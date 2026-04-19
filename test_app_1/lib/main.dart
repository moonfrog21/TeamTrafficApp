import 'package:flutter/material.dart';
import 'dart:async';
import 'storage_service.dart';
import 'settings_screen.dart';
import 'telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Telemetry App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTransmitting = false;
  Timer? _transmissionTimer;

  /// Handle the GPS data transmission toggle
  Future<void> _toggleGpsTransmission() async {
    setState(() {
      _isTransmitting = !_isTransmitting;
    });

    if (_isTransmitting) {
      // Start the periodic transmission
      _transmissionTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) async {
          try {
            final response = await TelemetryService.sendGpsData();

            if (mounted) {
              final snackBar = SnackBar(
                content: Text(response.message),
                backgroundColor: response.success ? Colors.green : Colors.red,
                duration: const Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          } catch (e) {
            if (mounted) {
              final snackBar = SnackBar(
                content: Text('Transmission error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        },
      );
    } else {
      // Stop the periodic transmission
      _transmissionTimer?.cancel();
      _transmissionTimer = null;
    }
  }

  /// Navigate to settings screen
  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  void dispose() {
    // Cleanup timer on widget disposal
    _transmissionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Telemetry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'GPS Telemetry Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toggle to start continuous GPS data transmission',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 280,
              child: ElevatedButton.icon(
                onPressed: _toggleGpsTransmission,
                icon: Icon(
                  _isTransmitting ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  _isTransmitting
                      ? 'Stop GPS Data Transmit'
                      : 'Start GPS Data Transmit',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      _isTransmitting ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Make sure you have configured your ngrok URL in Settings before sending data. Transmission occurs every 5 seconds.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
