import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              // Controller will be used in step 4
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: _toggleGpsTransmission,
                  icon: Icon(
                    _isTransmitting ? Icons.stop : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    _isTransmitting ? 'Stop Transmit' : 'Start Transmit',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _isTransmitting ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
