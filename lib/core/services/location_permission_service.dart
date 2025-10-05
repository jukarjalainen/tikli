import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  Future<void> ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }
  }
}
