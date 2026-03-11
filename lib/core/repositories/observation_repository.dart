import 'dart:async';
import 'dart:collection';

import 'package:latlong2/latlong.dart';

import '../enums/observation_type.dart';
import '../models/observation.dart';
import '../models/species.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class ObservationRepository {
  ObservationRepository({ReverseGeocodingService? geocodingService})
    : _reverseGeocodingService = geocodingService ?? ReverseGeocodingService(),
      _ownsGeocodingService = geocodingService == null {
    _initDatabase();
  }

  final DatabaseService _dbService = DatabaseService();

  final List<Observation> _observations = [];
  final StreamController<List<Observation>> _controller =
      StreamController<List<Observation>>.broadcast();
  final ReverseGeocodingService _reverseGeocodingService;
  final bool _ownsGeocodingService;
  final Map<String, String?> _reverseGeocodeCache = {};

  Stream<List<Observation>> watchAll() => _controller.stream;

  List<Observation> getAll() => List.unmodifiable(_observations);

  Future<void> addObservation({
    required Species species,
    required ObservationType type,
    DateTime? timestamp,
    LatLng? position,
    String? address,
    String? notes,
  }) async {
    final locationDescription =
        position != null
            ? await _resolveAddress(
              position: position,
              providedAddress: address,
            )
            : address;
    final id = _generateId(species.id, timestamp ?? DateTime.now(), type);
    final observation = Observation(
      id: id,
      species: species,
      type: type,
      timestamp: timestamp,
      position: position,
      address: locationDescription,
      notes: notes,
    );
    // Tallenna tietokantaan
    final db = await _dbService.database;
    await db.insert(
      'observations', 
      observation.toMap(), // Vaatii Vaiheessa 2 tehdyn toMap() metodin
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _observations.add(observation);
    _notify();
  }

  Map<int, List<Observation>> yearlyObservations({ObservationType? type}) {
    final observations =
        type == null
            ? _observations
            : _observations.where((obs) => obs.type == type);
    final map = <int, List<Observation>>{};
    for (final observation in observations) {
      if (observation.timestamp == null) continue;
      final year = observation.timestamp!.year;
      map.putIfAbsent(year, () => <Observation>[]).add(observation);
    }
    return SplayTreeMap.of(map, (a, b) => b.compareTo(a));
  }

  void dispose() {
    _controller.close();
    if (_ownsGeocodingService) {
      _reverseGeocodingService.dispose();
    }
  }

  Future<String?> _resolveAddress({
    required LatLng position,
    required String? providedAddress,
  }) async {
    if (providedAddress != null && providedAddress.trim().isNotEmpty) {
      return providedAddress;
    }

    final cacheKey = _cacheKey(position);
    if (_reverseGeocodeCache.containsKey(cacheKey)) {
      return _reverseGeocodeCache[cacheKey];
    }

    try {
      final description = await _reverseGeocodingService.lookupDescription(
        position,
      );
      _reverseGeocodeCache[cacheKey] = description;
      return description;
    } catch (_) {
      _reverseGeocodeCache[cacheKey] = null;
      return null;
    }
  }

  String _cacheKey(LatLng position) {
    return '${position.latitude.toStringAsFixed(5)}:${position.longitude.toStringAsFixed(5)}';
  }

  Future<void> deleteObservation(String id) async {
    final initialLength = _observations.length;
    final db = await _dbService.database;
    await db.delete(
      'observations',
      where: 'id = ?',
      whereArgs: [id],
    );
    _observations.removeWhere((observation) => observation.id == id);
    if (_observations.length != initialLength) {
      _notify();
    }
  }

  void _notify() {
    _observations.sort((a, b) {
      final aTime = a.timestamp ?? DateTime(1970);
      final bTime = b.timestamp ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    _controller.add(List.unmodifiable(_observations));
  }

  String _generateId(
    String speciesId,
    DateTime timestamp,
    ObservationType type,
  ) {
    return '$speciesId-${type.storageKey}-${timestamp.millisecondsSinceEpoch}';
  }

  Future<void> _initDatabase() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('observations');

    // Tyhjennetään nykyinen lista varmuuden vuoksi
    _observations.clear();

    for (var map in maps) {
      // Tässä sinun täytyy hakea oikea Species-objekti map['speciesId']:n avulla.
      // Oletetaan, että sinulla on tapa hakea se (esim. SpeciesRepository tai lista kaikista lajeista).
      // Alla on yksinkertaistettu runko:
      
      /*
      final species = _haeLajiIdlla(map['speciesId']); 
      final type = ObservationType.values.firstWhere((e) => e.storageKey == map['type']);
      
      final observation = Observation(
        id: map['id'],
        species: species,
        type: type,
        timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
        position: map['latitude'] != null ? LatLng(map['latitude'], map['longitude']) : null,
        address: map['address'],
        notes: map['notes'],
      );
      _observations.add(observation);
      */
    }
    _notify(); // Päivittää UI:n, kun havainnot on ladattu!
  }

  
}
