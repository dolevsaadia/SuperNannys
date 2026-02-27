import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/nanny_card.dart';
import '../providers/nannies_provider.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
        onApply: (filter) => notifier.applyFilter(filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nanniesProvider);
    final user = ref.watch(currentUserProvider);
    final hasFilters = ref.read(nanniesProvider.notifier).currentFilter.hasFilters;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi ${user?.fullName.split(' ').first ?? 'there'} 👋',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const Text(
                              'Find your nanny',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      // Notification bell
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search + filter row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search by city, name...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (v) {
                                    ref.read(nanniesProvider.notifier).applyFilter(
                                      ref.read(nanniesProvider.notifier).currentFilter.copyWith(
                                        city: v.isEmpty ? null : v,
                                        clearCity: v.isEmpty,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showFilters,
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: hasFilters ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: hasFilters ? AppColors.primary : AppColors.border),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.tune_rounded, color: hasFilters ? Colors.white : AppColors.textPrimary, size: 20),
                              if (hasFilters)
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sort tabs
            Container(
              height: 44,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _SortChip(label: 'Top Rated', value: 'rating', notifier: ref.read(nanniesProvider.notifier)),
                  _SortChip(label: 'Price ↑', value: 'rate_asc', notifier: ref.read(nanniesProvider.notifier)),
                  _SortChip(label: 'Price ↓', value: 'rate_desc', notifier: ref.read(nanniesProvider.notifier)),
                  _SortChip(label: 'Experience', value: 'experience', notifier: ref.read(nanniesProvider.notifier)),
                  _SortChip(label: 'Most Reviews', value: 'reviews', notifier: ref.read(nanniesProvider.notifier)),
                ],
              ),
            ),

            const Divider(height: 1),

            // Results
            Expanded(
              child: state.isLoading
                  ? const Center(child: LoadingIndicator())
                  : state.error != null
                      ? EmptyState(
                          title: 'Could not load nannies',
                          subtitle: state.error!,
                          icon: Icons.wifi_off_rounded,
                          actionLabel: 'Retry',
                          onAction: () => ref.read(nanniesProvider.notifier).loadNannies(),
                        )
                      : state.nannies.isEmpty
                          ? const EmptyState(
                              title: 'No nannies found',
                              subtitle: 'Try adjusting your filters',
                              icon: Icons.search_off_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref.read(nanniesProvider.notifier).loadNannies(),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: state.nannies.length + (state.isLoadingMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == state.nannies.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: LoadingIndicator()),
                                    );
                                  }
                                  final nanny = state.nannies[i];
                                  return NannyCard(
                                    nanny: nanny,
                                    onTap: () => context.go('/home/nanny/${nanny.id}'),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  final String label;
  final String value;
  final NanniesNotifier notifier;

  const _SortChip({required this.label, required this.value, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(nanniesProvider.notifier).currentFilter.sortBy;
    final selected = current == value;

    return GestureDetector(
      onTap: () => notifier.applyFilter(notifier.currentFilter.copyWith(sortBy: value)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
