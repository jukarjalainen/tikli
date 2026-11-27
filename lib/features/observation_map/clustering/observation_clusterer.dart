// Groups observations that would overlap on the map at the current zoom.

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/models/observation.dart';
import 'observation_cluster.dart';

/// How close, in screen pixels, two observations must be to share a marker.
const double defaultClusterRadius = 60;

/// Groups [observations] so that no two markers lie within [radius] pixels of
/// the first observation of a group.
///
/// [project] turns a position into pixels at the zoom being shown, for example
/// `(position) => camera.project(position)`. World pixels do not change when
/// the map is panned, so moving the map never regroups the observations; only
/// zooming does.
///
/// Observations without a position are left out. The result does not depend
/// on the order of [observations].
List<ObservationCluster> clusterObservations(
  Iterable<Observation> observations, {
  required math.Point<double> Function(LatLng position) project,
  double radius = defaultClusterRadius,
}) {
  assert(radius > 0, 'radius must be positive');
  final located = [
    for (final observation in observations)
      if (observation.position != null) observation,
  ]..sort(_byPosition);
  final points = [
    for (final observation in located) project(observation.position!),
  ];

  // Each observation goes in a grid cell the size of the radius, so every
  // observation within the radius of another lies in one of the 3 x 3 cells
  // around it.
  (int, int) cellOf(math.Point<double> point) => (
    (point.x / radius).floor(),
    (point.y / radius).floor(),
  );
  final cells = <(int, int), List<int>>{};
  for (var i = 0; i < points.length; i++) {
    cells.putIfAbsent(cellOf(points[i]), () => []).add(i);
  }

  final grouped = List.filled(located.length, false);
  final radiusSquared = radius * radius;
  final clusters = <ObservationCluster>[];
  for (var seed = 0; seed < located.length; seed++) {
    if (grouped[seed]) continue;
    grouped[seed] = true;
    final members = [seed];
    final (cellX, cellY) = cellOf(points[seed]);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final other in cells[(cellX + dx, cellY + dy)] ?? const <int>[]) {
          if (!grouped[other] &&
              points[seed].squaredDistanceTo(points[other]) <= radiusSquared) {
            grouped[other] = true;
            members.add(other);
          }
        }
      }
    }
    members.sort();
    final memberObservations = [for (final i in members) located[i]];
    clusters.add(
      ObservationCluster(
        observations: memberObservations,
        center: _averagePosition(memberObservations),
      ),
    );
  }
  return clusters;
}

int _byPosition(Observation a, Observation b) {
  final byLatitude = a.position!.latitude.compareTo(b.position!.latitude);
  if (byLatitude != 0) return byLatitude;
  final byLongitude = a.position!.longitude.compareTo(b.position!.longitude);
  if (byLongitude != 0) return byLongitude;
  return a.id.compareTo(b.id);
}

LatLng _averagePosition(List<Observation> observations) {
  var latitude = 0.0;
  var longitude = 0.0;
  for (final observation in observations) {
    latitude += observation.position!.latitude;
    longitude += observation.position!.longitude;
  }
  return LatLng(
    latitude / observations.length,
    longitude / observations.length,
  );
}
