import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';

/// Utility for resolving and managing image URLs across the app.
class ImageUtils {
  ImageUtils._();

  /// The base URL for the API server (without /api suffix).
  /// Derived from [AppConstants.apiBaseUrl] by stripping the `/api` path.
  static String get _serverBase {
    final base = AppConstants.apiBaseUrl;
    // Remove trailing /api to get the server root
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  /// Resolves an avatar URL that may be:
  /// - null/empty → returns null
  /// - A full URL (https://...) → returns as-is
  /// - A relative path (/uploads/...) → prepends server base URL
  static String? resolveAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Relative path like /uploads/avatar-xxx.jpg
    return '$_serverBase$url';
  }

  /// Evicts a specific image URL from the CachedNetworkImage cache.
  /// Call this after uploading a new avatar to ensure the old one is not shown.
  static Future<void> evictFromCache(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(url);
    } catch (_) {
      // Silently ignore — cache eviction is best-effort
    }
  }

  /// Evicts all possible variants of an avatar URL from cache
  /// (both relative and absolute forms).
  static Future<void> evictAvatarFromCache(String? url) async {
    if (url == null || url.isEmpty) return;
    await evictFromCache(url);
    // Also evict the resolved version in case both forms are cached
    final resolved = resolveAvatarUrl(url);
    if (resolved != null && resolved != url) {
      await evictFromCache(resolved);
    }
  }
}
