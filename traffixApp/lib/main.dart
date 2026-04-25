import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'storage_service.dart';
import 'settings_screen.dart';
import 'telemetry_service.dart';
import 'maps_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix for Android lockHardwareCanvas spam / crashes by enforcing Hybrid Composition
  if (Platform.isAndroid) {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
      try {
        await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (e) {
        debugPrint('Failed to initialize latest map renderer: $e');
      }
    }
  }

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
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _locationPermissionGranted = false;
  
  final MapsService _mapsService = MapsService();
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSuggestion> _suggestions = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartTracking();
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // If we have permission, update state to show blue dot
    setState(() {
      _locationPermissionGranted = true;
    });

    // Start listening to the position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      // Shift the camera to follow the user
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17.0,
          ),
        ),
      );
    });
  }

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
    // Cleanup timers and subscriptions on widget disposal
    _transmissionTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
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
            zoomControlsEnabled: false,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: _locationPermissionGranted,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search destination...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _markers.clear();
                          });
                        },
                      ) : null,
                    ),
                    onChanged: (value) async {
                      setState(() {}); // Trigger rebuild for suffixIcon
                      if (value.length > 2) {
                        final results = await _mapsService.getAutocompleteSuggestions(value);
                        if (mounted) {
                          setState(() {
                            _suggestions = results;
                          });
                        }
                      } else {
                        setState(() {
                          _suggestions = [];
                        });
                      }
                    },
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.grey),
                          title: Text(suggestion.description),
                          onTap: () async {
                            _searchController.text = suggestion.description;
                            FocusScope.of(context).unfocus(); // Close keyboard
                            setState(() {
                              _suggestions = [];
                            });

                            final coords = await _mapsService.getPlaceCoordinates(suggestion.placeId);
                            if (coords != null && mounted) {
                              setState(() {
                                _markers = {
                                  Marker(
                                    markerId: const MarkerId('destination'),
                                    position: LatLng(coords['lat']!, coords['lng']!),
                                    infoWindow: InfoWindow(title: suggestion.description),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                  ),
                                };
                              });

                              // Temporarily pan the camera to show the marker
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(coords['lat']!, coords['lng']!),
                                  15,
                                )
                              );
                              
                              _mapsService.endSession();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
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
          ),
        ],
      ),
    );
  }
}
