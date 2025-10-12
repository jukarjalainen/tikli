import 'dart:convert';
import 'package:flutter/services.dart';

class AllBirdsService {
  static List<String>? _cachedBirds;

  /// Load all Finnish birds from JSON asset file
  static Future<List<String>> loadAllBirds() async {
    if (_cachedBirds != null) {
      return _cachedBirds!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/all_finnish_birds.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedBirds = jsonList.cast<String>();
      return _cachedBirds!;
    } catch (e) {
      throw Exception('Failed to load all Finnish birds: $e');
    }
  }

  /// Filter birds based on search query
  static List<String> filterBirds(List<String> allBirds, String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    return allBirds
        .where((bird) => bird.toLowerCase().contains(lowerQuery))
        .take(10) // Limit to 10 suggestions
        .toList();
  }
}
