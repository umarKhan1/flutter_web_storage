import 'package:flutter/widgets.dart';
import '../interface/storage_platform_interface.dart';
import '../core/flutter_web_storage_impl.dart';

/// A standard [NavigatorObserver] that automatically persists the current route name
/// or URI into [StorageArea.session] storage.
///
/// Works out-of-the-box with GoRouter, Navigator 2.0, and traditional Navigator setups
/// by listening to didPush, didPop, and didReplace.
class WebRoutePreserverNavigatorObserver extends NavigatorObserver {
  /// The key used in sessionStorage to store the preserved route.
  static const String routeKey = '__preserved_route__';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _saveRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveRoute(newRoute);
    }
  }

  void _saveRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    // We only preserve named routes / deep links.
    if (routeName != null && routeName.isNotEmpty) {
      FlutterWebStorage.instance.setString(routeKey, routeName, area: StorageArea.session);
    }
  }
  /// Static helper to retrieve the saved route on app boot.
  static String? getRestoredRoute() {
    return FlutterWebStorage.instance.getString(routeKey, area: StorageArea.session);
  }
}

/// Retrieves the saved route from [StorageArea.session] on boot so F5 reload survives.
/// Falls back to [defaultRoute] (typically `/`) if no route is preserved.
String getRestoredRoute({String defaultRoute = '/'}) {
  final saved = FlutterWebStorage.instance.getString(
    WebRoutePreserverNavigatorObserver.routeKey,
    area: StorageArea.session,
  );
  return saved ?? defaultRoute;
}
