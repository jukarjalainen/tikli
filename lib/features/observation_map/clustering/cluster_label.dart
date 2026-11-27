// The text shown on a map marker for a group of observations.

import 'observation_cluster.dart';

/// The most observations a marker lists by species name. A bigger group only
/// shows its count.
const int maxListedObservations = 10;

/// The lines of the marker label for [cluster]: the species names in
/// alphabetical order, or only the number of observations, e.g.
/// `15 havaintoa`, when there are more than [maxListed].
List<String> clusterLabelLines(
  ObservationCluster cluster, {
  int maxListed = maxListedObservations,
}) {
  if (cluster.count > maxListed) return ['${cluster.count} havaintoa'];
  return [
    for (final observation in cluster.observations)
      observation.species.commonName,
  ]..sort();
}
