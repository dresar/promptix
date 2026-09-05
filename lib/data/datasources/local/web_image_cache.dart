import 'dart:typed_data';

class WebImageCache {
  static final Map<String, Uint8List> _cache = {};

  static void put(String key, Uint8List bytes) {
    _cache[key] = bytes;
  }

  static Uint8List? get(String key) {
    return _cache[key];
  }

  static bool contains(String key) {
    return _cache.containsKey(key);
  }

  static void remove(String key) {
    _cache.remove(key);
  }

  static void clear() {
    _cache.clear();
  }
}
