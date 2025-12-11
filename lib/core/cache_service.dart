import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk caching data lokal untuk mengurangi request ke Supabase
class CacheService {
  static const String _cachePrefix = 'sigap_cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  
  /// Save data to cache
  static Future<void> saveCache(String key, dynamic data, {Duration? duration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now()
            .add(duration ?? _defaultCacheDuration)
            .millisecondsSinceEpoch,
      };
      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      // Silently fail - cache is optional
      print('Cache save error: $e');
    }
  }
  
  /// Get data from cache
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_cachePrefix$key');
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final expiresAt = cacheData['expiresAt'] as int;
      
      // Check if cache is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await prefs.remove('$_cachePrefix$key');
        return null;
      }
      
      return cacheData['data'];
    } catch (e) {
      return null;
    }
  }
  
  /// Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Check if cache exists and is valid
  static Future<bool> hasValidCache(String key) async {
    final cache = await getCache(key);
    return cache != null;
  }
}

