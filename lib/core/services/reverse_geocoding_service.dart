import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String?> lookupDescription(LatLng position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'zoom': '10',
      'addressdetails': '1',
    });

    final response = await _httpClient.get(
      uri,
      headers: {
        'User-Agent': 'TikliApp/1.0 (contact: support@tikli.app)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'];
    if (address is Map<String, dynamic>) {
      final fields = [
        'city',
        'town',
        'municipality',
        'village',
        'locality',
        'county',
        'state',
      ];
      for (final key in fields) {
        final value = address[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    final displayName = data['display_name'];
    if (displayName is String && displayName.isNotEmpty) {
      return displayName;
    }
    return null;
  }

  void dispose() {
    _httpClient.close();
  }
}
