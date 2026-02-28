import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/nanny_card.dart';
import '../../../core/widgets/nanny_card_horizontal.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/category_strip.dart';
import '../../../core/widgets/promo_carousel.dart';
import '../providers/nannies_provider.dart';
import '../providers/home_sections_provider.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedCategory = 'all';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isSearchMode &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(nanniesProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilters() {
    final notifier = ref.read(nanniesProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        currentFilter: notifier.currentFilter,
        onApply: (filter) {
          notifier.applyFilter(filter);
          setState(() => _isSearchMode = true);
        },
      ),
    );
  }

  void _onCategorySelected(String catId) {
    setState(() => _selectedCategory = catId);
    if (catId == 'all') {
      setState(() => _isSearchMode = false);
    } else {
      final skillMap = {
        'infant': 'Infant Care',
        'toddler': 'Toddler Care',
        'school': 'School Age Care',
        'special': 'Special Needs Care',
        'night': 'Overnight Care',
        'weekend': 'Weekend Care',
      };
      final skill = skillMap[catId];
      if (skill != null) {
        ref.read(nanniesProvider.notifier).applyFilter(
          ref.read(nanniesProvider.notifier).currentFilter.copyWith(skill: skill),
        );
        setState(() => _isSearchMode = true);
      }
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isEmpty) {
      setState(() => _isSearchMode = false);
      return;
    }
    ref.read(nanniesProvider.notifier).applyFilter(
      ref.read(nanniesProvider.notifier).currentFilter.copyWith(city: query),
    );
    setState(() => _isSearchMode = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hasFilters = ref.read(nanniesProvider.notifier).currentFilter.hasFilters;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ═══ STICKY HEADER ═══
            _StickyHeader(
              userName: user?.fullName.split(' ').first ?? 'there',
              onNotification: () {},
              onProfile: () => context.go('/profile'),
            ),

            // ═══ SEARCH BAR ═══
            _SearchBar(
              controller: _searchController,
              hasFilters: hasFilters,
              onSubmitted: _onSearchSubmitted,
              onFilterTap: _showFilters,
              onClear: () {
                _searchController.clear();
                setState(() => _isSearchMode = false);
                ref.read(nanniesProvider.notifier).applyFilter(const NannyFilter());
              },
            ),

            // ═══ CONTENT ═══
            Expanded(
              child: _isSearchMode
                  ? _SearchResults(scrollController: _scrollController)
                  : _DiscoveryFeed(
                      scrollController: _scrollController,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: _onCategorySelected,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// STICKY HEADER
// ══════════════════════════════════════════════════════════
class _StickyHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onNotification;
  final VoidCallback onProfile;

  const _StickyHeader({required this.userName, required this.onNotification, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _CircleButton(icon: Icons.notifications_outlined, onTap: onNotification),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Text('My Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Spacer(),
          _CircleButton(icon: Icons.person_outline_rounded, onTap: onProfile),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      );
}

// ══════════════════════════════════════════════════════════
// SEARCH BAR
// ══════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasFilters;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.hasFilters, required this.onSubmitted, required this.onFilterTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Search nannies, cities...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: onSubmitted,
                      onChanged: (v) { if (v.isEmpty) onClear(); },
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: hasFilters ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: hasFilters ? null : Border.all(color: AppColors.divider),
                boxShadow: hasFilters ? AppShadows.primaryGlow(0.15) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, color: hasFilters ? Colors.white : AppColors.textPrimary, size: 20),
                  if (hasFilters)
                    Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// DISCOVERY FEED — Wolt-style sections
// ══════════════════════════════════════════════════════════
class _DiscoveryFeed extends ConsumerWidget {
  final ScrollController scrollController;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _DiscoveryFeed({required this.scrollController, required this.selectedCategory, required this.onCategorySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topRated = ref.watch(topRatedNanniesProvider);
    final availableNow = ref.watch(availableNowNanniesProvider);
    final newNannies = ref.watch(newNanniesProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(topRatedNanniesProvider);
        ref.invalidate(availableNowNanniesProvider);
        ref.invalidate(newNanniesProvider);
      },
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          CategoryStrip(selectedId: selectedCategory, onSelected: onCategorySelected),
          const SizedBox(height: 4),
          const PromoCarousel(),
          const SizedBox(height: 8),

          SectionHeader(title: 'Top Rated', emoji: '\u2B50', onMore: () {}),
          _HorizontalNannyList(asyncValue: topRated),

          SectionHeader(title: 'Available Now', emoji: '\uD83D\uDFE2', onMore: () {}),
          _HorizontalNannyList(asyncValue: availableNow),

          SectionHeader(title: 'All Nannies', emoji: '\uD83D\uDCCD', onMore: () {}),
          _VerticalNannyList(asyncValue: topRated),

          SectionHeader(title: 'New on SuperNanny', emoji: '\uD83C\uDD95', onMore: () {}),
          _HorizontalNannyList(asyncValue: newNannies),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// HORIZONTAL LIST
// ══════════════════════════════════════════════════════════
class _HorizontalNannyList extends ConsumerWidget {
  final AsyncValue<List<NannyModel>> asyncValue;
  const _HorizontalNannyList({required this.asyncValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => const SizedBox(height: 210, child: Center(child: LoadingIndicator())),
      error: (_, __) => const SizedBox(height: 100, child: Center(child: Text('Failed to load', style: TextStyle(color: AppColors.textHint)))),
      data: (nannies) {
        if (nannies.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No nannies found', style: TextStyle(color: AppColors.textHint))));
        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nannies.length,
            itemBuilder: (_, i) => NannyCardHorizontal(nanny: nannies[i], onTap: () => context.go('/home/nanny/${nannies[i].id}')),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// VERTICAL LIST (full-width cards)
// ══════════════════════════════════════════════════════════
class _VerticalNannyList extends ConsumerWidget {
  final AsyncValue<List<NannyModel>> asyncValue;
  const _VerticalNannyList({required this.asyncValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => const SizedBox(height: 200, child: Center(child: LoadingIndicator())),
      error: (_, __) => const SizedBox(height: 100, child: Center(child: Text('Failed to load', style: TextStyle(color: AppColors.textHint)))),
      data: (nannies) {
        if (nannies.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: nannies.take(3).map((n) => NannyCard(nanny: n, onTap: () => context.go('/home/nanny/${n.id}'))).toList()),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// SEARCH RESULTS
// ══════════════════════════════════════════════════════════
class _SearchResults extends ConsumerWidget {
  final ScrollController scrollController;
  const _SearchResults({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nanniesProvider);
    if (state.isLoading) return const Center(child: LoadingIndicator());
    if (state.error != null) {
      return EmptyState(title: 'Could not load nannies', subtitle: state.error!, icon: Icons.wifi_off_rounded, actionLabel: 'Retry', onAction: () => ref.read(nanniesProvider.notifier).loadNannies());
    }
    if (state.nannies.isEmpty) return const EmptyState(title: 'No nannies found', subtitle: 'Try adjusting your search or filters', icon: Icons.search_off_rounded);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.nannies.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == state.nannies.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicator()));
        final nanny = state.nannies[i];
        return NannyCard(nanny: nanny, onTap: () => context.go('/home/nanny/${nanny.id}'));
      },
    );
  }
}
