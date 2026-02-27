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
          rate: _rate, years: _years,
          onRateChanged: (r) => setState(() => _rate = r),
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
  final int years;
  final ValueChanged<int> onRateChanged;
  final ValueChanged<int> onYearsChanged;

  const _RateStep({required this.rate, required this.years, required this.onRateChanged, required this.onYearsChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your rate & experience', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const Text('Hourly Rate (₪)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('₪$rate/hr', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          Slider(
            value: rate.toDouble(), min: 30, max: 150, divisions: 24,
            activeColor: AppColors.primary,
            onChanged: (v) => onRateChanged(v.toInt()),
          ),
          const SizedBox(height: 24),
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
