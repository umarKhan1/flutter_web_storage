# flutter_web_storage

A production-grade, **WASM-Ready**, and **Multiplatform-Safe** Flutter package for accessing `localStorage` and `sessionStorage` with **zero UI flicker**. Features reactive streams, deep link route preservation on browser refresh (F5), and drop-in reload-safe UI controllers.

[![pub package](https://img.shields.io/pub/v/flutter_web_storage.svg)](https://pub.dev/packages/flutter_web_storage)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![WASM-Ready](https://img.shields.io/badge/WASM-Ready-g.svg?color=10B981)](#)

---

## Why `flutter_web_storage`?

1. **WASM (WebAssembly) Ready**: Implemented strictly using modern `package:web` and `dart:js_interop`. Absolutely **zero** imports of the deprecated `dart:html` library, allowing compatibility with Flutter's WASM build targets.
2. **Zero UI Flicker**: State is hydrated synchronously from browser storage directly during widget initialization. No need to wrap your widgets in asynchronous `FutureBuilder` blocks or show loading spinners while waiting for values.
3. **Multiplatform Safe**: Employs conditional imports. If run on native platforms (Android, iOS, macOS, Windows, Linux), it gracefully falls back to a clean in-memory map implementation so your codebase never crashes.
4. **Cross-Tab Reactive Streams**: Emits live updates across browser tabs. Updates made in one window will reflect instantly in other tabs listening to the same storage keys.
5. **Route Preservation**: Retains the active route (including Navigator 2.0 / GoRouter state) in sessionStorage. If the user hits F5 (refresh) on a subpage, they stay on that subpage rather than resetting to `/`.

---

## GIF Showcase & Recording Guide (For pub.dev)

The package includes an interactive playground app under `example/`. Here is how you can record the perfect showcase GIFs for your project description:

### 🎥 GIF 1: Unfinished Input Caching (SessionStorage)
- **What it demonstrates**: `ReloadSafeTextEditingController` caching text characters mid-typing.
- **How to record**: 
  1. Go to Card 1 in the demo.
  2. Type some text (e.g., `"Checking F5 persistence..."`).
  3. Reload the browser (F5) mid-typing.
  4. Notice how the cursor and text recover instantly on restart without reset.

### 🎥 GIF 2: Primitives Persistence (LocalStorage)
- **What it demonstrates**: Synchronous reading/writing of standard types (`int` and `bool`).
- **How to record**:
  1. Go to Card 2.
  2. Click the `+` button multiple times to increase the counter.
  3. Toggle the "Boolean Flag State" switch to active.
  4. Hit refresh (F5).
  5. The values remain intact.

### 🎥 GIF 3: Cross-Tab Reactive Sync Stream
- **What it demonstrates**: Live streaming updates across window contexts using `watchString`.
- **How to record**:
  1. Open the example app in two separate browser windows side-by-side.
  2. In Window A, type into the text field in Card 1.
  3. Look at Card 5 ("Reactive Stream") in Window B.
  4. Notice the value updating in real-time in Window B as you type in Window A!

### 🎥 GIF 4: Deep Link / Route Preservation (F5 Test)
- **What it demonstrates**: Retaining route history across page reloads.
- **How to record**:
  1. Scroll to Card 6.
  2. Click "Go to /subpage".
  3. Once on the subpage, reload (F5) the browser.
  4. Notice the app boots directly back onto `/subpage` instead of jumping back to the home route.

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_web_storage: ^1.0.0
```

---

## Core Usage Guide

### 1. Initializing and Accessing Basic Primitives

All functions are accessed via the `FlutterWebStorage.instance` singleton. You can specify `StorageArea.local` (localStorage) or `StorageArea.session` (sessionStorage).

```dart
final storage = FlutterWebStorage.instance;

// String
storage.setString('username', 'Alex', area: StorageArea.local);
String? name = storage.getString('username', area: StorageArea.local);

// Integer
storage.setInt('session_counter', 42, area: StorageArea.session);
int? counter = storage.getInt('session_counter', area: StorageArea.session);

// Boolean
storage.setBool('theme_dark', true);
bool? isDark = storage.getBool('theme_dark');
```

### 2. Lists & Complex JSON Models

```dart
// Lists of strings
storage.setStringList('user_tags', ['Flutter', 'WASM']);
List<String>? tags = storage.getStringList('user_tags');

// Custom Objects / JSON Maps
final profile = {'username': 'Alex', 'role': 'Admin'};
storage.setJson('user_profile', profile);
Map<String, dynamic>? data = storage.getJson('user_profile');
```

### 3. Reactive Watch Streams

Listen to updates to any key reactively. This stream is fired both by local updates and by cross-tab storage events from other tabs.

```dart
StreamBuilder<String?>(
  stream: FlutterWebStorage.instance.watchString('user_draft_text'),
  builder: (context, snapshot) {
    return Text('Live value: ${snapshot.data ?? ""}');
  },
);
```

### 4. Route Preservation (GoRouter & Navigator)

To preserve the navigation state on browser reload, simply attach `WebRoutePreserverNavigatorObserver` to your navigator observers.

```dart
MaterialApp(
  navigatorObservers: [WebRoutePreserverNavigatorObserver()],
  initialRoute: getRestoredRoute(defaultRoute: '/'),
  routes: {
    '/': (context) => const HomeScreen(),
    '/settings': (context) => const SettingsScreen(),
  },
);
```

### 5. Drop-in UI Controllers

```dart
// 1. Text Controller: auto-saves user typing into sessionStorage
late final ReloadSafeTextEditingController _inputController;

@override
void initState() {
  super.initState();
  _inputController = ReloadSafeTextEditingController(
    key: 'profile_draft',
    defaultValue: 'John Doe',
  );
}

// 2. ValueNotifier: auto-persists states (supports custom objects too!)
late final ReloadSafeNotifier<int> _notifier;

@override
void initState() {
  super.initState();
  _notifier = ReloadSafeNotifier<int>(
    key: 'live_counter',
    defaultValue: 0,
    area: StorageArea.local,
  );
}
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
