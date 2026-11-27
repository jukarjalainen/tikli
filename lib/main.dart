// Entry point of the Tikli application.
// Initializes essential services, repositories, and runs the root application widget.

import 'package:flutter/material.dart';
import 'app.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';
import 'core/repositories/custom_list_repository.dart';
import 'core/services/database_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseService = DatabaseService();
  final speciesRepository = SpeciesRepository();
  final observationRepository = ObservationRepository(
    speciesRepository: speciesRepository,
    databaseService: databaseService,
  );
  final customListRepository = CustomListRepository(
    databaseService: databaseService,
  );

  runApp(
    TikliApp(
      observationRepository: observationRepository,
      speciesRepository: speciesRepository,
      customListRepository: customListRepository,
    ),
  );
}
