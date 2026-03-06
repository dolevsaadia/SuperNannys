import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../theme/app_colors.dart';

/// Shows a one-time dialog asking user to enable biometric login.
/// Call this after successful login/register.
Future<void> showBiometricPrompt(BuildContext context, String token) async {
  final biometric = BiometricService();
  final isSupported = await biometric.isDeviceSupported;
  final alreadyEnabled = await biometric.isEnabled;

  if (!isSupported || alreadyEnabled) return;
  if (!context.mounted) return;

  final types = await biometric.getAvailableBiometrics();
  final hasFace = types.isNotEmpty
      ? types.any((t) => t.name == 'face')
      : Platform.isIOS; // Default to Face ID on iOS, Fingerprint on Android
  final label = hasFace ? 'Face ID' : 'Fingerprint';

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(
        hasFace ? Icons.face_rounded : Icons.fingerprint_rounded,
        size: 48,
        color: AppColors.primary,
      ),
      title: Text('Enable $label?'),
      content: Text(
        'Sign in faster next time using $label. You can change this in settings.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Enable $label'),
        ),
      ],
    ),
  );

  if (result == true) {
    await biometric.enable(token);
  }
}
