import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/species.dart';

class SpeciesRepository {
  SpeciesRepository({this.assetPath = 'assets/data/species.json'});

  final String assetPath;
  List<Species>? _cachedSpecies;
  Future<List<Species>>? _inFlight;

  Future<List<Species>> loadSpecies() async {
    if (_cachedSpecies != null) {
      return _cachedSpecies!;
    }
    _inFlight ??= _readSpecies();
    _cachedSpecies = await _inFlight!;
    _inFlight = null;
    return _cachedSpecies!;
  }

  Stream<List<Species>> streamSpecies() {
    return Stream.fromFuture(loadSpecies());
  }

  Future<List<Species>> _readSpecies() async {
    final raw = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Species asset must decode to a List');
    }
    return decoded
        .map<Species>((dynamic item) {
          if (item is Map<String, dynamic>) {
            return _speciesFromMap(item);
          }
          if (item is Map) {
            return _speciesFromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          throw const FormatException('Species entries must be map objects');
        })
        .toList(growable: false);
  }

  Species _speciesFromMap(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final commonName =
        json['species']?.toString() ?? json['commonName']?.toString();
    if (id == null || id.isEmpty || commonName == null || commonName.isEmpty) {
      throw const FormatException('Species entry missing id or name');
    }
    return Species(id: id, commonName: commonName);
  }
}
