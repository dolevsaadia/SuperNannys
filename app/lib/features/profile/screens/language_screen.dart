import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Language'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System default option
              _LanguageTile(
                title: 'System Default',
                subtitle: 'Follow device language',
                isSelected: currentCode == null,
                onTap: () {
                  ref.read(localeProvider.notifier).clearLocale();
                  context.pop();
                },
                isFirst: true,
              ),
              const Divider(indent: 56, height: 1),
              // All supported languages
              ...supportedLanguages.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final lang = entry.value;
                final isLast = idx == supportedLanguages.length - 1;
                return Column(
                  children: [
                    _LanguageTile(
                      title: lang.value,
                      subtitle: lang.key.toUpperCase(),
                      isSelected: currentCode == lang.key,
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(Locale(lang.key));
                        context.pop();
                      },
                      isLast: isLast,
                    ),
                    if (!isLast) const Divider(indent: 56, height: 1),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.language_rounded,
          size: 18,
          color: isSelected ? AppColors.primary : AppColors.textHint,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
          : const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
    );
  }
}
