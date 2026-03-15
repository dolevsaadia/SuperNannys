import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/constants/israeli_cities.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/async_value_ui.dart';
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
          // Sync category bar with filter selection
          setState(() {
            _isSearchMode = filter.hasFilters;
            if (filter.hasRecurringRate == true) {
              _selectedCategory = 'ongoing';
            } else if (filter.skill != null) {
              // Reverse-map skill name back to category ID
              _selectedCategory = _skillToCategoryId(filter.skill!) ?? 'all';
            } else {
              _selectedCategory = 'all';
            }
          });
        },
      ),
    );
  }

  /// Maps a skill name back to its category ID for syncing the category bar
  static String? _skillToCategoryId(String skill) {
    const reverseSkillMap = {
      'Infant Care': 'infant',
      'Toddler Care': 'toddler',
      'School Age Care': 'school',
      'Special Needs Care': 'special',
      'First Aid Certified': 'first_aid',
      'Overnight Care': 'night',
      'Weekend Care': 'weekend',
    };
    return reverseSkillMap[skill];
  }

  void _onCategorySelected(String catId) {
    setState(() => _selectedCategory = catId);
    final notifier = ref.read(nanniesProvider.notifier);

    if (catId == 'all') {
      // Reset all filters and go back to discovery feed
      notifier.applyFilter(const NannyFilter());
      setState(() => _isSearchMode = false);
    } else if (catId == 'ongoing') {
      // Filter for nannies who offer recurring/ongoing care rates
      // Clear any previous skill filter when switching to ongoing
      notifier.applyFilter(
        notifier.currentFilter.copyWith(hasRecurringRate: true, clearSkill: true),
      );
      setState(() => _isSearchMode = true);
    } else {
      const skillMap = {
        'infant': 'Infant Care',
        'toddler': 'Toddler Care',
        'school': 'School Age Care',
        'special': 'Special Needs Care',
        'first_aid': 'First Aid Certified',
        'night': 'Overnight Care',
        'weekend': 'Weekend Care',
      };
      final skill = skillMap[catId];
      if (skill != null) {
        // Clear hasRecurringRate when switching to a skill-based category
        notifier.applyFilter(
          NannyFilter(
            city: notifier.currentFilter.city,
            minRate: notifier.currentFilter.minRate,
            maxRate: notifier.currentFilter.maxRate,
            minYears: notifier.currentFilter.minYears,
            language: notifier.currentFilter.language,
            minRating: notifier.currentFilter.minRating,
            lat: notifier.currentFilter.lat,
            lng: notifier.currentFilter.lng,
            radiusKm: notifier.currentFilter.radiusKm,
            skill: skill,
          ),
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
    final backendCity = IsraeliCities.toBackendQuery(query);
    ref.read(nanniesProvider.notifier).applyFilter(
      ref.read(nanniesProvider.notifier).currentFilter.copyWith(city: backendCity),
    );
    setState(() => _isSearchMode = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hasFilters = ref.read(nanniesProvider.notifier).currentFilter.hasFilters;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
          children: [
            // ═══ STICKY HEADER ═══
            _StickyHeader(
              userName: user?.fullName.split(' ').first ?? 'there',
              onNotification: () => context.go('/chat'),
              onProfile: () => context.go('/profile'),
              onLocationSelected: (city) {
                if (city.isEmpty) {
                  // Use current location - clear city filter
                  ref.read(nanniesProvider.notifier).applyFilter(
                    ref.read(nanniesProvider.notifier).currentFilter.copyWith(city: ''),
                  );
                } else {
                  _searchController.text = city;
                  final backendCity = IsraeliCities.toBackendQuery(city);
                  ref.read(nanniesProvider.notifier).applyFilter(
                    ref.read(nanniesProvider.notifier).currentFilter.copyWith(city: backendCity),
                  );
                  setState(() => _isSearchMode = true);
                }
              },
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
class _StickyHeader extends StatefulWidget {
  final String userName;
  final VoidCallback onNotification;
  final VoidCallback onProfile;
  final ValueChanged<String>? onLocationSelected;

  const _StickyHeader({required this.userName, required this.onNotification, required this.onProfile, this.onLocationSelected});

  @override
  State<_StickyHeader> createState() => _StickyHeaderState();
}

class _StickyHeaderState extends State<_StickyHeader> {
  String _selectedLocation = 'My Location';

  void _showLocationPicker() {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final suggestions = IsraeliCities.search(searchController.text).take(15).toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Use current location option
                ListTile(
                  leading: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                  title: const Text('Use My Location', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
                  onTap: () {
                    setState(() => _selectedLocation = 'My Location');
                    widget.onLocationSelected?.call('');
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textHint),
                      title: Text(suggestions[i], style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        setState(() => _selectedLocation = suggestions[i]);
                        widget.onLocationSelected?.call(suggestions[i]);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(
        children: [
          _CircleButton(icon: Icons.notifications_outlined, onTap: widget.onNotification),
          const Spacer(),
          GestureDetector(
            onTap: _showLocationPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(_selectedLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
          const Spacer(),
          _CircleButton(icon: Icons.person_outline_rounded, onTap: widget.onProfile),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6, offset: const Offset(0, 1))],
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      );
}

// ══════════════════════════════════════════════════════════
// SEARCH BAR
// ══════════════════════════════════════════════════════════
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final bool hasFilters;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.hasFilters, required this.onSubmitted, required this.onFilterTap, required this.onClear});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _updateSuggestions(widget.controller.text);
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  void _updateSuggestions(String query) {
    _suggestions = IsraeliCities.search(query).take(6).toList();
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _hideOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: renderBox.size.width - 74, // account for filter button
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: _suggestions.isEmpty
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final city = _suggestions[i];
                        return InkWell(
                          onTap: () {
                            widget.controller.text = city;
                            widget.onSubmitted(city);
                            _hideOverlay();
                            _focusNode.unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(city, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Search by city or area...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          widget.onSubmitted(v);
                          _hideOverlay();
                        },
                        onChanged: (v) {
                          if (v.isEmpty) {
                            widget.onClear();
                          }
                          _updateSuggestions(v);
                          if (_overlayEntry == null && _focusNode.hasFocus) _showOverlay();
                        },
                      ),
                    ),
                    if (widget.controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          widget.onClear();
                          _hideOverlay();
                        },
                        child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: widget.hasFilters ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.hasFilters ? null : Border.all(color: AppColors.divider),
                  boxShadow: widget.hasFilters ? AppShadows.primaryGlow(0.15) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.tune_rounded, color: widget.hasFilters ? Colors.white : AppColors.textPrimary, size: 18),
                    if (widget.hasFilters)
                      Positioned(top: 8, right: 8, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle))),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    return asyncValue.authAwareWhen(
      ref,
      loading: () => SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: NannyCardSkeleton(),
          ),
        ),
      ),
      error: (_, __) => const InlineAsyncError(height: 100),
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
    return asyncValue.authAwareWhen(
      ref,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SkeletonList(count: 3, skeleton: NannyCardSkeleton(), padding: EdgeInsets.zero),
      ),
      error: (_, __) => const InlineAsyncError(height: 100),
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
    if (state.isLoading) return const SkeletonList(count: 4, skeleton: NannyCardSkeleton());
    if (state.error != null) {
      return EmptyState(title: 'Could not load nannies', subtitle: state.error!, icon: Icons.wifi_off_rounded, actionLabel: 'Retry', onAction: () => ref.read(nanniesProvider.notifier).loadNannies());
    }
    if (state.nannies.isEmpty) return const EmptyState(title: 'No nannies found', subtitle: 'Try adjusting your search or filters', icon: Icons.search_off_rounded);

    final currentSort = ref.read(nanniesProvider.notifier).currentFilter.sortBy;

    return Column(
      children: [
        // ── Results count + sort bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${state.total} nannies found',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const Spacer(),
              _SortDropdown(
                currentSort: currentSort,
                onChanged: (sort) {
                  final notifier = ref.read(nanniesProvider.notifier);
                  notifier.applyFilter(notifier.currentFilter.copyWith(sortBy: sort));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.nannies.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == state.nannies.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: LoadingIndicator()));
              final nanny = state.nannies[i];
              return NannyCard(nanny: nanny, onTap: () => context.go('/home/nanny/${nanny.id}'));
            },
          ),
        ),
      ],
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onChanged;

  const _SortDropdown({required this.currentSort, required this.onChanged});

  static const _options = {
    'rating': 'Top Rated',
    'rate_asc': 'Price: Low → High',
    'rate_desc': 'Price: High → Low',
    'experience': 'Most Experienced',
    'reviews': 'Most Reviews',
    'newest': 'Newest',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              _options[currentSort] ?? 'Sort',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (_) => _options.entries.map((e) => PopupMenuItem<String>(
        value: e.key,
        child: Row(
          children: [
            if (e.key == currentSort)
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(e.value, style: TextStyle(
              fontSize: 13,
              fontWeight: e.key == currentSort ? FontWeight.w700 : FontWeight.w500,
              color: e.key == currentSort ? AppColors.primary : AppColors.textPrimary,
            )),
          ],
        ),
      )).toList(),
    );
  }
}
