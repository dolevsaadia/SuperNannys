import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Shows a friendly "session expired" dialog that the user must acknowledge.
/// Returns a Future that completes when the user taps "Sign In".
Future<void> showSessionExpiredDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_clock_outlined, size: 32, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            l.sessionExpired,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l.sessionExpiredMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.signIn, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
