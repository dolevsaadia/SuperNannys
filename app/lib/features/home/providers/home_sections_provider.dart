import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

/// Fetches nannies for a specific home section with custom params
Future<List<NannyModel>> _fetchSection(Map<String, dynamic> params) async {
  final resp = await apiClient.dio.get('/nannies', queryParameters: params);
  final data = resp.data['data'] as Map<String, dynamic>;
  return (data['nannies'] as List<dynamic>)
      .map((e) => NannyModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// ──────────────────────────────────────────────────────────────
/// HOME SECTION PROVIDERS — with auth-aware auto-refresh + stale-while-revalidate
/// ──────────────────────────────────────────────────────────────
///
/// **Problem solved:**
/// These providers are NOT autoDispose (cached while app is alive).
/// When a 401 triggered auto-logout, they cached the ERROR state forever.
/// After re-login, they still showed "Could not load" because nothing
/// told them to refetch.
///
/// **Fix (2 layers):**
///
/// 1. `ref.watch(authProvider)` — provider auto-refetches whenever auth
///    state changes (login, logout, token refresh). After re-login,
///    fresh data loads automatically.
///
/// 2. **Stale-while-revalidate** — on error, returns the last successful
///    data if available. Only shows error if there's truly no cached data.
///    This means transient network blips never show "Could not load".
/// ──────────────────────────────────────────────────────────────

/// Top Rated nannies (sorted by rating, limit 10)
final topRatedNanniesProvider = FutureProvider<List<NannyModel>>((ref) async {
  // ── Auto-refresh on auth change (login/logout/token refresh) ──
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return []; // Don't fetch when logged out

  try {
    return await _fetchSection({'sortBy': 'rating', 'page': '1', 'limit': '10'});
  } catch (e) {
    // ── Stale-while-revalidate: return cached data on error ──
    final cached = ref.state.valueOrNull;
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});

/// Available Now nannies (only available, limit 10)
final availableNowNanniesProvider = FutureProvider<List<NannyModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  try {
    return await _fetchSection({'sortBy': 'rating', 'available': 'true', 'page': '1', 'limit': '10'});
  } catch (e) {
    final cached = ref.state.valueOrNull;
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});

/// New nannies (sorted by newest, limit 10)
final newNanniesProvider = FutureProvider<List<NannyModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  try {
    return await _fetchSection({'sortBy': 'newest', 'page': '1', 'limit': '10'});
  } catch (e) {
    final cached = ref.state.valueOrNull;
    if (cached != null && cached.isNotEmpty) return cached;
    rethrow;
  }
});

/// Near You nannies (sorted by distance, limit 8)
final nearbyNanniesProvider = FutureProvider.family<List<NannyModel>, ({double lat, double lng})>(
  (ref, coords) async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];

    try {
      return await _fetchSection({
        'sortBy': 'distance',
        'lat': coords.lat.toString(),
        'lng': coords.lng.toString(),
        'page': '1',
        'limit': '8',
      });
    } catch (e) {
      final cached = ref.state.valueOrNull;
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  },
);
