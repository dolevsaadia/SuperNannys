import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('About'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),

          // ── App Icon & Info ──────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradientPrimary, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.child_care_rounded, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('SuperNanny', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Version 1.3.0', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Find trusted babysitters near you', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Links ───────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                  ),
                  title: const Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                  onTap: () {
                    // TODO: open Terms of Service URL
                  },
                ),
                const Divider(indent: 64, height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.primary),
                  ),
                  title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                  onTap: () {
                    // TODO: open Privacy Policy URL
                  },
                ),
                const Divider(indent: 64, height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.source_outlined, size: 18, color: AppColors.primary),
                  ),
                  title: const Text('Open Source Licenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'SuperNanny',
                    applicationVersion: '1.3.0',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.child_care_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Copyright ───────────────────────
          const Center(
            child: Text('\u00A9 2026 SuperNanny', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
