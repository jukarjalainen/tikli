// Entry point of the Tikli application. 
// Initializes essential services, repositories, and runs the root application widget.

import 'package:flutter/material.dart';
import 'app.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';

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
