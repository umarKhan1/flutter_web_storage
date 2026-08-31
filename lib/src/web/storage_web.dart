import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../interface/storage_platform_interface.dart';

/// Instantiates the web storage driver.
StoragePlatformInterface createPlatformInstance() => StorageWeb();

/// Web implementation of [StoragePlatformInterface] utilizing `package:web`
/// and JS interop to read/write synchronously.
class StorageWeb implements StoragePlatformInterface {
  late final web.Storage _localStorage;
  late final web.Storage _sessionStorage;
  final StreamController<StorageEventData> _changeController = StreamController<StorageEventData>.broadcast(sync: true);

  StorageWeb() {
    _localStorage = web.window.localStorage;
    _sessionStorage = web.window.sessionStorage;
  }

  @override
  void initialize() {
    // 1. Listen to 'beforeunload' for an immediate flush before browser context teardown.
    web.window.addEventListener('beforeunload', (web.Event event) {
      // In a synchronous storage library, all modifications are written
      // immediately to localStorage/sessionStorage. This hook is exposed
      // to ensure standard compliant lifecycle hook registration.
    }.toJS);

    // 2. Listen to 'storage' events for cross-tab reactive updates.
    web.window.addEventListener('storage', (web.StorageEvent event) {
      final storageArea = event.storageArea;
      StorageArea? area;
      
      // Determine which storage area triggered the event
      if (storageArea != null) {
        if (storageArea == _localStorage) {
          area = StorageArea.local;
        } else if (storageArea == _sessionStorage) {
          area = StorageArea.session;
        }
      }

      if (area != null) {
        _changeController.add(StorageEventData(
          area: area,
          key: event.key,
          newValue: event.newValue,
          oldValue: event.oldValue,
        ));
      }
    }.toJS);
  }

  @override
  String? getItem(StorageArea area, String key) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    return storage.getItem(key);
  }

  @override
  void setItem(StorageArea area, String key, String value) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    final oldValue = storage.getItem(key);
    storage.setItem(key, value);

    // Fire event locally because the window's storage listener only receives
    // events triggered by other windows/tabs.
    _changeController.add(StorageEventData(
      area: area,
      key: key,
      newValue: value,
      oldValue: oldValue,
    ));
  }

  @override
  void removeItem(StorageArea area, String key) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    final oldValue = storage.getItem(key);
    storage.removeItem(key);

    _changeController.add(StorageEventData(
      area: area,
      key: key,
      newValue: null,
      oldValue: oldValue,
    ));
  }

  @override
  void clear(StorageArea area) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    storage.clear();

    _changeController.add(StorageEventData(
      area: area,
      key: null,
      newValue: null,
      oldValue: null,
    ));
  }

  @override
  bool containsKey(StorageArea area, String key) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    return storage.getItem(key) != null;
  }

  @override
  Set<String> getKeys(StorageArea area) {
    final storage = area == StorageArea.local ? _localStorage : _sessionStorage;
    final keys = <String>{};
    final len = storage.length;
    for (int i = 0; i < len; i++) {
      final key = storage.key(i);
      if (key != null) {
        keys.add(key);
      }
    }
    return keys;
  }

  @override
  Stream<StorageEventData> get onStorageChanged => _changeController.stream;
}
