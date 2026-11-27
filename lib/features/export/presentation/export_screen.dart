import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../core/models/custom_list.dart';
import '../../../core/repositories/observation_repository.dart';
import '../../../core/repositories/custom_list_repository.dart';
import '../formatters/observation_text_formatter.dart';

// UI screen for exporting observations into files (TXT, JSON).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  // creates a JSON string representing the list of observations, suitable for backup/restore purposes
  String _generateJsonContent(
    List<Observation> observations,
    List<CustomList> customLists,
  ) {
    final list =
        observations.map((obs) {
          return {
            'id': obs.id,
            'speciesId': obs.species.id,
            'type':
                obs
                    .type
                    .storageKey, // use storageKey to identify the type in JSON
            'timestamp': obs.timestamp?.toIso8601String(),
            'latitude': obs.position?.latitude,
            'longitude': obs.position?.longitude,
            'municipality': obs.municipality,
            'customListId': obs.customListId,
          };
        }).toList();
    return jsonEncode({
      'customLists': [for (final customList in customLists) customList.toMap()],
      'observations': list,
    });
  }

  // saves the given content to a temporary file and shares it using the system's share dialog
  Future<void> _exportFile(
    BuildContext context,
    String content,
    String fileName,
    String mimeType,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      final xFile = XFile(file.path, mimeType: mimeType);

      // share the file using the system's share dialog
      await Share.shareXFiles([
        xFile,
      ], text: 'Tässä Tikli-sovelluksen havaintoni!');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Virhe viennissä: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // gets all observations from the repository to prepare the export content
    final repository = context.read<ObservationRepository>();
    final observations = repository.getAll();
    final customLists =
        context.read<CustomListRepository>().current?.lists ??
        const <CustomList>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Tulosta havainnot')),
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
                final txtContent = formatObservationsAsText(
                  observations,
                  customLists: customLists,
                );
                await _exportFile(
                  context,
                  txtContent,
                  'tikli_havainnot.txt',
                  'text/plain',
                );
              },
              icon: const Icon(Icons.description),
              label: const Text('Tulosta .txt (Tekstitiedosto)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final jsonContent = _generateJsonContent(
                  observations,
                  customLists,
                );
                await _exportFile(
                  context,
                  jsonContent,
                  'tikli_backup.json',
                  'application/json',
                );
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
