// Map marker for a group of observations: a label above a pin.

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/enums/observation_type.dart';
import '../clustering/cluster_label.dart';
import '../clustering/observation_cluster.dart';

/// The pin colour of observations of [type].
Color observationTypeColor(ObservationType type) => switch (type) {
  ObservationType.life => Colors.green,
  ObservationType.custom => Colors.orange,
  ObservationType.yearly => Colors.red,
};

class ObservationClusterMarker extends StatelessWidget {
  const ObservationClusterMarker({
    super.key,
    required this.cluster,
    this.onTap,
  });

  /// Width of the marker.
  static const double width = 140;

  static const double _fontSize = 10;
  static const double _lineHeight = 1.3;
  static const double _iconSize = 24;
  static const double _labelPadding = 2;
  static const double _labelGap = 4;
  // Room for rounding, so the label never overflows its marker.
  static const double _slack = 4;

  /// The height a marker for [cluster] needs with [textScaler].
  static double heightFor(ObservationCluster cluster, TextScaler textScaler) {
    final lineCount = clusterLabelLines(cluster).length;
    final lineHeight = textScaler.scale(_fontSize) * _lineHeight;
    return lineCount * lineHeight +
        2 * _labelPadding +
        _labelGap +
        _iconSize +
        _slack;
  }

  final ObservationCluster cluster;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lines = clusterLabelLines(cluster);
    // Kept at the bottom so the tip of the pin stays on the position.
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: _labelPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in lines)
                    Text(
                      line,
                      style: const TextStyle(
                        fontSize: _fontSize,
                        height: _lineHeight,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: _labelGap),
            Icon(
              cluster.count == 1
                  ? MdiIcons.mapMarkerStar
                  : MdiIcons.mapMarkerMultiple,
              size: _iconSize,
              color: observationTypeColor(cluster.observations.first.type),
            ),
          ],
        ),
      ),
    );
  }
}
