import 'dart:async';
import 'dart:developer';
import 'package:location/location.dart' as loc;
import 'package:firebase_database/firebase_database.dart';
import 'package:vanlink_assignment/model/trip_details_model.dart';

class DriverLocationService {
  final loc.Location _location = loc.Location();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  StreamSubscription<loc.LocationData>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _locationListener;

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
        _sendLocationToFirebase(
            currentLocation.latitude!, currentLocation.longitude!);
      }
    });

    log("Started sending location");
  }

  /// Stop sending driver's location to Firebase
  void stopSendingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    log("Stopped sending location");
  }

  /// Internal: Push location to Firebase
  Future<void> _sendLocationToFirebase(
      double latitude, double longitude) async {
    try {
      await _databaseReference.child('driver_location').set({
        'lat': latitude,
        'lng': longitude,
      });
      log('Location sent: $latitude, $longitude');
    } catch (e) {
      log('Error sending location: $e');
    }
  }

  /// Listen to real-time updates from Firebase
  void fetchLiveLocation(Function(double lat, double lng) onUpdate) {
    _locationListener = _databaseReference
        .child('driver_location')
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey('lat') && data.containsKey('lng')) {
        final double lat = data['lat'] as double;
        final double lng = data['lng'] as double;
        onUpdate(lat, lng);
      }
    });
  }

  /// Stop listening to location updates from Firebase
  void stopListeningToLocation() {
    _locationListener?.cancel();
    _locationListener = null;
    print("Stopped listening to Firebase");
  }
}
