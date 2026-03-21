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
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/utils/async_value_ui.dart';

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

  Future<String?> _uploadFile(File file, String filename, String docType) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: filename),
      'type': docType,
    });
    final resp = await apiClient.dio.post('/nannies/me/documents', data: formData);
    return resp.data['data']?['url'] as String?;
  }

  Future<void> _submitOrUpdate(Map<String, dynamic>? existing) async {
    final isUpdate = existing != null;
    final existingIdCard = existing?['idCardUrl'] as String?;

    // For new submissions, ID card is required
    if (!isUpdate && _idCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your ID card'), backgroundColor: AppColors.error),
      );
      return;
    }

    // For updates, must have at least one new file OR existing files cover it
    if (isUpdate && _idCard == null && _idAppendix == null && _policeClearance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one new document'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Upload only NEW files (locally picked)
      String? idCardUrl;
      String? idAppendixUrl;
      String? policeClearanceUrl;

      if (_idCard != null) {
        idCardUrl = await _uploadFile(_idCard!, 'id_card.jpg', 'ID_CARD');
      }
      if (_idAppendix != null) {
        idAppendixUrl = await _uploadFile(_idAppendix!, 'id_appendix.jpg', 'ID_APPENDIX');
      }
      if (_policeClearance != null) {
        policeClearanceUrl = await _uploadFile(_policeClearance!, 'police_clearance.jpg', 'POLICE_CLEARANCE');
      }

      final body = <String, dynamic>{
        if (idCardUrl != null) 'idCardUrl': idCardUrl,
        if (idAppendixUrl != null) 'idAppendixUrl': idAppendixUrl,
        if (policeClearanceUrl != null) 'policeClearanceUrl': policeClearanceUrl,
      };

      if (isUpdate) {
        await apiClient.dio.put('/verification-requests/me', data: body);
      } else {
        await apiClient.dio.post('/verification-requests', data: body);
      }

      ref.invalidate(_verificationStatusProvider);
      triggerDataRefresh(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdate ? 'Verification request updated!' : 'Verification request submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please try again.'), backgroundColor: AppColors.error),
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
      body: statusAsync.authAwareWhen(
        ref,
        errorTitle: 'Could not load verification status',
        onRetry: () => ref.invalidate(_verificationStatusProvider),
        data: (existing) {
          // Approved → read-only status view
          if (existing != null && existing['status'] == 'approved') {
            return _ApprovedView(request: existing);
          }

          // Pending or rejected → editable form with existing docs pre-loaded
          // No request → fresh submit form
          return _EditableForm(
            existing: existing,
            idCard: _idCard,
            idAppendix: _idAppendix,
            policeClearance: _policeClearance,
            isSubmitting: _isSubmitting,
            onPickImage: _pickImage,
            onSubmit: () => _submitOrUpdate(existing),
          );
        },
      ),
    );
  }
}

/// Read-only view for approved verification requests.
class _ApprovedView extends StatelessWidget {
  final Map<String, dynamic> request;
  const _ApprovedView({required this.request});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Verified!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 8),
          const Text(
            'Your identity has been verified. You now have a verified badge on your profile.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Editable form for new submission, pending update, or rejected resubmission.
class _EditableForm extends StatelessWidget {
  final Map<String, dynamic>? existing;
  final File? idCard;
  final File? idAppendix;
  final File? policeClearance;
  final bool isSubmitting;
  final ValueChanged<String> onPickImage;
  final VoidCallback onSubmit;

  const _EditableForm({
    required this.existing,
    required this.idCard,
    required this.idAppendix,
    required this.policeClearance,
    required this.isSubmitting,
    required this.onPickImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUpdate = existing != null;
    final status = existing?['status'] as String?;
    final adminNotes = existing?['adminNotes'] as String?;
    final existingIdCard = existing?['idCardUrl'] as String?;
    final existingAppendix = existing?['idAppendixUrl'] as String?;
    final existingPolice = existing?['policeClearanceUrl'] as String?;

    final String title;
    final String subtitle;
    final String buttonLabel;
    if (status == 'rejected') {
      title = 'Resubmit Verification';
      subtitle = 'Your previous request was rejected. Update your documents and resubmit.';
      buttonLabel = 'Resubmit for Verification';
    } else if (isUpdate) {
      title = 'Update Verification';
      subtitle = 'Upload any missing documents to complete your verification request.';
      buttonLabel = 'Update Request';
    } else {
      title = 'Get Verified';
      subtitle = 'Upload your documents to get a verified badge on your profile. This helps parents trust you.';
      buttonLabel = 'Submit for Verification';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner for rejected requests
          if (status == 'rejected') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Previous request was rejected',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Status banner for pending requests
          if (status == 'pending') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Under review \u2014 you can still add missing documents',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Admin notes
          if (adminNotes != null && adminNotes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
                  const SizedBox(height: 4),
                  Text(adminNotes, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),

          _DocumentUploadCard(
            title: 'ID Card (Teudat Zehut)',
            subtitle: 'Front side of your ID',
            icon: Icons.badge_rounded,
            file: idCard,
            existingUrl: existingIdCard,
            isRequired: !isUpdate,
            onTap: () => onPickImage('id'),
          ),
          const SizedBox(height: 12),
          _DocumentUploadCard(
            title: 'ID Appendix (Sefach)',
            subtitle: 'Back side / appendix',
            icon: Icons.description_rounded,
            file: idAppendix,
            existingUrl: existingAppendix,
            isRequired: false,
            onTap: () => onPickImage('appendix'),
          ),
          const SizedBox(height: 12),
          _DocumentUploadCard(
            title: 'Police Clearance',
            subtitle: 'Ethics / background check certificate',
            icon: Icons.security_rounded,
            file: policeClearance,
            existingUrl: existingPolice,
            isRequired: false,
            onTap: () => onPickImage('police'),
          ),

          const SizedBox(height: 32),

          AppButton(
            label: isSubmitting ? 'Submitting...' : buttonLabel,
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
  final String? existingUrl;
  final bool isRequired;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.isRequired,
    required this.onTap,
    this.existingUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasNewFile = file != null;
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;
    final hasAny = hasNewFile || hasExisting;

    final String statusText;
    final Color statusColor;
    if (hasNewFile) {
      statusText = 'New file selected';
      statusColor = AppColors.primary;
    } else if (hasExisting) {
      statusText = 'Already uploaded';
      statusColor = AppColors.success;
    } else {
      statusText = subtitle;
      statusColor = AppColors.textHint;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border.all(
            color: hasNewFile
                ? AppColors.primary.withValues(alpha: 0.4)
                : hasExisting
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: hasAny
                    ? (hasNewFile ? AppColors.primary : AppColors.success).withValues(alpha: 0.1)
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasAny ? Icons.check_circle_rounded : icon,
                color: hasNewFile ? AppColors.primary : (hasExisting ? AppColors.success : AppColors.textHint),
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
                      Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(statusText, style: TextStyle(fontSize: 12, color: statusColor)),
                ],
              ),
            ),
            Icon(
              hasAny ? Icons.edit_rounded : Icons.upload_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
