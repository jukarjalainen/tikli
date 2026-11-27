import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/models/custom_list.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/core/repositories/custom_list_repository.dart';
import 'package:tikli/core/services/database_service.dart';

const talitiainen = Species(id: 'talitiainen', commonName: 'Talitiainen');
const tikli = Species(id: 'tikli', commonName: 'Tikli');

Observation testObservation(
  String id,
  DateTime timestamp, {
  Species species = talitiainen,
  ObservationType type = ObservationType.yearly,
  String? municipality,
  String? customListId,
}) {
  return Observation(
    id: id,
    species: species,
    type: type,
    timestamp: timestamp,
    municipality: municipality,
    customListId:
        customListId ?? (type == ObservationType.custom ? pihapinna.id : null),
  );
}

/// An in-memory repository whose observations the test controls.
class FakeObservationRepository extends Fake implements ObservationRepository {
  FakeObservationRepository([List<Observation> observations = const []])
    : _observations = [...observations];

  List<Observation> _observations;
  final _controller = StreamController<List<Observation>>.broadcast();
  var _nextId = 0;

  @override
  List<Observation> getAll() => [..._observations];

  @override
  Stream<List<Observation>> watchAll() => _controller.stream;

  /// Replaces the observations and notifies listeners.
  void replaceAll(List<Observation> observations) {
    _observations = [...observations];
    _controller.add(getAll());
  }

  @override
  Future<void> addObservation({
    required Species species,
    required ObservationType type,
    DateTime? timestamp,
    LatLng? position,
    String? municipality,
    String? customListId,
  }) async {
    replaceAll([
      ..._observations,
      Observation(
        id: 'added-${_nextId++}',
        species: species,
        type: type,
        timestamp: timestamp,
        position: position,
        municipality: municipality,
        customListId: customListId,
      ),
    ]);
  }

  @override
  Future<void> deleteObservation(String id) async {
    replaceAll(_observations.where((obs) => obs.id != id).toList());
  }

  @override
  void dispose() {
    _controller.close();
  }
}

/// An in-memory stand-in for the SQLite database. Without arguments it is
/// like a fresh install: no custom lists and none preselected.
class FakeDatabaseService extends Fake implements DatabaseService {
  FakeDatabaseService({
    List<CustomList> customLists = const [],
    String? activeCustomListId,
  }) : _customLists = [for (final list in customLists) list.toMap()],
       _settings = {
         if (activeCustomListId != null)
           DatabaseService.activeCustomListIdKey: activeCustomListId,
       };

  final List<Map<String, dynamic>> _customLists;
  final Map<String, String> _settings;

  @override
  Future<List<Map<String, dynamic>>> getCustomLists() async => [
    ..._customLists,
  ];

  @override
  Future<void> insertCustomList(Map<String, dynamic> customListMap) async {
    _customLists.add(customListMap);
  }

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }
}

/// A [CustomListRepository] on a [FakeDatabaseService]. It loads in a microtask,
/// so let the test settle before reading [CustomListRepository.current].
CustomListRepository fakeCustomListRepository({
  List<CustomList> customLists = const [],
  String? activeCustomListId,
  FakeDatabaseService? databaseService,
}) {
  var tick = 0;
  return CustomListRepository(
    databaseService:
        databaseService ??
        FakeDatabaseService(
          customLists: customLists,
          activeCustomListId: activeCustomListId,
        ),
    // Distinct, increasing times, so created lists get distinct ids.
    clock: () => DateTime(2030).add(Duration(seconds: tick++)),
  );
}

/// Custom lists for tests.
final pihapinna = CustomList(
  id: 'pihapinna',
  name: 'Pihapinna',
  createdAt: DateTime(2020),
);
final mokki = CustomList(id: 'mokki', name: 'Mökki', createdAt: DateTime(2021));
