import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../network/api_client.dart';
import '../utils/image_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable profile image picker with upload support.
/// Shows current avatar (from URL or local file) with an edit overlay.
/// Handles gallery pick + camera capture + upload to `/users/me/avatar`.
///
/// Properly handles:
/// - Camera & photo library permissions (iOS + Android)
/// - Permission denied with recovery path (open settings)
/// - User cancel without crash
/// - Cache invalidation after upload
/// - Immediate local preview before upload completes
class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String? name;
  final double size;
  final ValueChanged<String>? onUploaded;
  /// When false, only shows the camera icon button (no image preview).
  /// Useful when the image is already displayed as a background elsewhere.
  final bool showImagePreview;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.name,
    this.size = 100,
    this.onUploaded,
    this.showImagePreview = true,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _localFile;
  bool _isUploading = false;
  String? _lastUploadedUrl;

  /// The effective image URL — use the last uploaded URL if available,
  /// otherwise fall back to the prop. This ensures we always show the
  /// latest image even if the parent hasn't rebuilt yet.
  String? get _effectiveImageUrl => _lastUploadedUrl ?? widget.currentImageUrl;

  Future<void> _pickAndUpload() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    // ── Check permissions ──
    final hasPermission = await _checkPermission(source);
    if (!hasPermission) return;

    // ── Pick image ──
    try {
      final picker = ImagePicker();
      final XFile? picked;
      try {
        picked = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
      } catch (e) {
        if (mounted) {
          _showError('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please check app permissions in Settings.');
        }
        return;
      }

      // User cancelled — do nothing (no crash)
      if (picked == null) return;

      final file = File(picked.path);
      if (!file.existsSync()) return;

      // ── Show local preview immediately ──
      final oldUrl = _effectiveImageUrl;
      setState(() {
        _localFile = file;
        _isUploading = true;
      });

      // ── Upload ──
      try {
        final formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(
            file.path,
            filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });

        final resp = await apiClient.dio.post('/users/me/avatar', data: formData);
        final rawAvatarUrl = resp.data['data']?['avatarUrl'] as String?;

        if (rawAvatarUrl != null) {
          // Resolve relative URL to full URL
          final resolvedUrl = ImageUtils.resolveAvatarUrl(rawAvatarUrl);

          // Evict OLD image from cache so it's not shown anywhere
          await ImageUtils.evictAvatarFromCache(oldUrl);

          // Also evict the new URL in case there's stale cache from a previous upload
          await ImageUtils.evictAvatarFromCache(resolvedUrl);

          setState(() => _lastUploadedUrl = resolvedUrl);

          // Notify parent — this triggers refreshMe() + triggerDataRefresh()
          widget.onUploaded?.call(resolvedUrl ?? rawAvatarUrl);
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
        // Upload failed — revert local preview
        setState(() => _localFile = null);
        if (mounted) {
          _showError('Upload failed. Please try again.');
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } catch (e) {
      // Catch-all for any unexpected errors
      if (mounted) {
        setState(() {
          _localFile = null;
          _isUploading = false;
        });
      }
    }
  }

  /// Check and request permission for camera or photo library.
  /// Returns true if granted, false if denied.
  Future<bool> _checkPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }
      if (status.isPermanentlyDenied) {
        if (mounted) _showPermissionDeniedDialog('camera');
        return false;
      }
      return status.isGranted;
    } else {
      // Gallery — on iOS 14+ uses PHPicker which doesn't need explicit permission
      // On Android 13+, uses READ_MEDIA_IMAGES
      // The image_picker plugin handles this internally on most platforms,
      // but we add explicit handling for edge cases
      if (Platform.isAndroid) {
        var status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
          // On Android < 13, photos permission doesn't exist — fall through
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
        if (status.isPermanentlyDenied) {
          if (mounted) _showPermissionDeniedDialog('photo library');
          return false;
        }
      }
      return true;
    }
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCardLg),
        title: Text('$feature Access Required', style: AppTextStyles.heading3),
        content: Text(
          'Please enable $feature access in your device Settings to use this feature.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Open Settings', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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

    // Camera-only mode: just a circular icon button, no image preview
    if (!widget.showImagePreview) {
      return GestureDetector(
        onTap: _isUploading ? null : _pickAndUpload,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          child: _isUploading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.25),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Icon(Icons.camera_alt_rounded, size: size * 0.45, color: AppColors.white),
        ),
      );
    }

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
    // Show local file if picked (immediate preview)
    if (_localFile != null) {
      return Image.file(
        _localFile!,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
      );
    }

    // Show network image if available
    final url = _effectiveImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
        // Add cache key with timestamp to bust cache after upload
        cacheKey: _lastUploadedUrl != null ? '${url}_${DateTime.now().millisecondsSinceEpoch}' : url,
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

/// Board/card-style profile image with upload support.
/// Shows a rectangular image area (like the nanny card top image) with a
/// camera edit button overlay. Used on the Profile screen for a premium look.
class ProfileImageBoard extends StatefulWidget {
  final String? currentImageUrl;
  final String? name;
  final double height;
  final ValueChanged<String>? onUploaded;

  const ProfileImageBoard({
    super.key,
    this.currentImageUrl,
    this.name,
    this.height = 200,
    this.onUploaded,
  });

  @override
  State<ProfileImageBoard> createState() => _ProfileImageBoardState();
}

class _ProfileImageBoardState extends State<ProfileImageBoard> {
  File? _localFile;
  bool _isUploading = false;
  String? _lastUploadedUrl;

  String? get _effectiveImageUrl => _lastUploadedUrl ?? widget.currentImageUrl;

  Future<void> _pickAndUpload() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final hasPermission = await _checkPermission(source);
    if (!hasPermission) return;

    try {
      final picker = ImagePicker();
      final XFile? picked;
      try {
        picked = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please check app permissions.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (picked == null) return;

      final file = File(picked.path);
      if (!file.existsSync()) return;

      final oldUrl = _effectiveImageUrl;
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
        final rawAvatarUrl = resp.data['data']?['avatarUrl'] as String?;

        if (rawAvatarUrl != null) {
          final resolvedUrl = ImageUtils.resolveAvatarUrl(rawAvatarUrl);
          await ImageUtils.evictAvatarFromCache(oldUrl);
          await ImageUtils.evictAvatarFromCache(resolvedUrl);
          setState(() => _lastUploadedUrl = resolvedUrl);
          widget.onUploaded?.call(resolvedUrl ?? rawAvatarUrl);
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
        setState(() => _localFile = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localFile = null;
          _isUploading = false;
        });
      }
    }
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (status.isDenied) status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) _showPermissionDeniedDialog('camera');
        return false;
      }
      return status.isGranted;
    } else {
      if (Platform.isAndroid) {
        var status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
          if (status.isDenied) status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          if (mounted) _showPermissionDeniedDialog('photo library');
          return false;
        }
      }
      return true;
    }
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCardLg),
        title: Text('$feature Access Required', style: AppTextStyles.heading3),
        content: Text(
          'Please enable $feature access in your device Settings to use this feature.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Open Settings', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: AppRadius.borderXl),
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
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: AppRadius.borderXl),
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
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            _buildImage(),
            // Gradient overlay at bottom for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
            // Camera edit button
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: AppShadows.sm,
                ),
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_localFile != null) {
      return Image.file(_localFile!, fit: BoxFit.cover);
    }

    final url = _effectiveImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        cacheKey: _lastUploadedUrl != null ? '${url}_${DateTime.now().millisecondsSinceEpoch}' : url,
        placeholder: (_, __) => _boardPlaceholder(),
        errorWidget: (_, __, ___) => _boardPlaceholder(),
      );
    }

    return _boardPlaceholder();
  }

  Widget _boardPlaceholder() {
    final initial = (widget.name?.isNotEmpty == true) ? widget.name![0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              initial,
              style: AppTextStyles.heading1.copyWith(color: AppColors.white, fontSize: 48),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add photo',
              style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
