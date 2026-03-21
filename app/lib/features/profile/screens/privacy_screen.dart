import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supported = await _biometricService.isDeviceSupported;
    final enrolled = await _biometricService.isBiometricEnrolled;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricAvailable = supported && enrolled;
      _biometricEnabled = prefs.getBool('pref_biometric_lock') ?? false;
      _loaded = true;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_biometric_lock', value);
    setState(() => _biometricEnabled = value);
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(l10n.deleteAccount),
          ],
        ),
        content: Text(
          l10n.deleteAccountWarning,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dc);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please contact support@supernanny.net to delete your account.'),
                ),
              );
            },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.privacySettings),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Security', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.sm,
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.primary),
                    ),
                    title: const Text('Biometric Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    subtitle: Text(
                      _biometricAvailable ? 'Require biometric authentication to open app' : 'Not available on this device',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: _biometricEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _biometricAvailable ? _toggleBiometric : null,
                  ),
                ),

                const SizedBox(height: 24),
                Text(l10n.account, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.sm,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    ),
                    title: Text(l10n.deleteAccount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                    onTap: _showDeleteAccountDialog,
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
