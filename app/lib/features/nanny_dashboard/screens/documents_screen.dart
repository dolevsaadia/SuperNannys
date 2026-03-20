import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  static const _docTypes = {
    'ID_CARD': {'label': 'ID Card (Teudat Zehut)', 'icon': Icons.badge_rounded, 'color': AppColors.primary},
    'CHILDCARE_CERT': {'label': 'Ethics Certificate', 'icon': Icons.school_rounded, 'color': AppColors.accent},
    'FIRST_AID_CERT': {'label': 'First Aid Certificate', 'icon': Icons.medical_services_rounded, 'color': AppColors.success},
    'POLICE_CHECK': {'label': 'Police Background Check', 'icon': Icons.security_rounded, 'color': AppColors.warning},
    'OTHER': {'label': 'Other Document', 'icon': Icons.description_rounded, 'color': AppColors.info},
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final resp = await apiClient.dio.get('/nannies/me/documents');
      final docs = (resp.data['data'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) setState(() { _documents = docs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(String type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      await apiClient.dio.post('/nannies/me/documents', data: formData);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String docId) async {
    try {
      await apiClient.dio.delete('/nannies/me/documents/$docId');
      await _loadDocuments();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: LoadingIndicator()));

    final uploadedTypes = _documents.map((d) => d['type'] as String).toSet();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Documents'),
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload your ID and ethics certificate to get verified. Verified nannies get more bookings!',
                    style: TextStyle(color: AppColors.info.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          if (_isUploading)
            const LinearProgressIndicator(color: AppColors.primary),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: _docTypes.entries.map((entry) {
                final type = entry.key;
                final meta = entry.value;
                final existing = _documents.where((d) => d['type'] == type).toList();
                final isUploaded = existing.isNotEmpty;
                final isVerified = isUploaded && existing.first['verifiedAt'] != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.sm,
                    border: isVerified
                        ? Border.all(color: AppColors.success.withValues(alpha: 0.3))
                        : isUploaded
                            ? Border.all(color: AppColors.warning.withValues(alpha: 0.3))
                            : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (meta['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(meta['icon'] as IconData, color: meta['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta['label'] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            if (isVerified)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                                        SizedBox(width: 4),
                                        Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else if (isUploaded)
                              const Text('Pending review', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500))
                            else
                              const Text('Not uploaded', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      if (isUploaded)
                        GestureDetector(
                          onTap: () => _deleteDocument(existing.first['id'] as String),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isUploading ? null : () => _uploadDocument(type),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? AppColors.textHint.withValues(alpha: 0.08)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isUploaded ? Icons.refresh_rounded : Icons.upload_rounded,
                            size: 18,
                            color: isUploaded ? AppColors.textHint : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
