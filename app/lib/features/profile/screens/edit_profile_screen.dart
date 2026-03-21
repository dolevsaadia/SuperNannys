import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/profile_image_picker.dart';
import '../../../l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await apiClient.dio.put('/users/me', data: {
        'fullName': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      await ref.read(authProvider.notifier).refreshMe();
      triggerDataRefresh(ref);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile Image ──
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: [
                    ProfileImagePicker(
                      currentImageUrl: user?.avatarUrl,
                      name: user?.fullName,
                      size: 110,
                      onUploaded: (_) async {
                        await ref.read(authProvider.notifier).refreshMe();
                        triggerDataRefresh(ref);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.tapToChangePhoto,
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // ── Form Fields ──
              AppTextField(
                label: l10n.fullName,
                controller: _name,
                validator: (v) => (v?.trim().length ?? 0) < 2 ? l10n.required : null,
                prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: l10n.phoneNumber,
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textHint),
              ),
              const SizedBox(height: 24),
              AppButton(label: l10n.saveChanges, onTap: _save, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
