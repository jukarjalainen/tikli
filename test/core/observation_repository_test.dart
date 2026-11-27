import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/core/repositories/species_repository.dart';
import 'package:tikli/core/services/database_service.dart';

const _listed = Species(id: '121', commonName: 'Metsäkirvinen');

class _FakeSpeciesRepository extends Fake implements SpeciesRepository {
  _FakeSpeciesRepository(this.ready);

  /// Holds back loading until it completes, if given.
  final Future<void>? ready;

  @override
  Future<List<Species>> loadSpecies() async {
    await ready;
    return const [_listed];
  }
}

/// Serves the stored rows. [Fake] throws on every other call, so a test also
/// fails if loading writes to or deletes from the database.
class _FakeDatabaseService extends Fake implements DatabaseService {
  _FakeDatabaseService(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> getAllObservations() async => rows;
}

Map<String, dynamic> _row(String speciesId, {int day = 1}) {
  return {
    'id': '$speciesId-yearly-$day',
    'speciesId': speciesId,
    'type': 'yearly',
    'timestamp': DateTime(2026, 5, day).toIso8601String(),
    'latitude': null,
    'longitude': null,
    'municipality': 'Oulu',
    'customListId': null,
  };
}

ObservationRepository _createRepository(
  List<Map<String, dynamic>> rows, {
  Future<void>? speciesReady,
}) {
  final repository = ObservationRepository(
    speciesRepository: _FakeSpeciesRepository(speciesReady),
    databaseService: _FakeDatabaseService(rows),
  );
  addTearDown(repository.dispose);
  return repository;
}

/// Loading starts in the constructor. The fakes complete without real I/O, so
/// it has finished by the next turn of the event loop.
Future<void> _finishLoading() => Future<void>.delayed(Duration.zero);

Future<Map<String, String>> _loadNamesBySpeciesId(
  List<Map<String, dynamic>> rows,
) async {
  final repository = _createRepository(rows);
  await _finishLoading();
  return {
    for (final Observation observation in repository.getAll())
      observation.species.id: observation.species.commonName,
  };
}

void main() {
  group('ObservationRepository loading', () {
    test('keeps the rest of the history when a species is unknown', () async {
      final names = await _loadNamesBySpeciesId([_row('121'), _row('999')]);

      expect(names, {'121': 'Metsäkirvinen', '999': 'Tuntematon laji (999)'});
    });

    test('names rare species from their id', () async {
      final names = await _loadNamesBySpeciesId([
        _row('rare_pikku-uikku'),
        _row('rare_jokin_harvinainen_laji'),
      ]);

      expect(names, {
        'rare_pikku-uikku': 'pikku-uikku',
        'rare_jokin_harvinainen_laji': 'jokin harvinainen laji',
      });
    });

    test('keeps the names of species removed from the species list', () async {
      final names = await _loadNamesBySpeciesId([
        _row('120'),
        _row('123'),
        _row('240'),
      ]);

      expect(names, {
        '120': 'Metsähanhi',
        '123': 'Mustahaikara',
        '240': 'Tundraurpiainen',
      });
    });

    test('leaves the stored values of every observation unchanged', () async {
      final rows = [_row('121'), _row('120'), _row('rare_alli'), _row('999')];
      final repository = _createRepository(rows);
      await _finishLoading();

      expect(
        repository.getAll().map((observation) => observation.toMap()),
        unorderedEquals(rows),
      );
    });

    test('emits a copy of the history, newest first', () async {
      final listening = Completer<void>();
      final repository = _createRepository([
        _row('121', day: 1),
        _row('121', day: 3),
        _row('121', day: 2),
      ], speciesReady: listening.future);
      final emissions = <List<Observation>>[];
      final subscription = repository.watchAll().listen(emissions.add);
      addTearDown(subscription.cancel);
      // Let the listener receive the empty history before loading goes on.
      await Future<void>.delayed(Duration.zero);
      listening.complete();
      await _finishLoading();

      expect(emissions.last.map((observation) => observation.timestamp!.day), [
        3,
        2,
        1,
      ]);
      emissions.last.clear();
      expect(repository.getAll(), hasLength(3));
    });
  });
}
