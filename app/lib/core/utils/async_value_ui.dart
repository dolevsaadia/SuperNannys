import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_indicator.dart';

/// ──────────────────────────────────────────────────────────────
/// AUTH-AWARE ASYNC VALUE HELPERS
/// ──────────────────────────────────────────────────────────────
///
/// Solves the "Could not load" flash problem:
///
/// When a 401 triggers auto-logout, providers briefly enter error state
/// BEFORE GoRouter redirects to login. Without this helper, every screen
/// flashes "Could not load" for a split second.
///
/// [authAwareWhen] checks if the user is still authenticated before
/// showing an error. If not authenticated → show loading spinner
/// (the user is being redirected to login anyway).
/// ──────────────────────────────────────────────────────────────

extension AsyncValueUI<T> on AsyncValue<T> {
  /// Like [when], but suppresses errors when the user is logged out
  /// (during 401 → auto-logout transition). Shows a loading spinner
  /// instead of "Could not load" while redirecting to login.
  Widget authAwareWhen(
    WidgetRef ref, {
    required Widget Function(T data) data,
    Widget Function()? loading,
    Widget Function(Object error, StackTrace? stack)? error,
    String errorTitle = 'Could not load',
    String errorSubtitle = 'Check your connection and try again',
    IconData errorIcon = Icons.wifi_off_rounded,
    VoidCallback? onRetry,
  }) {
    return when(
      loading: loading ?? () => const Center(child: LoadingIndicator()),
      error: (e, st) {
        // ── KEY FIX: Don't show errors during auth transition ──
        // If user is not authenticated, they're being redirected to login.
        // Showing "Could not load" would just flash and confuse the user.
        final isAuth = ref.watch(authProvider).isAuthenticated;
        if (!isAuth) {
          return loading?.call() ?? const Center(child: LoadingIndicator());
        }

        // ── Custom error handler provided ──
        if (error != null) return error(e, st);

        // ── Default: styled error with retry button ──
        return _DefaultErrorWidget(
          title: errorTitle,
          subtitle: errorSubtitle,
          icon: errorIcon,
          onRetry: onRetry,
        );
      },
      data: data,
    );
  }
}

/// Compact inline error (for horizontal lists inside a bigger page)
class InlineAsyncError extends StatelessWidget {
  final double height;
  final VoidCallback? onRetry;

  const InlineAsyncError({super.key, this.height = 100, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: onRetry != null
            ? TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
              )
            : const Text('Failed to load',
                style: TextStyle(color: AppColors.textHint)),
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
