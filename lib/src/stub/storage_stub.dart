import 'dart:async';
import '../interface/storage_platform_interface.dart';

/// Instantiates the fallback stub storage driver.
StoragePlatformInterface createPlatformInstance() => StorageStub();

/// A fallback implementation of [StoragePlatformInterface] that uses an in-memory
/// map. This is loaded on non-web platforms (iOS, Android, Desktop) to avoid crashes.
class StorageStub implements StoragePlatformInterface {
  final Map<String, String> _localMap = {};
  final Map<String, String> _sessionMap = {};
  final StreamController<StorageEventData> _changeController = StreamController<StorageEventData>.broadcast(sync: true);

  @override
  void initialize() {
    // No-op on non-web platforms.
  }

  Map<String, String> _getMap(StorageArea area) {
    return area == StorageArea.local ? _localMap : _sessionMap;
  }

  @override
  String? getItem(StorageArea area, String key) {
    return _getMap(area)[key];
  }

  @override
  void setItem(StorageArea area, String key, String value) {
    final map = _getMap(area);
    final oldValue = map[key];
    map[key] = value;
    _changeController.add(StorageEventData(
      area: area,
      key: key,
      newValue: value,
      oldValue: oldValue,
    ));
  }

  @override
  void removeItem(StorageArea area, String key) {
    final map = _getMap(area);
    final oldValue = map.remove(key);
    _changeController.add(StorageEventData(
      area: area,
      key: key,
      newValue: null,
      oldValue: oldValue,
    ));
  }

  @override
  void clear(StorageArea area) {
    _getMap(area).clear();
    _changeController.add(StorageEventData(
      area: area,
      key: null,
      newValue: null,
      oldValue: null,
    ));
  }

  @override
  bool containsKey(StorageArea area, String key) {
    return _getMap(area).containsKey(key);
  }

  @override
  Set<String> getKeys(StorageArea area) {
    return _getMap(area).keys.toSet();
  }

  @override
  Stream<StorageEventData> get onStorageChanged => _changeController.stream;
}
