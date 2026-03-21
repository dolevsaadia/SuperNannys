import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/mini_map_preview.dart';
import '../../../core/widgets/nanny_list_tile.dart';
import '../../home/providers/nannies_provider.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  LatLng? _userLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          setState(() => _loadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nanniesState = ref.watch(nanniesProvider);
    final allNannies = nanniesState.nannies;
    final mappableNannies = allNannies.where((n) => n.latitude != null && n.longitude != null).toList();
    final center = _userLocation ?? const LatLng(32.0853, 34.7818);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Nearby Nannies', style: AppTextStyles.heading2),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.my_location_rounded, size: 22),
          onPressed: _userLocation != null ? () => _getUserLocation() : null,
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.textPrimary),
            ),
            onPressed: () {
              // Navigate to find screen for filters
              context.go('/home');
            },
          ),
        ],
      ),
      body: _loadingLocation || nanniesState.isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await _getUserLocation();
                ref.read(nanniesProvider.notifier).loadNannies();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── Mini Map Preview ──
                  MiniMapPreview(
                    center: center,
                    nannies: mappableNannies,
                    userLocation: _userLocation,
                    height: 200,
                    onTap: () => context.push('/nearby/fullmap', extra: {
                      'userLocation': _userLocation,
                      'nannies': mappableNannies,
                    }),
                  ),

                  const SizedBox(height: AppSpacing.s20),

                  // ── Results header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
                    child: Row(
                      children: [
                        Text(
                          '${allNannies.length} nannies found',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_userLocation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.xs),
                                Text('Near you', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Nanny List ──
                  if (allNannies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.s40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
                            const SizedBox(height: AppSpacing.xl),
                            Text('No nannies found nearby', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                      child: Column(
                        children: allNannies
                            .map((nanny) => NannyListTile(
                                  nanny: nanny,
                                  onTap: () => context.go('/home/nanny/${nanny.id}'),
                                ))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
