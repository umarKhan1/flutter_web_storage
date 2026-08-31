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
      // Automatically preserves and restores route on browser refresh (F5)
      navigatorObservers: [WebRoutePreserverNavigatorObserver()],
      initialRoute: getRestoredRoute(defaultRoute: '/'),
      routes: {
        '/': (context) => const StorageDashboard(),
        '/subpage': (context) => const SubPageDemo(),
      },
      // Handles stale / unknown routes from sessionStorage gracefully
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

  // ==========================================
  // LEFT COLUMN: STANDARD STATE (NO PERSISTENCE)
  // ==========================================
  int _stdCounter = 0;
  bool _stdSwitch = false;
  final TextEditingController _stdTextController = TextEditingController();

  // ==========================================
  // RIGHT COLUMN: PERSISTED STATE (WITH WEB STORAGE)
  // ==========================================
  // Using our drop-in UI helpers:
  late final ReloadSafeNotifier<int> _persistedCounter;
  late final ReloadSafeNotifier<bool> _persistedSwitch;
  late final ReloadSafeTextEditingController _persistedTextController;

  @override
  void initState() {
    super.initState();
    // Persist counter in localStorage (survives tab closing)
    _persistedCounter = ReloadSafeNotifier<int>(
      key: 'gif_counter',
      defaultValue: 0,
      area: StorageArea.local,
    );

    // Persist switch in sessionStorage (survives F5 reload)
    _persistedSwitch = ReloadSafeNotifier<bool>(
      key: 'gif_switch',
      defaultValue: false,
      area: StorageArea.session,
    );

    // Persist text input in sessionStorage (survives F5 reload)
    _persistedTextController = ReloadSafeTextEditingController(
      key: 'gif_text_draft',
      defaultValue: '',
      area: StorageArea.session,
    );
  }

  @override
  void dispose() {
    _stdTextController.dispose();
    _persistedCounter.dispose();
    _persistedSwitch.dispose();
    _persistedTextController.dispose();
    super.dispose();
  }

  void _resetEverything() {
    setState(() {
      _stdCounter = 0;
      _stdSwitch = false;
      _stdTextController.clear();
    });
    _storage.clear(area: StorageArea.session);
    _storage.clear(area: StorageArea.local);
    _persistedCounter.value = 0;
    _persistedSwitch.value = false;
    _persistedTextController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Web Storage — Before/After Demo'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.indigo),
            label: const Text('Reset All', style: TextStyle(color: Colors.indigo)),
            onPressed: _resetEverything,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Instruction: Change values on both sides, then press F5 (Browser Reload). '
                        'Observe how standard variables reset to default, while web-storage variables recover instantly.',
                        style: TextStyle(fontSize: 14, color: Colors.indigo, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Side-by-side layout
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStandardCard()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildPersistedCard()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildStandardCard(),
                          const SizedBox(height: 24),
                          _buildPersistedCard(),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Subpage Test
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.alt_route, color: Colors.white),
                    ),
                    title: const Text('Test Route Preservation (Navigator)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Go to subpage and hit reload. You will remain on `/subpage`.'),
                    trailing: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/subpage'),
                      child: const Text('Go to /subpage'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Left side: Standard Flutter States
  Widget _buildStandardCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade600),
                const SizedBox(width: 10),
                const Text('Without Web Storage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const Text('(Values reset on browser reload)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 30),

            // 1. Text Field
            const Text('Text Input Draft', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _stdTextController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type text here...',
              ),
            ),
            const SizedBox(height: 20),

            // 2. Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Counter Value', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Count: $_stdCounter', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.red.shade400),
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _stdCounter++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Toggle Switch', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _stdSwitch,
              onChanged: (val) {
                setState(() {
                  _stdSwitch = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Right side: Web Storage Persisted States
  Widget _buildPersistedCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade300, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 10),
                const Text('With flutter_web_storage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Text('(Values survive browser reload)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 30),

            // 1. Persisted Text Field
            const Text('Text Input Draft (session)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _persistedTextController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type text here...',
              ),
            ),
            const SizedBox(height: 20),

            // 2. Persisted Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Counter Value (local)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ValueListenableBuilder<int>(
                      valueListenable: _persistedCounter,
                      builder: (context, value, _) {
                        return Text('Count: $value', style: const TextStyle(fontSize: 16));
                      },
                    ),
                  ],
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.green.shade500),
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _persistedCounter.value++;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Persisted Switch
            ValueListenableBuilder<bool>(
              valueListenable: _persistedSwitch,
              builder: (context, active, _) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Toggle Switch (session)', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: active,
                  onChanged: (val) {
                    _persistedSwitch.value = val;
                  },
                );
              },
            ),
          ],
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
      appBar: AppBar(title: const Text('Subpage Route (/subpage)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 70, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Press F5 / Reload Browser Right Now!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will stay on /subpage because the package preserved the route in sessionStorage.',
              style: TextStyle(color: Colors.grey),
            ),
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
