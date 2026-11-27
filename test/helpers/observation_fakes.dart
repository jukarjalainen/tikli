import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/models/yard_list.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/core/repositories/yard_list_repository.dart';
import 'package:tikli/core/services/database_service.dart';

const talitiainen = Species(id: 'talitiainen', commonName: 'Talitiainen');
const tikli = Species(id: 'tikli', commonName: 'Tikli');

Observation testObservation(
  String id,
  DateTime timestamp, {
  Species species = talitiainen,
  ObservationType type = ObservationType.yearly,
  String? municipality,
  String? yardListId,
}) {
  return Observation(
    id: id,
    species: species,
    type: type,
    timestamp: timestamp,
    municipality: municipality,
    yardListId:
        yardListId ??
        (type == ObservationType.yard ? YardList.defaultId : null),
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
    String? yardListId,
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
        yardListId: yardListId,
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

/// An in-memory stand-in for the SQLite database, seeded like a fresh install
/// with the default yard list "Koti" preselected.
class FakeDatabaseService extends Fake implements DatabaseService {
  FakeDatabaseService({List<YardList>? yardLists, String? activeYardListId})
    : _yardLists = [
        for (final list
            in yardLists ??
                [
                  YardList(
                    id: YardList.defaultId,
                    name: YardList.defaultName,
                    createdAt: DateTime(2020),
                  ),
                ])
          list.toMap(),
      ],
      _settings = {
        DatabaseService.activeYardListIdKey:
            activeYardListId ?? YardList.defaultId,
      };

  final List<Map<String, dynamic>> _yardLists;
  final Map<String, String> _settings;

  @override
  Future<List<Map<String, dynamic>>> getYardLists() async => [..._yardLists];

  @override
  Future<void> insertYardList(Map<String, dynamic> yardListMap) async {
    _yardLists.add(yardListMap);
  }

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }
}

/// A [YardListRepository] on a [FakeDatabaseService]. It loads in a microtask,
/// so let the test settle before reading [YardListRepository.current].
YardListRepository fakeYardListRepository({
  List<YardList>? yardLists,
  String? activeYardListId,
  FakeDatabaseService? databaseService,
}) {
  var tick = 0;
  return YardListRepository(
    databaseService:
        databaseService ??
        FakeDatabaseService(
          yardLists: yardLists,
          activeYardListId: activeYardListId,
        ),
    // Distinct, increasing times, so created lists get distinct ids.
    clock: () => DateTime(2030).add(Duration(seconds: tick++)),
  );
}

/// A second yard list for tests, next to the default "Koti".
final mokki = YardList(id: 'mokki', name: 'Mökki', createdAt: DateTime(2021));

YardList get koti => YardList(
  id: YardList.defaultId,
  name: YardList.defaultName,
  createdAt: DateTime(2020),
);
