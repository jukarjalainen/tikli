// Map layer that groups observations which would overlap at the current zoom.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/models/observation.dart';
import '../clustering/observation_cluster.dart';
import '../clustering/observation_clusterer.dart';
import 'observation_cluster_marker.dart';
import 'observation_cluster_sheet.dart';

/// Shows [observations] on the enclosing [FlutterMap], one marker per group of
/// observations that are too close together to tell apart at the current
/// zoom. The groups change as the user zooms.
///
/// Tapping a group zooms in to separate it. A group that cannot be separated,
/// because its observations share one spot or the map is fully zoomed in,
/// opens a list of its observations instead.
class ObservationClusterLayer extends StatefulWidget {
  const ObservationClusterLayer({
    super.key,
    required this.observations,
    this.radius = defaultClusterRadius,
  });

  final List<Observation> observations;

  /// How close, in screen pixels, observations must be to share a marker.
  final double radius;

  @override
  State<ObservationClusterLayer> createState() =>
      _ObservationClusterLayerState();
}

class _ObservationClusterLayerState extends State<ObservationClusterLayer> {
  // The layer rebuilds on every camera change. Panning does not change the
  // groups, so they are only worked out again when the zoom or the
  // observations change.
  List<Observation>? _groupedObservations;
  double? _groupedZoom;
  double? _groupedRadius;
  List<ObservationCluster> _clusters = const [];

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (!identical(_groupedObservations, widget.observations) ||
        _groupedZoom != camera.zoom ||
        _groupedRadius != widget.radius) {
      _groupedObservations = widget.observations;
      _groupedZoom = camera.zoom;
      _groupedRadius = widget.radius;
      _clusters = clusterObservations(
        widget.observations,
        project: (position) => camera.project(position),
        radius: widget.radius,
      );
    }

    final textScaler = MediaQuery.textScalerOf(context);
    return MarkerLayer(
      markers: [
        for (final cluster in _clusters)
          Marker(
            key: ValueKey(cluster.observations.first.id),
            point: cluster.center,
            width: ObservationClusterMarker.width,
            height: ObservationClusterMarker.heightFor(cluster, textScaler),
            // The whole marker sits above the position, so the pin points at it.
            alignment: Alignment.topCenter,
            child: ObservationClusterMarker(
              cluster: cluster,
              onTap: () => _onClusterTapped(cluster),
            ),
          ),
      ],
    );
  }

  void _onClusterTapped(ObservationCluster cluster) {
    final camera = MapCamera.of(context);
    final maxZoom = camera.maxZoom;
    final fullyZoomedIn = maxZoom != null && camera.zoom >= maxZoom;
    if (cluster.sharesSinglePosition || fullyZoomedIn) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ObservationClusterSheet(cluster: cluster),
      );
      return;
    }
    MapController.of(context).fitCamera(
      CameraFit.coordinates(
        coordinates: cluster.positions,
        padding: const EdgeInsets.all(80),
      ),
    );
  }
}
