import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../core/models/yard_list.dart';

/// Builds the human-readable text export of [observations].
///
/// Every year has its own yearly list, so yearly observations get one section
/// per year, oldest first. Each section is numbered from one and ordered by
/// observation time.
///
/// Each of [yardLists] gets its own yard list section, in the given order,
/// headed by its name. Yard observations of lists not in [yardLists] share a
/// plain "Pihapinnat" section.
String formatObservationsAsText(
  List<Observation> observations, {
  List<YardList> yardLists = const [],
}) {
  // Oldest first, with observations without a timestamp at the start.
  final sorted = List<Observation>.from(observations)..sort((a, b) {
    if (a.timestamp == null && b.timestamp == null) return 0;
    if (a.timestamp == null) return -1;
    if (b.timestamp == null) return 1;
    return a.timestamp!.compareTo(b.timestamp!);
  });

  List<Observation> ofType(ObservationType type) =>
      sorted.where((observation) => observation.type == type).toList();

  // The map keeps insertion order, so the years stay chronological.
  final yearly = <int?, List<Observation>>{};
  for (final observation in ofType(ObservationType.yearly)) {
    yearly
        .putIfAbsent(observation.timestamp?.year, () => <Observation>[])
        .add(observation);
  }

  final yard = ofType(ObservationType.yard);
  final knownYardListIds = {for (final list in yardLists) list.id};
  final unlistedYard = [
    for (final observation in yard)
      if (!knownYardListIds.contains(observation.yardListId)) observation,
  ];

  final sections = [
    // Keep the heading in the output even when there is nothing to list.
    if (yearly.isEmpty) (header: 'Vuodenpinnat', entries: <Observation>[]),
    for (final MapEntry(key: year, value: entries) in yearly.entries)
      (
        header: year == null ? 'Vuodenpinnat' : 'Vuodenpinnat $year',
        entries: entries,
      ),
    for (final list in yardLists)
      (
        header: 'Pihapinnat: ${list.name}',
        entries: [
          for (final observation in yard)
            if (observation.yardListId == list.id) observation,
        ],
      ),
    if (yardLists.isEmpty || unlistedYard.isNotEmpty)
      (header: 'Pihapinnat', entries: unlistedYard),
    (header: 'Elämänpinnat', entries: ofType(ObservationType.life)),
  ];

  final buffer = StringBuffer();
  for (var i = 0; i < sections.length; i++) {
    // An empty line between sections, but not after the last one.
    if (i > 0) buffer.writeln();
    buffer.writeln(sections[i].header);

    final entries = sections[i].entries;
    for (var j = 0; j < entries.length; j++) {
      buffer.writeln(_formatLine(j + 1, entries[j]));
    }
  }
  return buffer.toString();
}

/// For example "1. talitiainen 1.1.2026 Oulu".
String _formatLine(int index, Observation observation) {
  final date = _formatDate(observation.timestamp);
  final municipality = observation.municipality ?? '';
  final line =
      '$index. ${observation.species.commonName.toLowerCase()} $date $municipality';
  // Collapse the gaps left by missing values.
  return line.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day}.${date.month}.${date.year}';
}
