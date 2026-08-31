import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../interface/storage_platform_interface.dart';
import '../core/flutter_web_storage_impl.dart';

/// A [TextEditingController] subclass that automatically loads its initial text
/// synchronously from [StorageArea.session] on boot, and updates the cache
/// instantly on every character typed.
class ReloadSafeTextEditingController extends TextEditingController {
  /// The unique storage key.
  final String key;

  /// The storage area to save to (defaults to [StorageArea.session]).
  final StorageArea area;

  ReloadSafeTextEditingController({
    String? key,
    String? storageKey,
    this.area = StorageArea.session,
    String? defaultValue,
    String? fallbackText,
  })  : key = key ?? storageKey ?? '',
        super(
          text: FlutterWebStorage.instance.getString(key ?? storageKey ?? '', area: area) ??
              defaultValue ??
              fallbackText ??
              '',
        ) {
    addListener(_saveText);
  }

  void _saveText() {
    FlutterWebStorage.instance.setString(key, text, area: area);
  }

  @override
  void dispose() {
    removeListener(_saveText);
    super.dispose();
  }
}

/// A [ValueNotifier] subclass that auto-persists and rehydrates state.
/// Supports both primitive types and complex models using [toJson] and [fromJson].
class ReloadSafeNotifier<T> extends ValueNotifier<T> {
  /// The unique storage key.
  final String key;

  /// The storage area to save to (defaults to [StorageArea.session]).
  final StorageArea area;

  /// Serialization callback for custom objects.
  final Map<String, dynamic> Function(T item)? toJson;

  /// Deserialization callback for custom objects.
  final T Function(Map<String, dynamic> json)? fromJson;

  ReloadSafeNotifier({
    required this.key,
    required T defaultValue,
    this.area = StorageArea.session,
    this.toJson,
    this.fromJson,
  }) : super(_hydrateValue(key, defaultValue, area, fromJson)) {
    addListener(_saveValue);
  }

  static T _hydrateValue<T>(
    String key,
    T defaultValue,
    StorageArea area,
    T Function(Map<String, dynamic> json)? fromJson,
  ) {
    final storage = FlutterWebStorage.instance;

    // 1. If deserializer is supplied, fetch object list or single object
    if (fromJson != null) {
      final obj = storage.getObject<T>(key, fromJson, area: area);
      if (obj != null) return obj;
    }

    // 2. Perform direct type checks for primitives
    if (T == String) {
      final str = storage.getString(key, area: area);
      if (str != null) return str as T;
    } else if (T == int) {
      final val = storage.getInt(key, area: area);
      if (val != null) return val as T;
    } else if (T == double) {
      final val = storage.getDouble(key, area: area);
      if (val != null) return val as T;
    } else if (T == bool) {
      final val = storage.getBool(key, area: area);
      if (val != null) return val as T;
    }

    // 3. Check for raw Map fallback
    if (defaultValue is Map) {
      final jsonMap = storage.getJson(key, area: area);
      if (jsonMap != null) return jsonMap as T;
    }

    // 4. Try parsing general JSON string
    final raw = storage.getString(key, area: area);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is T) {
          return decoded;
        }
      } catch (_) {}
    }

    return defaultValue;
  }

  void _saveValue() {
    final storage = FlutterWebStorage.instance;
    final val = value;

    if (toJson != null) {
      storage.setObject<T>(key, val, toJson!, area: area);
    } else if (val is String) {
      storage.setString(key, val, area: area);
    } else if (val is int) {
      storage.setInt(key, val, area: area);
    } else if (val is double) {
      storage.setDouble(key, val, area: area);
    } else if (val is bool) {
      storage.setBool(key, val, area: area);
    } else if (val is Map<String, dynamic>) {
      storage.setJson(key, val, area: area);
    } else {
      // Fallback: encode standard JSON objects/lists
      try {
        storage.setString(key, jsonEncode(val), area: area);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    removeListener(_saveValue);
    super.dispose();
  }
}
