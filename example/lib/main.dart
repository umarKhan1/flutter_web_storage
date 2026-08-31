import 'package:flutter/material.dart';
import 'package:flutter_web_storage/flutter_web_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StorageExampleApp());
}

class StorageExampleApp extends StatelessWidget {
  const StorageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'flutter_web_storage Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      navigatorObservers: [WebRoutePreserverNavigatorObserver()],
      initialRoute: getRestoredRoute(defaultRoute: '/'),
      routes: {
        '/': (context) => const StorageDashboard(),
        '/subpage': (context) => const SubPageDemo(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const StorageDashboard(),
        );
      },
    );
  }
}

class StorageDashboard extends StatefulWidget {
  const StorageDashboard({super.key});

  @override
  State<StorageDashboard> createState() => _StorageDashboardState();
}

class _StorageDashboardState extends State<StorageDashboard> {
  final FlutterWebStorage _storage = FlutterWebStorage.instance;
  late final ReloadSafeTextEditingController _textController;
  late final ReloadSafeNotifier<int> _counter;

  @override
  void initState() {
    super.initState();
    _textController = ReloadSafeTextEditingController(
      key: 'gif_text_draft',
      defaultValue: '',
      area: StorageArea.session,
    );
    _counter = ReloadSafeNotifier<int>(
      key: 'gif_counter',
      defaultValue: 0,
      area: StorageArea.local,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Storage Demo'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.indigo),
            onPressed: () {
              _storage.clear(area: StorageArea.session);
              _storage.clear(area: StorageArea.local);
              _textController.clear();
              _counter.value = 0;
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Persisted Text Input (sessionStorage)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Type something...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Persisted Counter (localStorage)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              ValueListenableBuilder<int>(
                                valueListenable: _counter,
                                builder: (context, val, _) => Text('Count: $val',
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () => _counter.value++,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/subpage'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Go to /subpage (Test Route Reload)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubPageDemo extends StatelessWidget {
  const SubPageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subpage (/subpage)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 70, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Press F5 / Reload Browser!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('The route observer keeps you on /subpage.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
