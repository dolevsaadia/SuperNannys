import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';

final _verificationStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final resp = await apiClient.dio.get('/verification-requests/me');
    return resp.data['data'] as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});

class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  ConsumerState<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends ConsumerState<VerificationRequestScreen> {
  File? _idCard;
  File? _idAppendix;
  File? _policeClearance;
  bool _isSubmitting = false;

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
    if (result == null) return;
    setState(() {
      switch (type) {
        case 'id': _idCard = File(result.path);
        case 'appendix': _idAppendix = File(result.path);
        case 'police': _policeClearance = File(result.path);
      }
    });
  }

  Future<String?> _uploadFile(File file, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path, filename: '${fieldName}_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    });
    final resp = await apiClient.dio.post('/nannies/me/documents', data: formData);
    return resp.data['data']?['url'] as String?;
  }

  Future<void> _submit() async {
    if (_idCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your ID card'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Upload files and get URLs
      String? idCardUrl;
      String? idAppendixUrl;
      String? policeClearanceUrl;

      if (_idCard != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_idCard!.path, filename: 'id_card.jpg'),
          'type': 'ID_CARD',
        });
        final resp = await apiClient.dio.post('/nannies/me/documents', data: formData);
        idCardUrl = resp.data['data']?['url'] as String?;
      }
      if (_idAppendix != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_idAppendix!.path, filename: 'id_appendix.jpg'),
          'type': 'ID_APPENDIX',
        });
        final resp = await apiClient.dio.post('/nannies/me/documents', data: formData);
        idAppendixUrl = resp.data['data']?['url'] as String?;
      }
      if (_policeClearance != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_policeClearance!.path, filename: 'police_clearance.jpg'),
          'type': 'POLICE_CLEARANCE',
        });
        final resp = await apiClient.dio.post('/nannies/me/documents', data: formData);
        policeClearanceUrl = resp.data['data']?['url'] as String?;
      }

      await apiClient.dio.post('/verification-requests', data: {
        if (idCardUrl != null) 'idCardUrl': idCardUrl,
        if (idAppendixUrl != null) 'idAppendixUrl': idAppendixUrl,
        if (policeClearanceUrl != null) 'policeClearanceUrl': policeClearanceUrl,
      });

      ref.invalidate(_verificationStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request submitted!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(_verificationStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Verification'),
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, __) => const Center(child: Text('Error loading status')),
        data: (existing) {
          if (existing != null) {
            return _StatusView(request: existing);
          }
          return _SubmitForm(
            idCard: _idCard,
            idAppendix: _idAppendix,
            policeClearance: _policeClearance,
            isSubmitting: _isSubmitting,
            onPickImage: _pickImage,
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final Map<String, dynamic> request;
  const _StatusView({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final adminNotes = request['adminNotes'] as String?;

    final statusConfig = switch (status) {
      'pending' => (AppColors.warning, Icons.hourglass_top_rounded, 'Under Review', 'Your verification is being reviewed by our team.'),
      'approved' => (AppColors.success, Icons.verified_rounded, 'Verified!', 'Your identity has been verified. You now have a verified badge.'),
      'rejected' => (AppColors.error, Icons.cancel_rounded, 'Rejected', 'Your verification was not approved. Please resubmit.'),
      _ => (AppColors.textHint, Icons.info_outline_rounded, status, ''),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: statusConfig.$1.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusConfig.$2, color: statusConfig.$1, size: 40),
          ),
          const SizedBox(height: 16),
          Text(statusConfig.$3, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: statusConfig.$1)),
          const SizedBox(height: 8),
          Text(statusConfig.$4, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          if (adminNotes != null && adminNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info)),
                  const SizedBox(height: 4),
                  Text(adminNotes, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmitForm extends StatelessWidget {
  final File? idCard;
  final File? idAppendix;
  final File? policeClearance;
  final bool isSubmitting;
  final ValueChanged<String> onPickImage;
  final VoidCallback onSubmit;

  const _SubmitForm({
    required this.idCard,
    required this.idAppendix,
    required this.policeClearance,
    required this.isSubmitting,
    required this.onPickImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Get Verified', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Upload your documents to get a verified badge on your profile. This helps parents trust you.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          _DocumentUploadCard(
            title: 'ID Card (Teudat Zehut)',
            subtitle: 'Front side of your ID',
            icon: Icons.badge_rounded,
            file: idCard,
            isRequired: true,
            onTap: () => onPickImage('id'),
          ),
          const SizedBox(height: 12),
          _DocumentUploadCard(
            title: 'ID Appendix (Sefach)',
            subtitle: 'Back side / appendix',
            icon: Icons.description_rounded,
            file: idAppendix,
            isRequired: false,
            onTap: () => onPickImage('appendix'),
          ),
          const SizedBox(height: 12),
          _DocumentUploadCard(
            title: 'Police Clearance',
            subtitle: 'Ethics / background check certificate',
            icon: Icons.security_rounded,
            file: policeClearance,
            isRequired: false,
            onTap: () => onPickImage('police'),
          ),

          const SizedBox(height: 32),

          AppButton(
            label: isSubmitting ? 'Submitting...' : 'Submit for Verification',
            variant: AppButtonVariant.gradient,
            isLoading: isSubmitting,
            onTap: isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final bool isRequired;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border.all(
            color: hasFile ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: hasFile ? AppColors.success.withValues(alpha: 0.1) : AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasFile ? Icons.check_circle_rounded : icon,
                color: hasFile ? AppColors.success : AppColors.textHint,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? 'File selected' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.edit_rounded : Icons.upload_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
