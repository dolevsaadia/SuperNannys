import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nanny_card.dart';
import '../../../core/utils/async_value_ui.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';

final _favoritesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider); // re-fetch when favorites toggled elsewhere
  final resp = await apiClient.dio.get('/favorites');
  final list = resp.data['data']['favorites'] as List<dynamic>? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_favoritesProvider);

    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.savedNannies,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.authAwareWhen(
        ref,
        loading: () => const FullScreenLoader(),
        errorTitle: l.couldNotLoadFavorites,
        onRetry: () => ref.invalidate(_favoritesProvider),
        data: (favorites) {
          if (favorites.isEmpty) {
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l.noSavedNanniesYet,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.savedNanniesEmptyDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(l.browseNannies),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_favoritesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final nannyUser = fav['nannyUser'] as Map<String, dynamic>? ?? {};
                final nannyProfile = nannyUser['nannyProfile'] as Map<String, dynamic>?;

                if (nannyProfile == null) return const SizedBox.shrink();

                final nannyProfileId = nannyProfile['id'] as String? ?? nannyUser['id'] as String? ?? '';
                final nannyModel = NannyModel(
                  id: nannyProfileId,
                  userId: nannyUser['id'] as String? ?? '',
                  headline: nannyProfile['headline'] as String? ?? '',
                  bio: '',
                  hourlyRateNis: nannyProfile['hourlyRateNis'] as int? ?? 0,
                  recurringHourlyRateNis: nannyProfile['recurringHourlyRateNis'] as int?,
                  yearsExperience: nannyProfile['yearsExperience'] as int? ?? 0,
                  languages: [],
                  skills: [],
                  badges: [],
                  isVerified: false,
                  isAvailable: true,
                  latitude: (nannyProfile['latitude'] as num?)?.toDouble(),
                  longitude: (nannyProfile['longitude'] as num?)?.toDouble(),
                  city: nannyProfile['city'] as String? ?? '',
                  address: '',
                  rating: (nannyProfile['rating'] as num?)?.toDouble() ?? 0.0,
                  reviewsCount: nannyProfile['reviewsCount'] as int? ?? 0,
                  completedJobs: 0,
                  user: NannyUser(
                    id: nannyUser['id'] as String? ?? '',
                    fullName: nannyUser['fullName'] as String? ?? '',
                    avatarUrl: nannyUser['avatarUrl'] as String?,
                  ),
                  availability: [],
                );

                return NannyCard(
                  nanny: nannyModel,
                  onTap: () => context.go('/home/nanny/$nannyProfileId'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
