import 'dart:async';
import 'dart:convert';
import '../interface/storage_platform_interface.dart';

/// The primary entry point for managing synchronous, reactive web storage.
class FlutterWebStorage {
  // Private constructor to enforce Singleton pattern
  FlutterWebStorage._();

  /// Singleton instance of [FlutterWebStorage].
  static final FlutterWebStorage instance = FlutterWebStorage._();

  /// Retrieve the underlying platform interface driver instance.
  StoragePlatformInterface get _platform => StoragePlatform.instance;

  // ==========================================
  // PRIMITIVES (Synchronous Get/Set)
  // ==========================================

  /// Synchronously gets a String value for [key] from the specified [area].
  String? getString(String key, {StorageArea area = StorageArea.session}) {
    return _platform.getItem(area, key);
  }

  /// Synchronously sets a String [value] for [key] in the specified [area].
  void setString(String key, String value, {StorageArea area = StorageArea.session}) {
    _platform.setItem(area, key, value);
  }

  /// Synchronously gets an int value for [key] from the specified [area].
  int? getInt(String key, {StorageArea area = StorageArea.session}) {
    final val = getString(key, area: area);
    if (val == null) return null;
    return int.tryParse(val);
  }

  /// Synchronously sets an int [value] for [key] in the specified [area].
  void setInt(String key, int value, {StorageArea area = StorageArea.session}) {
    setString(key, value.toString(), area: area);
  }

  /// Synchronously gets a double value for [key] from the specified [area].
  double? getDouble(String key, {StorageArea area = StorageArea.session}) {
    final val = getString(key, area: area);
    if (val == null) return null;
    return double.tryParse(val);
  }

  /// Synchronously sets a double [value] for [key] in the specified [area].
  void setDouble(String key, double value, {StorageArea area = StorageArea.session}) {
    setString(key, value.toString(), area: area);
  }

  /// Synchronously gets a bool value for [key] from the specified [area].
  bool? getBool(String key, {StorageArea area = StorageArea.session}) {
    final val = getString(key, area: area);
    if (val == null) return null;
    return val == 'true';
  }

  /// Synchronously sets a bool [value] for [key] in the specified [area].
  void setBool(String key, bool value, {StorageArea area = StorageArea.session}) {
    setString(key, value.toString(), area: area);
  }

  // ==========================================
  // LISTS & ARRAYS
  // ==========================================

  /// Synchronously gets a List of Strings for [key] from the specified [area].
  List<String>? getStringList(String key, {StorageArea area = StorageArea.session}) {
    final val = getString(key, area: area);
    if (val == null) return null;
    try {
      final decoded = jsonDecode(val);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Synchronously sets a List of Strings [value] for [key] in the specified [area].
  void setStringList(String key, List<String> value, {StorageArea area = StorageArea.session}) {
    setString(key, jsonEncode(value), area: area);
  }

  /// Synchronously gets a List of Custom Objects [T] for [key] from the specified [area].
  List<T>? getObjectList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    StorageArea area = StorageArea.session,
  }) {
    final val = getString(key, area: area);
    if (val == null) return null;
    try {
      final decoded = jsonDecode(val);
      if (decoded is List) {
        return decoded.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return null;
  }

  /// Synchronously sets a List of Custom Objects [T] [list] for [key] in the specified [area].
  void setObjectList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T item) toJson, {
    StorageArea area = StorageArea.session,
  }) {
    final serialized = list.map((e) => toJson(e)).toList();
    setString(key, jsonEncode(serialized), area: area);
  }

  // ==========================================
  // JSON & CUSTOM MODELS
  // ==========================================

  /// Synchronously gets a JSON Map for [key] from the specified [area].
  Map<String, dynamic>? getJson(String key, {StorageArea area = StorageArea.session}) {
    final val = getString(key, area: area);
    if (val == null) return null;
    try {
      final decoded = jsonDecode(val);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Synchronously sets a JSON Map [value] for [key] in the specified [area].
  void setJson(String key, Map<String, dynamic> value, {StorageArea area = StorageArea.session}) {
    setString(key, jsonEncode(value), area: area);
  }

  /// Synchronously gets a Custom Object [T] for [key] from the specified [area].
  T? getObject<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    StorageArea area = StorageArea.session,
  }) {
    final val = getJson(key, area: area);
    if (val == null) return null;
    return fromJson(val);
  }

  /// Synchronously sets a Custom Object [T] [object] for [key] in the specified [area].
  void setObject<T>(
    String key,
    T object,
    Map<String, dynamic> Function(T item) toJson, {
    StorageArea area = StorageArea.session,
  }) {
    setJson(key, toJson(object), area: area);
  }

  // ==========================================
  // UTILITIES
  // ==========================================

  /// Checks if [key] is present in the specified [area].
  bool containsKey(String key, {StorageArea area = StorageArea.session}) {
    return _platform.containsKey(area, key);
  }

  /// Removes [key] and its value from the specified [area].
  void remove(String key, {StorageArea area = StorageArea.session}) {
    _platform.removeItem(area, key);
  }

  /// Clears all keys and values in the specified [area].
  void clear({StorageArea area = StorageArea.session}) {
    _platform.clear(area);
  }

  /// Retrieves a set of all keys present in the specified [area].
  Set<String> getKeys({StorageArea area = StorageArea.session}) {
    return _platform.getKeys(area);
  }

  // ==========================================
  // REACTIVE STREAMS
  // ==========================================

  /// Returns a stream of String values for the given [key] in the specified [area].
  /// Emits the current value immediately upon subscription.
  Stream<String?> watchString(String key, {StorageArea area = StorageArea.session}) {
    final controller = StreamController<String?>.broadcast(sync: true);

    controller.onListen = () {
      controller.add(getString(key, area: area));
    };

    final subscription = _platform.onStorageChanged
        .where((event) => event.area == area && (event.key == null || event.key == key))
        .listen((event) {
      if (event.key == null) {
        controller.add(null);
      } else {
        controller.add(getString(key, area: area));
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Returns a stream of JSON Map values for the given [key] in the specified [area].
  /// Emits the current value immediately upon subscription.
  Stream<Map<String, dynamic>?> watchJson(String key, {StorageArea area = StorageArea.session}) {
    return watchString(key, area: area).map<Map<String, dynamic>?>((val) {
      if (val == null) return null;
      try {
        final decoded = jsonDecode(val);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      return null;
    });
  }

  /// Returns a stream of typed values [T] for the given [key] in the specified [area].
  /// If [decoder] is provided, it parses the dynamic representation. Otherwise, it
  /// attempts to parse primitive types or fallback to direct cast.
  /// Emits the current value immediately upon subscription.
  Stream<T?> watch<T>(
    String key, {
    T Function(dynamic raw)? decoder,
    StorageArea area = StorageArea.session,
  }) {
    return watchString(key, area: area).map<T?>((val) {
      if (val == null) return null;
      if (decoder != null) {
        try {
          final decoded = jsonDecode(val);
          return decoder(decoded);
        } catch (_) {
          try {
            return decoder(val);
          } catch (_) {
            return null;
          }
        }
      }

      // Handle common primitive conversions automatically
      if (T == String) {
        return val as T;
      }
      if (T == int) {
        return int.tryParse(val) as T?;
      }
      if (T == double) {
        return double.tryParse(val) as T?;
      }
      if (T == bool) {
        return (val == 'true') as T?;
      }

      // Fallback: try decoding as dynamic JSON
      try {
        final decoded = jsonDecode(val);
        return decoded as T?;
      } catch (_) {
        return null;
      }
    });
  }
}
