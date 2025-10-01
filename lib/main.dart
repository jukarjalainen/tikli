import 'package:flutter/material.dart';

import 'app.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final observationRepository = ObservationRepository();
  final speciesRepository = SpeciesRepository();
  runApp(
    TikliApp(
      observationRepository: observationRepository,
      speciesRepository: speciesRepository,
    ),
  );
}
