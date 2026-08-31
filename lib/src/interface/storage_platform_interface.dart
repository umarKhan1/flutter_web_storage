import 'dart:async';
import '../stub/storage_stub.dart' if (dart.library.js_interop) '../web/storage_web.dart' as impl;

/// Defines the target storage locations in the browser or backends.
enum StorageArea {
  /// Session storage: tab-scoped, survives F5 reload, cleared when tab closes.
  session,

  /// Local storage: permanent across tabs and browser restarts.
  local,
}

/// Represents a change event occurred in either Local or Session storage.
class StorageEventData {
  /// The storage area where the change occurred.
  final StorageArea area;

  /// The storage key that was changed. Null if the storage area was cleared.
  final String? key;

  /// The new value stored. Null if the key was removed or cleared.
  final String? newValue;

  /// The previous value before the change. Null if it was a new entry or cleared.
  final String? oldValue;

  const StorageEventData({
    required this.area,
    this.key,
    this.newValue,
    this.oldValue,
  });
}

/// Abstract definition of the storage driver, implemented conditionally
/// for both web (JS interop) and non-web (stub) environments.
abstract class StoragePlatformInterface {
  /// Sets up lifecycle event listeners (e.g. beforeunload / storage hooks).
  void initialize();

  /// Synchronously retrieves an item from the specified storage area.
  String? getItem(StorageArea area, String key);

  /// Synchronously sets an item in the specified storage area.
  void setItem(StorageArea area, String key, String value);

  /// Synchronously removes an item from the specified storage area.
  void removeItem(StorageArea area, String key);

  /// Synchronously clears all items from the specified storage area.
  void clear(StorageArea area);

  /// Synchronously checks if a key exists in the specified storage area.
  bool containsKey(StorageArea area, String key);

  /// Synchronously retrieves all keys stored in the specified storage area.
  Set<String> getKeys(StorageArea area);

  /// Broadcast stream emitting events when storage values change.
  Stream<StorageEventData> get onStorageChanged;
}

/// Global entry point to get the active platform implementation.
abstract class StoragePlatform {
  static StoragePlatformInterface? _instance;

  /// Retrieves the active instance of [StoragePlatformInterface].
  static StoragePlatformInterface get instance {
    if (_instance == null) {
      _instance = impl.createPlatformInstance();
      _instance!.initialize();
    }
    return _instance!;
  }
}

