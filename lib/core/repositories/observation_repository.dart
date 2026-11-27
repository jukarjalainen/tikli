// Repository class managing bird observation data.
// Acts as the single source of truth by coordinating data between local memory and the SQLite DatabaseService.

import 'dart:async';
import 'dart:collection';

import 'package:latlong2/latlong.dart';

import '../enums/observation_type.dart';
import '../models/observation.dart';
import '../models/species.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/database_service.dart';
import '../repositories/species_repository.dart';

class ObservationRepository {
  ObservationRepository({
    required this.speciesRepository,
    ReverseGeocodingService? geocodingService,
    DatabaseService? databaseService,
  }) : _reverseGeocodingService = geocodingService ?? ReverseGeocodingService(),
       _ownsGeocodingService = geocodingService == null,
       _dbService = databaseService ?? DatabaseService() {
    _initDatabase();
  }
  final SpeciesRepository speciesRepository;
  final DatabaseService _dbService;

  final List<Observation> _observations = [];
  final StreamController<List<Observation>> _controller =
      StreamController<List<Observation>>.broadcast();
  final ReverseGeocodingService _reverseGeocodingService;
  final bool _ownsGeocodingService;
  final Map<String, String?> _reverseGeocodeCache = {};

  Stream<List<Observation>> watchAll() async* {
    yield [..._observations];
    yield* _controller.stream;
  }

  List<Observation> getAll() => [..._observations];

  Future<void> addObservation({
    required Species species,
    required ObservationType type,
    DateTime? timestamp,
    LatLng? position,
    String? municipality,
  }) async {
    final locationDescription =
        position != null
            ? await _resolvemunicipality(
              position: position,
              providedmunicipality: municipality,
            )
            : municipality;
    final id = _generateId(species.id, timestamp ?? DateTime.now(), type);
    final observation = Observation(
      id: id,
      species: species,
      type: type,
      timestamp: timestamp ?? DateTime.now(),
      position: position,
      municipality: locationDescription,
    );

    _observations.add(observation);
    _notify();

    // Save the observation to the database
    await _dbService.insertObservation(observation.toMap());
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

  Future<String?> _resolvemunicipality({
    required LatLng position,
    required String? providedmunicipality,
  }) async {
    if (providedmunicipality != null &&
        providedmunicipality.trim().isNotEmpty) {
      return providedmunicipality;
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
    await _dbService.deleteObservation(id);
    _observations.removeWhere((observation) => observation.id == id);
    if (_observations.length != initialLength) {
      _notify();
    }
  }

  void _notify() {
    _observations.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });
    _controller.add([..._observations]);
  }

  String _generateId(
    String speciesId,
    DateTime timestamp,
    ObservationType type,
  ) {
    return '$speciesId-${type.storageKey}-${timestamp.millisecondsSinceEpoch}';
  }

  // Initialize the database and load observations
  Future<void> _initDatabase() async {
    final speciesList = await speciesRepository.loadSpecies();
    final speciesMap = {for (var species in speciesList) species.id: species};

    final dbObservations = await _dbService.getAllObservations();
    _observations.addAll(
      dbObservations.map((obs) {
        final speciesId = obs['speciesId'] as String;
        final species = speciesMap[speciesId] ?? Species.unlisted(speciesId);
        return Observation.fromMap(obs, species);
      }),
    );
    _notify();
  }
}
