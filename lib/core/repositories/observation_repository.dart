import 'dart:async';
import 'dart:collection';

import 'package:latlong2/latlong.dart';

import '../enums/observation_type.dart';
import '../models/observation.dart';
import '../models/species.dart';

class ObservationRepository {
  ObservationRepository();

  final List<Observation> _observations = [];
  final StreamController<List<Observation>> _controller =
      StreamController<List<Observation>>.broadcast();

  Stream<List<Observation>> watchAll() => _controller.stream;

  List<Observation> getAll() => List.unmodifiable(_observations);

  Future<void> addObservation({
    required Species species,
    required ObservationType type,
    required DateTime timestamp,
    required LatLng position,
    String? address,
    String? notes,
  }) async {
    final id = _generateId(species.id, timestamp, type);
    final observation = Observation(
      id: id,
      species: species,
      type: type,
      timestamp: timestamp,
      position: position,
      address: address,
      notes: notes,
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
      final year = observation.timestamp.year;
      map.putIfAbsent(year, () => <Observation>[]).add(observation);
    }
    return SplayTreeMap.of(map, (a, b) => b.compareTo(a));
  }

  void dispose() {
    _controller.close();
  }

  void _notify() {
    _observations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _controller.add(List.unmodifiable(_observations));
  }

  String _generateId(
    String speciesId,
    DateTime timestamp,
    ObservationType type,
  ) {
    return '$speciesId-${type.storageKey}-${timestamp.millisecondsSinceEpoch}';
  }
}
