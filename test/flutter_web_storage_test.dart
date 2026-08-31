import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_storage/flutter_web_storage.dart';

class TestUser {
  final String name;
  final int age;

  TestUser(this.name, this.age);

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        json['name'] as String,
        json['age'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser && runtimeType == other.runtimeType && name == other.name && age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

void main() {
  late FlutterWebStorage storage;

  setUp(() {
    storage = FlutterWebStorage.instance;
    storage.clear(area: StorageArea.session);
    storage.clear(area: StorageArea.local);
  });

  group('Primitives (Synchronous Get/Set)', () {
    test('String storage', () {
      expect(storage.getString('str'), isNull);
      storage.setString('str', 'hello');
      expect(storage.getString('str'), 'hello');

      storage.setString('str', 'world', area: StorageArea.local);
      expect(storage.getString('str'), 'hello'); // session
      expect(storage.getString('str', area: StorageArea.local), 'world');
    });

    test('Integer storage', () {
      expect(storage.getInt('num'), isNull);
      storage.setInt('num', 42);
      expect(storage.getInt('num'), 42);
    });

    test('Double storage', () {
      expect(storage.getDouble('db'), isNull);
      storage.setDouble('db', 3.14159);
      expect(storage.getDouble('db'), 3.14159);
    });

    test('Bool storage', () {
      expect(storage.getBool('flag'), isNull);
      storage.setBool('flag', true);
      expect(storage.getBool('flag'), isTrue);
      storage.setBool('flag', false);
      expect(storage.getBool('flag'), isFalse);
    });
  });

  group('Lists & Arrays', () {
    test('StringList storage', () {
      expect(storage.getStringList('list'), isNull);
      storage.setStringList('list', ['a', 'b', 'c']);
      expect(storage.getStringList('list'), ['a', 'b', 'c']);
    });

    test('ObjectList storage', () {
      final users = [TestUser('Alice', 25), TestUser('Bob', 30)];
      expect(storage.getObjectList<TestUser>('users', TestUser.fromJson), isNull);

      storage.setObjectList<TestUser>('users', users, (u) => u.toJson());
      final retrieved = storage.getObjectList<TestUser>('users', TestUser.fromJson);
      expect(retrieved, users);
    });
  });

  group('JSON & Custom Models', () {
    test('JSON Map storage', () {
      final jsonMap = {'name': 'Gemini', 'version': 1.5, 'active': true};
      expect(storage.getJson('meta'), isNull);

      storage.setJson('meta', jsonMap);
      expect(storage.getJson('meta'), jsonMap);
    });

    test('Single Object storage', () {
      final user = TestUser('Charlie', 28);
      expect(storage.getObject<TestUser>('user', TestUser.fromJson), isNull);

      storage.setObject<TestUser>('user', user, (u) => u.toJson());
      expect(storage.getObject<TestUser>('user', TestUser.fromJson), user);
    });
  });

  group('Utility Functions', () {
    test('containsKey, remove, clear, and getKeys', () {
      expect(storage.containsKey('key1'), isFalse);
      storage.setString('key1', 'v1');
      storage.setString('key2', 'v2');

      expect(storage.containsKey('key1'), isTrue);
      expect(storage.getKeys(), {'key1', 'key2'});

      storage.remove('key1');
      expect(storage.containsKey('key1'), isFalse);
      expect(storage.getKeys(), {'key2'});

      storage.clear();
      expect(storage.getKeys(), isEmpty);
    });
  });

  group('Reactive Streams', () {
    test('watchString emits values reactively', () async {
      final events = <String?>[];
      final subscription = storage.watchString('watch_str').listen((val) {
        events.add(val);
      });

      storage.setString('watch_str', 'v1');
      storage.setString('watch_str', 'v2');
      storage.remove('watch_str');

      // Allow microtasks to execute
      await Future.delayed(Duration.zero);

      expect(events, [isNull, 'v1', 'v2', isNull]);
      await subscription.cancel();
    });

    test('watchJson emits JSON maps reactively', () async {
      final events = <Map<String, dynamic>?>[];
      final subscription = storage.watchJson('watch_json').listen((val) {
        events.add(val);
      });

      storage.setJson('watch_json', {'step': 1});
      storage.setJson('watch_json', {'step': 2});

      await Future.delayed(Duration.zero);

      expect(events, [
        isNull,
        {'step': 1},
        {'step': 2},
      ]);
      await subscription.cancel();
    });

    test('watch<T> emits custom objects reactively', () async {
      final events = <TestUser?>[];
      final subscription = storage.watch<TestUser>(
        'watch_user',
        decoder: (json) => TestUser.fromJson(json as Map<String, dynamic>),
      ).listen((val) {
        events.add(val);
      });

      final user1 = TestUser('David', 31);
      final user2 = TestUser('Eva', 22);

      storage.setObject<TestUser>('watch_user', user1, (u) => u.toJson());
      storage.setObject<TestUser>('watch_user', user2, (u) => u.toJson());

      await Future.delayed(Duration.zero);

      expect(events, [
        isNull,
        user1,
        user2,
      ]);
      await subscription.cancel();
    });
  });

  group('Route Preservation', () {
    test('WebRoutePreserverNavigatorObserver stores routes', () {
      final observer = WebRoutePreserverNavigatorObserver();
      final route = MaterialPageRoute(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => Container(),
      );

      expect(getRestoredRoute(defaultRoute: '/fallback'), '/fallback');

      observer.didPush(route, null);
      expect(getRestoredRoute(defaultRoute: '/fallback'), '/home');
    });
  });

  group('UI Helpers / Controllers', () {
    testWidgets('ReloadSafeTextEditingController persists and rehydrates', (WidgetTester tester) async {
      storage.setString('input_key', 'prefilled');

      final controller = ReloadSafeTextEditingController(key: 'input_key');
      expect(controller.text, 'prefilled');

      controller.text = 'new_value';
      expect(storage.getString('input_key'), 'new_value');

      controller.dispose();
    });

    testWidgets('ReloadSafeNotifier persists and rehydrates', (WidgetTester tester) async {
      // Test primitives
      storage.setInt('counter', 10);
      final counterNotifier = ReloadSafeNotifier<int>(key: 'counter', defaultValue: 0);
      expect(counterNotifier.value, 10);

      counterNotifier.value = 15;
      expect(storage.getInt('counter'), 15);
      counterNotifier.dispose();

      // Test custom object
      final user = TestUser('Frank', 45);
      storage.setObject<TestUser>('user_key', user, (u) => u.toJson());

      final userNotifier = ReloadSafeNotifier<TestUser>(
        key: 'user_key',
        defaultValue: TestUser('Guest', 0),
        fromJson: TestUser.fromJson,
        toJson: (u) => u.toJson(),
      );

      expect(userNotifier.value, user);

      final newUser = TestUser('Grace', 50);
      userNotifier.value = newUser;
      expect(storage.getObject<TestUser>('user_key', TestUser.fromJson), newUser);
      userNotifier.dispose();
    });
  });
}
