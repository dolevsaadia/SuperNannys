/// ──────────────────────────────────────────────────────────────
/// Safe API Response Parsing Helpers
/// ──────────────────────────────────────────────────────────────
/// Provides null-safe extraction of data from Dio responses.
/// Guards against unexpected response structures from the backend.

import 'package:dio/dio.dart';

/// Extract the `data` field from a standard API response envelope.
/// Our backend always wraps responses in `{ success: true, data: ... }`.
///
/// Returns `Map<String, dynamic>` or throws a clear error.
Map<String, dynamic> extractDataMap(Response resp) {
  final body = resp.data;
  if (body is! Map<String, dynamic>) {
    throw FormatException('Expected JSON object, got ${body.runtimeType}');
  }
  final data = body['data'];
  if (data is! Map<String, dynamic>) {
    throw FormatException('Expected data to be a Map, got ${data.runtimeType}');
  }
  return data;
}

/// Extract a nested list from the response data field.
/// e.g. `extractDataList(resp, 'bookings')` for `{ data: { bookings: [...] } }`
List<dynamic> extractDataList(Response resp, String key) {
  final data = extractDataMap(resp);
  final list = data[key];
  if (list is! List<dynamic>) {
    return [];
  }
  return list;
}

/// Extract the `data` field as a List (when data itself is a list).
List<dynamic> extractDataAsList(Response resp) {
  final body = resp.data;
  if (body is! Map<String, dynamic>) {
    throw FormatException('Expected JSON object, got ${body.runtimeType}');
  }
  final data = body['data'];
  if (data is List<dynamic>) return data;
  return [];
}
