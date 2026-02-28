import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';

/// Fetches nannies for a specific home section with custom params
Future<List<NannyModel>> _fetchSection(Map<String, dynamic> params) async {
  final resp = await apiClient.dio.get('/nannies', queryParameters: params);
  final data = resp.data['data'] as Map<String, dynamic>;
  return (data['nannies'] as List<dynamic>)
      .map((e) => NannyModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Top Rated nannies (sorted by rating, limit 10)
final topRatedNanniesProvider = FutureProvider.autoDispose<List<NannyModel>>((ref) async {
  return _fetchSection({'sortBy': 'rating', 'page': '1', 'limit': '10'});
});

/// Available Now nannies (only available, limit 10)
final availableNowNanniesProvider = FutureProvider.autoDispose<List<NannyModel>>((ref) async {
  return _fetchSection({'sortBy': 'rating', 'available': 'true', 'page': '1', 'limit': '10'});
});

/// New nannies (sorted by newest, limit 10)
final newNanniesProvider = FutureProvider.autoDispose<List<NannyModel>>((ref) async {
  return _fetchSection({'sortBy': 'newest', 'page': '1', 'limit': '10'});
});

/// Near You nannies (sorted by distance, limit 8)
final nearbyNanniesProvider = FutureProvider.autoDispose.family<List<NannyModel>, ({double lat, double lng})>(
  (ref, coords) async {
    return _fetchSection({
      'sortBy': 'distance',
      'lat': coords.lat.toString(),
      'lng': coords.lng.toString(),
      'page': '1',
      'limit': '8',
    });
  },
);
