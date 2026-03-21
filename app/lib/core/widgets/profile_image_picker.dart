import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable profile image picker with upload support.
/// Shows current avatar (from URL or local file) with an edit overlay.
/// Handles gallery pick + upload to `/users/me/avatar`.
class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String? name;
  final double size;
  final ValueChanged<String>? onUploaded;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.name,
    this.size = 100,
    this.onUploaded,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _localFile;
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _localFile = file;
      _isUploading = true;
    });

    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final resp = await apiClient.dio.post('/users/me/avatar', data: formData);
      final avatarUrl = resp.data['data']?['avatarUrl'] as String?;
      if (avatarUrl != null) {
        widget.onUploaded?.call(avatarUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: AppSpacing.sheetPadding,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.sheetTop,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.borderXs),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text('Choose Photo', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.s20),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.borderXl,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: Text('Choose from Gallery', style: AppTextStyles.label),
              subtitle: Text('Select an existing photo', style: AppTextStyles.caption),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: AppRadius.borderXl,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
              ),
              title: Text('Take a Photo', style: AppTextStyles.label),
              subtitle: Text('Use your camera', style: AppTextStyles.caption),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.s20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          children: [
            // Avatar
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                boxShadow: AppShadows.sm,
              ),
              child: ClipOval(
                child: _buildImage(size),
              ),
            ),
            // Edit overlay button
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: AppShadows.sm,
                ),
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double size) {
    // Show local file if picked
    if (_localFile != null) {
      return Image.file(
        _localFile!,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
      );
    }

    // Show network image if available
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.currentImageUrl!,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
        placeholder: (_, __) => _initials(size - 4),
        errorWidget: (_, __, ___) => _initials(size - 4),
      );
    }

    // Fallback to initials
    return _initials(size - 4);
  }

  Widget _initials(double s) {
    final initial = (widget.name?.isNotEmpty == true) ? widget.name![0].toUpperCase() : '?';
    return Container(
      width: s,
      height: s,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.gradientPrimary),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: s * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
