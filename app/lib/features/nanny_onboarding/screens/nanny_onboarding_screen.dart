import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  int _step = 0;
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  int _rate = 55;
  bool _enableRecurring = false;
  int _recurringRate = 45;
  int _years = 1;
  final List<String> _languages = ['Hebrew'];
  final List<String> _skills = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
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
      });
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
                      Text('Step ${_step + 1} of 3', style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                      if (_step > 0)
                        TextButton(onPressed: () => setState(() => _step--), child: const Text('Back')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / 3,
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
                label: _step < 2 ? 'Next' : 'Complete Setup',
                isLoading: _isLoading,
                onTap: () {
                  if (_step < 2) setState(() => _step++);
                  else _submit();
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
        return _BasicInfoStep(headlineCtrl: _headlineCtrl, bioCtrl: _bioCtrl, cityCtrl: _cityCtrl);
      case 1:
        return _RateStep(
          rate: _rate,
          enableRecurring: _enableRecurring,
          recurringRate: _recurringRate,
          years: _years,
          onRateChanged: (r) => setState(() => _rate = r),
          onEnableRecurringChanged: (v) => setState(() => _enableRecurring = v),
          onRecurringRateChanged: (r) => setState(() => _recurringRate = r),
          onYearsChanged: (y) => setState(() => _years = y),
        );
      case 2:
        return _SkillsStep(
          languages: _languages, skills: _skills,
          onLanguageToggle: (l) => setState(() => _languages.contains(l) ? _languages.remove(l) : _languages.add(l)),
          onSkillToggle: (s) => setState(() => _skills.contains(s) ? _skills.remove(s) : _skills.add(s)),
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

  const _BasicInfoStep({required this.headlineCtrl, required this.bioCtrl, required this.cityCtrl});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Parents will see this on your profile', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          AppTextField(label: 'Headline', hint: 'e.g. Experienced nanny with infant care expertise', controller: headlineCtrl),
          const SizedBox(height: 16),
          AppTextField(label: 'Bio', hint: 'Describe your experience, approach, and personality...', controller: bioCtrl, maxLines: 4),
          const SizedBox(height: 16),
          AppTextField(
            label: 'City',
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
  final ValueChanged<int> onRateChanged;
  final ValueChanged<bool> onEnableRecurringChanged;
  final ValueChanged<int> onRecurringRateChanged;
  final ValueChanged<int> onYearsChanged;

  const _RateStep({
    required this.rate,
    required this.enableRecurring,
    required this.recurringRate,
    required this.years,
    required this.onRateChanged,
    required this.onEnableRecurringChanged,
    required this.onRecurringRateChanged,
    required this.onYearsChanged,
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
                        color: AppColors.primary.withOpacity(0.1),
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
                color: enableRecurring ? AppColors.accent.withOpacity(0.4) : AppColors.border,
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
                  activeColor: AppColors.accent,
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
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
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
