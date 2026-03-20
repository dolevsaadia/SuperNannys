import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ──────────────────────────────────────────────────────────────
/// DATA REFRESH — lightweight event system for cross-screen invalidation
/// ──────────────────────────────────────────────────────────────
///
/// **Problem:** Non-autoDispose providers (nannies, home sections) cache
/// data forever. After mutations (booking created, favorite toggled, status
/// changed), other screens still show stale data.
///
/// **Solution:** A simple counter that increments on mutations. Providers
/// that `ref.watch(dataRefreshProvider)` will automatically re-fetch.
/// Screens that use autoDispose already re-fetch on remount — they don't
/// need this.
///
/// **Usage (mutation side):**
///   ref.read(dataRefreshProvider.notifier).state++;
///
/// **Usage (provider side):**
///   ref.watch(dataRefreshProvider); // triggers re-fetch on increment
/// ──────────────────────────────────────────────────────────────

/// Global data version — incrementing triggers re-fetch in watching providers.
final dataRefreshProvider = StateProvider<int>((ref) => 0);

/// Convenience: call from any ConsumerWidget or provider to trigger refresh.
void triggerDataRefresh(WidgetRef ref) {
  ref.read(dataRefreshProvider.notifier).state++;
}

/// Same but for use inside providers (Ref instead of WidgetRef).
void triggerDataRefreshFromRef(Ref ref) {
  ref.read(dataRefreshProvider.notifier).state++;
}
