import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../core/repositories/observation_repository.dart';

// UI screen for exporting observations into files (TXT, JSON).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  // helper method to format DateTime into a readable string (e.g., "1.1.2026")
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }

  // creates a human-readable text content of the observations, sorted by type and date, with a global index
  String _generateTextContent(List<Observation> observations) {
    final buffer = StringBuffer();

    // 1. order observations by timestamp (oldest first), nulls last
    final sortedObs = List<Observation>.from(observations)
      ..sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return -1;
        if (b.timestamp == null) return 1;
        return a.timestamp!.compareTo(b.timestamp!);
      });

    // 2. set the order of types: yearly, yard, life (or whatever order is desired)
    final typesOrder = [
      ObservationType.yearly,
      ObservationType.yard,
      ObservationType.life
    ];

    int globalIndex = 1;

    // 3. Print each type separately
    for (final type in typesOrder) {
      final typeObs = sortedObs.where((o) => o.type == type).toList();
      for (final obs in typeObs) {
        final dateStr = _formatDate(obs.timestamp);
        final addressStr = obs.address ?? '';

        // Muoto: 1. talitiainen 1.1.2026 oulu
        final line = '$globalIndex. ${obs.species.commonName.toLowerCase()} $dateStr $addressStr'.trim();
        
        // clean up whitespace
        buffer.writeln(line.replaceAll(RegExp(r'\s+'), ' '));
        globalIndex++;
      }
    }

    return buffer.toString();
  }

  // creates a JSON string representing the list of observations, suitable for backup/restore purposes
  String _generateJsonContent(List<Observation> observations) {
    final list = observations.map((obs) {
      return {
        'id': obs.id,
        'speciesId': obs.species.id,
        'type': obs.type.storageKey, // use storageKey to identify the type in JSON
        'timestamp': obs.timestamp?.toIso8601String(),
        'latitude': obs.position?.latitude,
        'longitude': obs.position?.longitude,
        'address': obs.address,
        'notes': obs.notes,
      };
    }).toList();
    return jsonEncode(list);
  }

  // saves the given content to a temporary file and shares it using the system's share dialog
  Future<void> _exportFile(BuildContext context, String content, String fileName, String mimeType) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      final xFile = XFile(file.path, mimeType: mimeType);
      
      // share the file using the system's share dialog
      await Share.shareXFiles([xFile], text: 'Tässä Tikli-sovelluksen havaintoni!');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Virhe viennissä: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // gets all observations from the repository to prepare the export content
    final repository = context.read<ObservationRepository>();
    final observations = repository.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tulosta havainnot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Yhteensä ${observations.length} havaintoa.',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final txtContent = _generateTextContent(observations);
                await _exportFile(context, txtContent, 'tikli_havainnot.txt', 'text/plain');
              },
              icon: const Icon(Icons.description),
              label: const Text('Tulosta .txt (Tekstitiedosto)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final jsonContent = _generateJsonContent(observations);
                await _exportFile(context, jsonContent, 'tikli_backup.json', 'application/json');
              },
              icon: const Icon(Icons.code),
              label: const Text('Tulosta .json (Varmuuskopio)'),
            ),
          ],
        ),
      ),
    );
  }
}