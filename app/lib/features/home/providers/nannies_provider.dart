import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/services/app_logger.dart';

class NannyFilter {
  final String? city;
  final int? minRate;
  final int? maxRate;
  final int? minYears;
  final String? language;
  final String? skill;
  final double? minRating;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String sortBy;
  final bool? hasRecurringRate;

  const NannyFilter({
    this.city, this.minRate, this.maxRate, this.minYears,
    this.language, this.skill, this.minRating, this.lat, this.lng,
    this.radiusKm, this.sortBy = 'rating', this.hasRecurringRate,
  });

  NannyFilter copyWith({
    String? city, int? minRate, int? maxRate, int? minYears,
    String? language, String? skill, double? minRating,
    double? lat, double? lng, double? radiusKm, String? sortBy,
    bool? hasRecurringRate,
    bool clearCity = false, bool clearLanguage = false, bool clearSkill = false,
    bool clearRecurring = false, bool clearMinRate = false, bool clearMaxRate = false,
    bool clearMinYears = false, bool clearMinRating = false,
  }) => NannyFilter(
        city: clearCity ? null : city ?? this.city,
        minRate: clearMinRate ? null : minRate ?? this.minRate,
        maxRate: clearMaxRate ? null : maxRate ?? this.maxRate,
        minYears: clearMinYears ? null : minYears ?? this.minYears,
        language: clearLanguage ? null : language ?? this.language,
        skill: clearSkill ? null : skill ?? this.skill,
        minRating: clearMinRating ? null : minRating ?? this.minRating,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusKm: radiusKm ?? this.radiusKm,
        sortBy: sortBy ?? this.sortBy,
        hasRecurringRate: clearRecurring ? null : hasRecurringRate ?? this.hasRecurringRate,
      );

  Map<String, dynamic> toQueryParams() {
    final m = <String, dynamic>{'sortBy': sortBy};
    if (city != null) m['city'] = city;
    if (minRate != null) m['minRate'] = minRate.toString();
    if (maxRate != null) m['maxRate'] = maxRate.toString();
    if (minYears != null) m['minYears'] = minYears.toString();
    if (language != null) m['language'] = language;
    if (skill != null) m['skill'] = skill;
    if (minRating != null) m['minRating'] = minRating.toString();
    if (lat != null) m['lat'] = lat.toString();
    if (lng != null) m['lng'] = lng.toString();
    if (radiusKm != null) m['radiusKm'] = radiusKm.toString();
    if (hasRecurringRate == true) m['hasRecurringRate'] = 'true';
    return m;
  }

  bool get hasFilters =>
      city != null || minRate != null || maxRate != null || minYears != null ||
      language != null || skill != null || minRating != null || hasRecurringRate == true;
}

class NanniesState {
  final List<NannyModel> nannies;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int total;
  final int page;
  final bool hasMore;

  const NanniesState({
    this.nannies = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.hasMore = true,
  });

  NanniesState copyWith({
    List<NannyModel>? nannies, bool? isLoading, bool? isLoadingMore,
    String? error, int? total, int? page, bool? hasMore,
  }) => NanniesState(
        nannies: nannies ?? this.nannies,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        total: total ?? this.total,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
      );
}

class NanniesNotifier extends StateNotifier<NanniesState> {
  NannyFilter _filter = const NannyFilter();

  NanniesNotifier() : super(const NanniesState()) {
    loadNannies();
  }

  Future<void> loadNannies({NannyFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = state.copyWith(isLoading: true, error: null, page: 1);

    try {
      final resp = await apiClient.dio.get('/nannies', queryParameters: {
        ..._filter.toQueryParams(), 'page': '1', 'limit': '20',
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      final list = (data['nannies'] as List<dynamic>)
          .map((e) => NannyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      state = NanniesState(
        nannies: list,
        isLoading: false,
        total: pagination['total'] as int,
        page: 1,
        hasMore: list.length < (pagination['total'] as int),
      );
    } catch (e) {
      final msg = e is DioException && e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString() ?? 'Failed to load nannies'
          : e is DioException && e.type == DioExceptionType.connectionError
              ? 'No internet connection'
              : 'Failed to load nannies';
      appLog.warn('nannies', 'load_failed', msg, extra: {'error': e.toString()});
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final resp = await apiClient.dio.get('/nannies', queryParameters: {
        ..._filter.toQueryParams(), 'page': nextPage.toString(), 'limit': '20',
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      final list = (data['nannies'] as List<dynamic>)
          .map((e) => NannyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        nannies: [...state.nannies, ...list],
        isLoadingMore: false,
        page: nextPage,
        hasMore: state.nannies.length + list.length < state.total,
      );
    } catch (e) {
      appLog.warn('nannies', 'load_more_failed', 'Failed to load more nannies', extra: {'error': e.toString()});
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void applyFilter(NannyFilter filter) => loadNannies(filter: filter);
  NannyFilter get currentFilter => _filter;
}

final nanniesProvider = StateNotifierProvider<NanniesNotifier, NanniesState>((ref) {
  final notifier = NanniesNotifier();
  // Re-fetch when data changes elsewhere (booking created, favorite toggled, etc.)
  ref.listen(dataRefreshProvider, (_, __) => notifier.loadNannies());
  return notifier;
});
