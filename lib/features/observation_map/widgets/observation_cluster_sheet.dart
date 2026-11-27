// Bottom sheet listing the observations of one map marker.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/observation.dart';
import '../clustering/observation_cluster.dart';

class ObservationClusterSheet extends StatelessWidget {
  const ObservationClusterSheet({super.key, required this.cluster});

  static final DateFormat _dateFormat = DateFormat('d.M.yyyy HH:mm');

  final ObservationCluster cluster;

  @override
  Widget build(BuildContext context) {
    final observations = [...cluster.observations]
      ..sort((a, b) => a.species.commonName.compareTo(b.species.commonName));
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              cluster.count == 1 ? '1 havainto' : '${cluster.count} havaintoa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final observation in observations)
                  ListTile(
                    title: Text(observation.species.commonName),
                    subtitle: Text(_details(observation)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _details(Observation observation) => [
    if (observation.timestamp != null)
      _dateFormat.format(observation.timestamp!),
    if (observation.municipality?.isNotEmpty ?? false)
      observation.municipality!,
  ].join(' · ');
}
