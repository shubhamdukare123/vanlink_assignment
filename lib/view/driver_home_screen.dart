import 'dart:developer';

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:vanlink_assignment/controller/firebase_driver_location_service.dart';
import 'package:vanlink_assignment/model/trip_details_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanlink_assignment/view/login_register/login_screen.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  LatLng? _previousPosition;
  static double zoom = 16;
  static double tilt = 45;

  static LocationData? currentLocation;
  double _speed = 0.0; // Speed in km/h

  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
    zoom: zoom,
    tilt: tilt,
  );

  @override
  void initState() {
    _loadCustomMarker(18.52, 73.84);
    getCurrentLocation();

    super.initState();
  }

  final databaseReference = FirebaseDatabase.instance
      .ref("driver_location"); // Adjust path accordingly

  void listenToDriverLocation() {
    databaseReference.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        final double lat = data['latitude'];
        final double lng = data['longitude'];

        final LatLng newPosition = LatLng(lat, lng);
        _setMarker(newPosition);
        _moveCamera(lat, lng);
      }
    });
  }

  Future<void> _loadCustomMarker(double latitude, double longitude) async {
    final Marker customMarker = Marker(
      icon: await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(100, 70)),
        'assets/school_bus_icon.png', 
      ),
      
      markerId: const MarkerId("Marker 1"),
      position: LatLng(latitude, longitude),
      infoWindow: const InfoWindow(
          title: 'Google Plex', snippet: "Your child's location"),
    );

    setState(() {
      _markers.add(customMarker);
    });
  }

//get current location

  Future<Uint8List> getMarkerIcon(String image, int size) async {
    ByteData data = await rootBundle.load(image);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: size,
    );
    ui.FrameInfo info = await codec.getNextFrame();
    return (await info.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return LoginScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vanlink",
          style:
              GoogleFonts.openSans(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
        
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, size: 20, color: Colors.black),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              GoogleMap(
                zoomControlsEnabled: false,
                markers: _markers,
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              Positioned(
                bottom: 30,
                left: 40,
                child: AnimatedRadialGauge(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.bounceIn,
                  radius: 70,
                  value: _speed.clamp(0, 120), // Clamp to 0-120 for speed
                  axis: GaugeAxis(
                    min: 0,
                    max: 120,
                    degrees: 180,
                    style: GaugeAxisStyle(
                      thickness: 20,
                      background: Colors.grey.shade700,
                      segmentSpacing: 6,
                      blendColors: true,
                    ),
                    segments: const  [
                      GaugeSegment(
                        from: 0,
                        to: 120,
                        gradient: GaugeAxisGradient(
                          colors: [Colors.green, Colors.orange, Colors.red],
                          colorStops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ],
                    pointer: null,
                  ),

                  builder: (context, child, value) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${value.toStringAsFixed(0)} ",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                       const  Text(
                          "km/h",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
        onPressed: () async {
          DriverLocationService locationService = DriverLocationService();

          if (TripDetails.tripStared) {
            TripDetails.tripStared = false;
            locationService.stopSendingLocation();
          } else {
            TripDetails.tripStared = true;

            LocationData? currentPosition = await getCurrentLocation();
            locationService.startSendingLocation();

            if (currentPosition != null &&
                currentPosition.latitude != null &&
                currentPosition.longitude != null) {
              _goCurrentPosition(
                currentPosition.latitude!,
                currentPosition.longitude!,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to fetch current location")),
              );
            }
          }

          setState(() {});
        },
        label: Row(
          children: [
           const  Icon(Icons.pin_drop),
            const SizedBox(
              width: 5,
            ),
            Text(
              ((!TripDetails.tripStared)
                  ? "Start Your Trip"
                  : "Stop Your Trip"),
              style: const  TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _goCurrentPosition(
    double startLat,
    double startLng,
  ) async {
    log("IN go to currrent position");
    log("Animating camera to: $startLat, $startLng"); // <- Add this

    final GoogleMapController controller = await _controller.future;
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(startLat, startLng),
      zoom: zoom,
      tilt: tilt, 
      bearing: 30, 
    )));
  }

  Timer? _speedResetTimer;

  Future<LocationData?> getCurrentLocation() async {
    loc.Location location = loc.Location();
    // Check if service is enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    // Check for permission
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        log("Location permission not granted");
        return null;
      }
    }

    // Get the location
    try {
      await location.getLocation().then((location) {
        currentLocation = location;
        _speed = (currentLocation!.speed ?? 0.0) * 3.6; // m/s to km/h
      });

      log("Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}");

      location.onLocationChanged.listen((newLocation) {
        final LatLng newPosition =
            LatLng(newLocation.latitude!, newLocation.longitude!);

        _speed = (newLocation.speed ?? 0.0) * 3.6; // m/s to km/h

        log("Speed: $_speed");

        // Cancel any existing timer
        _speedResetTimer?.cancel();

        // Restart a timer to reset speed after delay
        _speedResetTimer = Timer(Duration(seconds: 10), () {


          setState(() {
            log("IN SET state : changeLoc");
            _speed = 0;
          });
        });

        if (_previousPosition == null) {
          _previousPosition = newPosition;
          _setMarker(newPosition);
          _moveCamera(newPosition.latitude, newPosition.longitude);
        } else {
          _animateMarker(_previousPosition!, newPosition);
          _moveCamera(newPosition.latitude, newPosition.longitude);
          _previousPosition = newPosition;
        }

        currentLocation = newLocation;
      });

     
      return currentLocation;
    } catch (e) {
      log("Error getting location: $e");
      return null;
    }
  }

  Future<void> _animateMarker(LatLng from, LatLng to) async {
    const int steps = 30;
    const Duration stepDuration = Duration(milliseconds: 16); // ~60fps
    final double latDiff = to.latitude - from.latitude;
    final double lngDiff = to.longitude - from.longitude;

    for (int i = 1; i <= steps; i++) {
      final double lat = from.latitude + (latDiff * i / steps);
      final double lng = from.longitude + (lngDiff * i / steps);
      final LatLng intermediatePosition = LatLng(lat, lng);

      _setMarker(intermediatePosition);

      await Future.delayed(stepDuration);
    }
  }

  void _setMarker(LatLng position) async {
    final Uint8List markerIcon =
        await getMarkerIcon("assets/school_bus_icon.png", 200);

    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId("currentLocation"),
        position: position,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        infoWindow: InfoWindow(title: "Current Location"),
      ));
    });
  }

  Future<void> _moveCamera(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(lat, lng),
      ),
    );
  }
}
