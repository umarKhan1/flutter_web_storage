/// A complete, WASM-ready, multiplatform-safe Flutter package for unified
/// localStorage and sessionStorage access with reactive streams, route
/// preservation, and reload-safe UI controllers.
library flutter_web_storage;

export 'src/interface/storage_platform_interface.dart' show StorageArea, StorageEventData;
export 'src/core/flutter_web_storage_impl.dart' show FlutterWebStorage;
export 'src/routing/route_preserver.dart' show WebRoutePreserverNavigatorObserver, getRestoredRoute;
export 'src/widgets/reload_safe_controllers.dart' show ReloadSafeTextEditingController, ReloadSafeNotifier;
