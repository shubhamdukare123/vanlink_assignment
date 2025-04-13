import 'dart:developer';
import 'dart:typed_data';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart';

import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:vanlink_assignment/controller/firebase_driver_location_service.dart';
import 'package:vanlink_assignment/model/trip_details_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => MapSampleState();
}

class MapSampleState extends State<DriverHomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  LatLng? _previousPosition;

  LocationData? currentLocation;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(18.52, 73.84),
    zoom: 17,
    tilt: 59.440717697143555,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(18.52, 73.84),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  void initState() {
    _loadCustomMarker(18.52, 73.84);

    super.initState();

    // _loadCustomMarker(currentLocation!.latitude!, currentLocation!.latitude!);
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
    final Uint8List markerIcon =
        await getMarkerIcon("assets/school_bus_icon.png", 170);
    final Marker customMarker = Marker(
      icon: BitmapDescriptor.fromBytes(markerIcon),
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

  void _logout() {
    Navigator.of(context).pop();
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
        backgroundColor: Color.fromRGBO(255, 193, 7, 1),
        // centerTitle: true,
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
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 8),
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
      body: GoogleMap(
        markers: _markers,
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color.fromRGBO(255, 193, 7, 1),
        onPressed: () async {
          DriverLocationService _locationService = DriverLocationService();

          if (TripDetails.tripStared) {
            TripDetails.tripStared = false;
            _locationService.stopSendingLocation();
          } else {
            TripDetails.tripStared = true;

            LocationData? currentPosition = await getCurrentLocation();
            _locationService.startSendingLocation();

            if (currentPosition != null &&
                currentPosition.latitude != null &&
                currentPosition.longitude != null) {
              _goCurrentPosition(
                currentPosition.latitude!,
                currentPosition.longitude!,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to fetch current location")),
              );
            }
          }

          setState(() {});
        },
        label: Row(
          children: [
            Icon(Icons.pin_drop),
            const SizedBox(
              width: 5,
            ),
            Text(
              ((!TripDetails.tripStared)
                  ? "Start Your Trip"
                  : "Stop Your Trip"),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      zoom: 17,
      //      // Set the zoom level (you can adjust this for closer or farther view)
      tilt: 50, // Tilt to give a more dynamic perspective of the map
      bearing:
          30, // Set bearing to change the direction of the camera view (rotation)
    )));
  }

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
      });

      log("Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}");

      location.onLocationChanged.listen((newLocation) {
        final LatLng newPosition =
            LatLng(newLocation.latitude!, newLocation.longitude!);

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

      // _goCurrentPosition(newLocation.longitude!, newLocation.latitude!);
      // setState(() {});

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
