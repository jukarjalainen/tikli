// A group of observations shown as a single marker on the observation map.

import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/observation.dart';

/// Observations close enough together at the current zoom to share one map
/// marker. Every observation in [observations] has a position.
class ObservationCluster extends Equatable {
  const ObservationCluster({required this.observations, required this.center});

  /// The observations in the group, never empty.
  final List<Observation> observations;

  /// Where the marker goes: the average position of [observations].
  final LatLng center;

  /// How many observations the group holds, counting every observation.
  int get count => observations.length;

  /// The positions of [observations].
  List<LatLng> get positions => [
    for (final observation in observations) observation.position!,
  ];

  /// Whether every observation is at the same spot, so zooming in can never
  /// separate them.
  bool get sharesSinglePosition {
    final first = observations.first.position;
    return observations.every((observation) => observation.position == first);
  }

  @override
  List<Object?> get props => [observations, center];
}
