import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LatLng? _lastLocation;

  /// The location [getCurrentLocation] last found, if any. Available at
  /// once, while a fresh lookup can take seconds.
  LatLng? get lastLocation => _lastLocation;

  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      } on Exception {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return null;
      }

      final latitude = position.latitude;
      final longitude = position.longitude;
      if (!latitude.isFinite || !longitude.isFinite) {
        return null;
      }
      return _lastLocation = LatLng(latitude, longitude);
    } catch (_) {
      return null;
    }
  }
}
