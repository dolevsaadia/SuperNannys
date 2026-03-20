import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class NannyOnboardingScreen extends ConsumerStatefulWidget {
  const NannyOnboardingScreen({super.key});

  @override
  ConsumerState<NannyOnboardingScreen> createState() => _NannyOnboardingScreenState();
}

class _NannyOnboardingScreenState extends ConsumerState<NannyOnboardingScreen> {
  static const _totalSteps = 4;
  int _step = 0;
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _rate = 55;
  bool _enableRecurring = false;
  int _recurringRate = 45;
  int _years = 1;
  double _minimumHours = 0;
  bool _allowsBabysittingAtHome = false;
  final List<String> _languages = ['Hebrew'];
  final List<String> _skills = [];
  bool _isLoading = false;

  // Document uploads
  File? _idDocument;
  File? _policeCheck;

  @override
  void initState() {
    super.initState();
    // Pre-fill phone if already on the user profile (e.g. from email registration)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        _phoneCtrl.text = user.phone!;
      }
    });
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _idNumberCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
    if (result == null) return;
    setState(() {
      if (type == 'id') _idDocument = File(result.path);
      if (type == 'police') _policeCheck = File(result.path);
    });
  }

  Future<void> _takePhoto(String type) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
    if (result == null) return;
    setState(() {
      if (type == 'id') _idDocument = File(result.path);
      if (type == 'police') _policeCheck = File(result.path);
    });
  }

  void _showPickerOptions(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickFile(type); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _takePhoto(type); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(File file, String docType) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      'type': docType,
    });
    await apiClient.dio.post('/nannies/me/documents', data: formData);
  }

  /// Validate Israeli ID number (Luhn mod-10 check)
  bool _isValidIsraeliId(String id) {
    if (id.length < 5 || id.length > 9) return false;
    final padded = id.padLeft(9, '0');
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int digit = int.parse(padded[i]);
      int val = digit * ((i % 2 == 0) ? 1 : 2);
      if (val > 9) val -= 9;
      sum += val;
    }
    return sum % 10 == 0;
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      if (_idNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID number is required'), backgroundColor: Colors.orange),
        );
        return false;
      }
      if (!_isValidIsraeliId(_idNumberCtrl.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid Israeli ID number'), backgroundColor: Colors.orange),
        );
        return false;
      }
      if (_phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is required'), backgroundColor: Colors.orange),
        );
        return false;
      }
      final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'[\s\-]'), '');
      if (cleaned.length < 9 || cleaned.length > 13) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid phone number'), backgroundColor: Colors.orange),
        );
        return false;
      }
      if (_cityCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('City is required'), backgroundColor: Colors.orange),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      // 1. Update user profile fields (idNumber, phone)
      await apiClient.dio.put('/users/me', data: {
        if (_idNumberCtrl.text.trim().isNotEmpty) 'idNumber': _idNumberCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });

      // 2. Update nanny profile
      await apiClient.dio.put('/nannies/me', data: {
        'headline': _headlineCtrl.text,
        'bio': _bioCtrl.text,
        'city': _cityCtrl.text,
        'hourlyRateNis': _rate,
        if (_enableRecurring) 'recurringHourlyRateNis': _recurringRate,
        'yearsExperience': _years,
        'languages': _languages,
        'skills': _skills,
        'isAvailable': true,
        'minimumHoursPerBooking': _minimumHours,
        'allowsBabysittingAtHome': _allowsBabysittingAtHome,
      });

      // 2. Upload documents (if selected)
      if (_idDocument != null) {
        await _uploadDocument(_idDocument!, 'ID_CARD');
      }
      if (_policeCheck != null) {
        await _uploadDocument(_policeCheck!, 'POLICE_CHECK');
      }

      await ref.read(authProvider.notifier).refreshMe();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Step ${_step + 1} of $_totalSteps', style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                      if (_step > 0)
                        TextButton(onPressed: () => setState(() => _step--), child: const Text('Back')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStep(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                label: _step < _totalSteps - 1 ? 'Next' : 'Complete Setup',
                isLoading: _isLoading,
                onTap: () {
                  if (_step < _totalSteps - 1) {
                    if (_validateCurrentStep()) setState(() => _step++);
                  } else {
                    _submit();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _BasicInfoStep(
          headlineCtrl: _headlineCtrl,
          bioCtrl: _bioCtrl,
          cityCtrl: _cityCtrl,
          idNumberCtrl: _idNumberCtrl,
          phoneCtrl: _phoneCtrl,
        );
      case 1:
        return _RateStep(
          rate: _rate,
          enableRecurring: _enableRecurring,
          recurringRate: _recurringRate,
          years: _years,
          minimumHours: _minimumHours,
          allowsBabysittingAtHome: _allowsBabysittingAtHome,
          onRateChanged: (r) => setState(() => _rate = r),
          onEnableRecurringChanged: (v) => setState(() => _enableRecurring = v),
          onRecurringRateChanged: (r) => setState(() => _recurringRate = r),
          onYearsChanged: (y) => setState(() => _years = y),
          onMinimumHoursChanged: (h) => setState(() => _minimumHours = h),
          onAllowsBabysittingChanged: (v) => setState(() => _allowsBabysittingAtHome = v),
        );
      case 2:
        return _SkillsStep(
          languages: _languages, skills: _skills,
          onLanguageToggle: (l) => setState(() => _languages.contains(l) ? _languages.remove(l) : _languages.add(l)),
          onSkillToggle: (s) => setState(() => _skills.contains(s) ? _skills.remove(s) : _skills.add(s)),
        );
      case 3:
        return _DocumentsStep(
          idDocument: _idDocument,
          policeCheck: _policeCheck,
          onPickId: () => _showPickerOptions('id'),
          onPickPolice: () => _showPickerOptions('police'),
          onRemoveId: () => setState(() => _idDocument = null),
          onRemovePolice: () => setState(() => _policeCheck = null),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BasicInfoStep extends StatelessWidget {
  final TextEditingController headlineCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController idNumberCtrl;
  final TextEditingController phoneCtrl;

  const _BasicInfoStep({
    required this.headlineCtrl,
    required this.bioCtrl,
    required this.cityCtrl,
    required this.idNumberCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Parents will see this on your profile', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'ID Number *',
            hint: 'Israeli ID number',
            controller: idNumberCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.textHint),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone Number *',
            hint: '050-1234567',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Headline', hint: 'e.g. Experienced nanny with infant care expertise', controller: headlineCtrl),
          const SizedBox(height: 16),
          AppTextField(label: 'Bio', hint: 'Describe your experience, approach, and personality...', controller: bioCtrl, maxLines: 4),
          const SizedBox(height: 16),
          AppTextField(
            label: 'City *',
            hint: 'e.g. Tel Aviv',
            controller: cityCtrl,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textHint),
          ),
        ],
      );
}

class _RateStep extends StatelessWidget {
  final int rate;
  final bool enableRecurring;
  final int recurringRate;
  final int years;
  final double minimumHours;
  final bool allowsBabysittingAtHome;
  final ValueChanged<int> onRateChanged;
  final ValueChanged<bool> onEnableRecurringChanged;
  final ValueChanged<int> onRecurringRateChanged;
  final ValueChanged<int> onYearsChanged;
  final ValueChanged<double> onMinimumHoursChanged;
  final ValueChanged<bool> onAllowsBabysittingChanged;

  const _RateStep({
    required this.rate,
    required this.enableRecurring,
    required this.recurringRate,
    required this.years,
    required this.minimumHours,
    required this.allowsBabysittingAtHome,
    required this.onRateChanged,
    required this.onEnableRecurringChanged,
    required this.onRecurringRateChanged,
    required this.onYearsChanged,
    required this.onMinimumHoursChanged,
    required this.onAllowsBabysittingChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your rates & experience', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Set your hourly rate for bookings',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          // Casual rate
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Standard', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Hourly Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('\u20AA$rate/hr', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                Slider(
                  value: rate.toDouble(), min: 30, max: 150, divisions: 24,
                  activeColor: AppColors.primary,
                  onChanged: (v) => onRateChanged(v.toInt()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Enable recurring toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enableRecurring ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 22,
                  color: enableRecurring ? AppColors.accent : AppColors.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Allow Recurring Bookings',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Let parents book you on a fixed weekly schedule',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enableRecurring,
                  activeTrackColor: AppColors.accent,
                  onChanged: onEnableRecurringChanged,
                ),
              ],
            ),
          ),

          // Recurring rate (only shown when enabled)
          if (enableRecurring) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Recurring', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Fixed Schedule Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Discounted rate attracts regular clients',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('\u20AA$recurringRate/hr', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ),
                  Slider(
                    value: recurringRate.toDouble(), min: 20, max: 130, divisions: 22,
                    activeColor: AppColors.accent,
                    onChanged: (v) => onRecurringRateChanged(v.toInt()),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Years experience
          const Text('Years of Experience', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$years years', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          Slider(
            value: years.toDouble(), min: 0, max: 20, divisions: 20,
            activeColor: AppColors.primary,
            onChanged: (v) => onYearsChanged(v.toInt()),
          ),

          const SizedBox(height: 20),

          // Minimum hours per booking
          const Text('Minimum Hours Per Session', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Set 0 for no minimum', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                minimumHours == 0 ? 'No minimum' : '${minimumHours.toStringAsFixed(minimumHours == minimumHours.roundToDouble() ? 0 : 1)} hours',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: minimumHours, min: 0, max: 8, divisions: 16,
            activeColor: AppColors.primary,
            onChanged: (v) => onMinimumHoursChanged(v),
          ),

          const SizedBox(height: 14),

          // Allow babysitting at home toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: allowsBabysittingAtHome ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_rounded,
                  size: 22,
                  color: allowsBabysittingAtHome ? AppColors.success : AppColors.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Babysitting at My Home',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Allow parents to bring kids to your place',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: allowsBabysittingAtHome,
                  activeTrackColor: AppColors.success,
                  onChanged: onAllowsBabysittingChanged,
                ),
              ],
            ),
          ),
        ],
      );
}

class _SkillsStep extends StatelessWidget {
  final List<String> languages;
  final List<String> skills;
  final ValueChanged<String> onLanguageToggle;
  final ValueChanged<String> onSkillToggle;

  const _SkillsStep({required this.languages, required this.skills, required this.onLanguageToggle, required this.onSkillToggle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Languages & Skills', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const Text('Languages', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.languages.map((l) {
              final selected = languages.contains(l);
              return GestureDetector(
                onTap: () => onLanguageToggle(l),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(l, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.skills.map((s) {
              final selected = skills.contains(s);
              return GestureDetector(
                onTap: () => onSkillToggle(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(s, style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      );
}

class _DocumentsStep extends StatelessWidget {
  final File? idDocument;
  final File? policeCheck;
  final VoidCallback onPickId;
  final VoidCallback onPickPolice;
  final VoidCallback onRemoveId;
  final VoidCallback onRemovePolice;

  const _DocumentsStep({
    required this.idDocument,
    required this.policeCheck,
    required this.onPickId,
    required this.onPickPolice,
    required this.onRemoveId,
    required this.onRemovePolice,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Documents', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Upload your ID and certificate of good conduct for verification',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ID Document + Appendix
          _DocumentUploadCard(
            title: 'ID Card + Appendix',
            subtitle: 'Photo of your Israeli ID card (front & appendix)',
            icon: Icons.badge_outlined,
            file: idDocument,
            onPick: onPickId,
            onRemove: onRemoveId,
            color: AppColors.primary,
          ),

          const SizedBox(height: 16),

          // Certificate of Good Conduct (Police Check)
          _DocumentUploadCard(
            title: 'Certificate of Good Conduct',
            subtitle: 'Police background check certificate',
            icon: Icons.verified_user_outlined,
            file: policeCheck,
            onPick: onPickPolice,
            onRemove: onRemovePolice,
            color: AppColors.accent,
          ),

          const SizedBox(height: 16),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Documents will be reviewed by our team. You can also upload them later from your profile.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
}

class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final Color color;

  const _DocumentUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.onPick,
    required this.onRemove,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasFile ? color.withValues(alpha: 0.4) : AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (hasFile)
            // Show thumbnail of uploaded file
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.file(file!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(hasFile ? Icons.check_circle_rounded : icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        hasFile ? 'Document uploaded' : subtitle,
                        style: TextStyle(
                          color: hasFile ? color : AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasFile)
                  GestureDetector(
                    onTap: onPick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Upload', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onPick,
                    child: Text('Replace', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
