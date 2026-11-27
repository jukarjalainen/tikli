import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/features/observation_map/clustering/cluster_label.dart';
import 'package:tikli/features/observation_map/clustering/observation_cluster.dart';
import 'package:tikli/features/observation_map/clustering/observation_clusterer.dart';

const _helsinki = LatLng(60.17, 24.94);
// About 1 km north of _helsinki.
const _nearHelsinki = LatLng(60.179, 24.94);
const _oulu = LatLng(65.01, 25.47);

Observation _observation(
  String id,
  LatLng? position, {
  String species = 'Tikli',
}) {
  return Observation(
    id: id,
    species: Species(id: species.toLowerCase(), commonName: species),
    type: ObservationType.yearly,
    timestamp: DateTime(2026, 5, 1),
    position: position,
  );
}

/// Groups [observations] as the map does at [zoom].
List<ObservationCluster> _clusterAt(
  double zoom,
  List<Observation> observations,
) {
  const crs = Epsg3857();
  return clusterObservations(
    observations,
    project: (position) => crs.latLngToPoint(position, zoom),
  );
}

List<Set<String>> _idGroups(List<ObservationCluster> clusters) => [
  for (final cluster in clusters)
    {for (final observation in cluster.observations) observation.id},
];

void main() {
  group('clusterObservations', () {
    test('groups observations at the same spot at every zoom', () {
      final observations = [
        _observation('1', _helsinki),
        _observation('2', _helsinki, species: 'Talitiainen'),
      ];

      for (final zoom in [3.0, 10.0, 19.0]) {
        final clusters = _clusterAt(zoom, observations);
        expect(clusters, hasLength(1), reason: 'zoom $zoom');
        expect(clusters.single.sharesSinglePosition, isTrue);
      }
    });

    test('groups nearby observations when zoomed out and separates them '
        'when zoomed in', () {
      final observations = [
        _observation('1', _helsinki),
        _observation('2', _nearHelsinki),
      ];

      expect(_idGroups(_clusterAt(6, observations)), [
        {'1', '2'},
      ]);
      expect(_idGroups(_clusterAt(16, observations)), [
        {'1'},
        {'2'},
      ]);
    });

    test('keeps observations far apart separate', () {
      final clusters = _clusterAt(6, [
        _observation('1', _helsinki),
        _observation('2', _oulu),
      ]);

      expect(_idGroups(clusters), [
        {'1'},
        {'2'},
      ]);
    });

    test('counts every observation, also of the same species', () {
      final clusters = _clusterAt(6, [
        _observation('1', _helsinki),
        _observation('2', _helsinki),
        _observation('3', _nearHelsinki, species: 'Talitiainen'),
      ]);

      expect(clusters.single.count, 3);
    });

    test('gives the same groups whatever the order of the observations', () {
      final observations = [
        for (var i = 0; i < 20; i++)
          _observation('$i', LatLng(60 + i * 0.01, 24 + (i % 3) * 0.01)),
      ];
      final expected = _clusterAt(12, observations);

      final random = math.Random(1);
      for (var round = 0; round < 5; round++) {
        final shuffled = [...observations]..shuffle(random);
        expect(_clusterAt(12, shuffled), expected);
      }
    });

    test('leaves out observations without a position', () {
      final clusters = _clusterAt(6, [
        _observation('1', _helsinki),
        _observation('2', null),
      ]);

      expect(_idGroups(clusters), [
        {'1'},
      ]);
    });

    test('puts the marker at the average position of the group', () {
      final clusters = _clusterAt(6, [
        _observation('1', const LatLng(60, 24)),
        _observation('2', const LatLng(60.01, 24.02)),
      ]);

      expect(clusters.single.center.latitude, closeTo(60.005, 1e-9));
      expect(clusters.single.center.longitude, closeTo(24.01, 1e-9));
    });

    test('groups observations within the radius across grid cells', () {
      // Pixels are one per degree of longitude, so the grid cells of the
      // radius of 60 meet at longitude 60.
      math.Point<double> project(LatLng position) =>
          math.Point(position.longitude, 0);

      final across = clusterObservations([
        _observation('1', const LatLng(0, 59)),
        _observation('2', const LatLng(0, 61)),
      ], project: project);
      final apart = clusterObservations([
        _observation('1', const LatLng(0, 0)),
        _observation('2', const LatLng(0, 61)),
      ], project: project);

      expect(_idGroups(across), [
        {'1', '2'},
      ]);
      expect(_idGroups(apart), [
        {'1'},
        {'2'},
      ]);
    });
  });

  group('clusterLabelLines', () {
    ObservationCluster cluster(List<String> species) => ObservationCluster(
      observations: [
        for (var i = 0; i < species.length; i++)
          _observation('$i', _helsinki, species: species[i]),
      ],
      center: _helsinki,
    );

    test('lists the species names in alphabetical order', () {
      expect(clusterLabelLines(cluster(['Tikli', 'Peippo', 'Talitiainen'])), [
        'Peippo',
        'Talitiainen',
        'Tikli',
      ]);
    });

    test('lists the names of up to 10 observations', () {
      final names = [for (var i = 0; i < 10; i++) 'Laji $i'];

      expect(clusterLabelLines(cluster(names)), names);
    });

    test('shows only the count for more than 10 observations', () {
      final names = [for (var i = 0; i < 15; i++) 'Laji $i'];

      expect(clusterLabelLines(cluster(names)), ['15 havaintoa']);
    });
  });
}
