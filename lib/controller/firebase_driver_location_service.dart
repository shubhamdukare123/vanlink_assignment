import 'dart:async';
import 'dart:developer';
import 'package:location/location.dart' as loc;
import 'package:firebase_database/firebase_database.dart';
import 'package:vanlink_assignment/model/trip_details_model.dart';

class DriverLocationService {
  final loc.Location _location = loc.Location();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  Timer? _speedResetTimer;

  /// Start sending driver's location to Firebase
  Future<void> startSendingLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    final permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      final requestedPermission = await _location.requestPermission();
      if (requestedPermission != loc.PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription =
        _location.onLocationChanged.listen((loc.LocationData currentLocation) {
      if (TripDetails.tripStared) {
        final double speed = (currentLocation.speed ?? 0.0) * 3.6;
        log("Firebase Speed : $speed");

        _sendLocationToFirebase(
            currentLocation.latitude!, currentLocation.longitude!, speed);

      
        _speedResetTimer?.cancel();

      
        _speedResetTimer = Timer(Duration(seconds: 10), () {
        
          _sendLocationToFirebase(
            currentLocation.latitude!,
            currentLocation.longitude!,
            0.0,
          );
        });
      }
    });

    log("Started sending location");
  }

  
  void stopSendingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    log("Stopped sending location");
  }

  
  Future<void> _sendLocationToFirebase(
      double latitude, double longitude, double speed) async {
    try {
      await _databaseReference
          .child('driver_location')
          .set({'lat': latitude, 'lng': longitude, 'speed': (speed)});
      log('Location sent: $latitude, $longitude, $speed');
    } catch (e) {
      log('Error sending location: $e');
    }
  }


 

  
}
