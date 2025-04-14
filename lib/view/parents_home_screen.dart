import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanlink_assignment/view/login_register/login_screen.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class ParentsHomeScreen extends StatefulWidget {
  const ParentsHomeScreen({super.key});

  @override
  State<ParentsHomeScreen> createState() => ParentsHomeScreenState();
}

class ParentsHomeScreenState extends State<ParentsHomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  static double zoom = 16;

  static double lng = 0.0;
  static double lat = 0.0;
  static double _speed = 0.0; // Speed in km/h

  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(lat, lng),
    zoom: zoom,
  );

  @override
  void initState() {
    super.initState();
    listenToDriverLocation();
    _loadCustomMarker(lat, lng);
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
                  const   Icon(Icons.logout, color: Colors.black),
                   const  SizedBox(width: 8),
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
      body: Stack(children: [
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
            duration: Duration(milliseconds: 500),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  Text(
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
      
    );
  }

  final databaseReference = FirebaseDatabase.instance
      .ref("driver_location"); 

  Timer? _speedResetTimer;

  void listenToDriverLocation() {
    databaseReference.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        lat = data['lat'];
        lng = data['lng'];

        _speed = (data['speed'] as num).toDouble();

        // Cancel any existing timer
        _speedResetTimer?.cancel();

  
        _speedResetTimer = Timer(Duration(seconds: 10), () {
          _speed = 0;
    
          setState(() {});
        });

        final LatLng newPosition = LatLng(lat, lng);
        _setMarker(newPosition);
        _moveCamera(lat, lng);
      }
    });
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return LoginScreen();
    }));
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
