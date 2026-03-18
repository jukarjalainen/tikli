import 'package:flutter/material.dart';

import 'app.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';

/// The entry point of the application.
///
/// This function initializes the Flutter binding, creates
/// instances of the observation and species repositories,
/// and then runs the application with the created repositories.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final speciesRepository = SpeciesRepository();
  final observationRepository = ObservationRepository(speciesRepository: speciesRepository);

  runApp(
    TikliApp(
      observationRepository: observationRepository,
      speciesRepository: speciesRepository,
    ),
  );
}
