import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_routes.dart';
import 'core/models/species.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/yard_list_repository.dart';
import 'core/services/location_service.dart';
import 'core/services/reverse_geocoding_service.dart';
import 'features/observation_form/bloc/observation_form_bloc.dart';
import 'features/observation_form/presentation/observation_form_screen.dart';
import 'features/observation_list/presentation/observation_list_screen.dart';
import 'features/observation_map/presentation/observation_map_screen.dart';
import 'features/species_list/presentation/species_list_screen.dart';
import 'features/export/presentation/export_screen.dart';

class AppRouter {
  AppRouter({
    required ObservationRepository observationRepository,
    required YardListRepository yardListRepository,
  }) : _observationRepository = observationRepository,
       _yardListRepository = yardListRepository;

  final ObservationRepository _observationRepository;
  final YardListRepository _yardListRepository;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.speciesList:
        return MaterialPageRoute(
          builder: (_) => const SpeciesListScreen(),
          settings: settings,
        );
      case AppRoutes.observationForm:
        final species = settings.arguments as List<Species>? ?? <Species>[];
        return MaterialPageRoute(
          builder: (context) {
            final locationService = context.read<LocationService>();
            final reverseGeocodingService =
                context.read<ReverseGeocodingService>();
            return BlocProvider(
              create:
                  (_) => ObservationFormBloc(
                    observationRepository: _observationRepository,
                    yardListRepository: _yardListRepository,
                    locationService: locationService,
                    reverseGeocodingService: reverseGeocodingService,
                    selectedSpecies: species,
                  )..add(const ObservationFormLocationRequested()),
              child: ObservationFormScreen(selectedSpecies: species),
            );
          },
          settings: settings,
        );
      case AppRoutes.observationList:
        return MaterialPageRoute(
          builder: (_) => const ObservationListScreen(),
          settings: settings,
        );
      case AppRoutes.observationMap:
        return MaterialPageRoute(
          builder: (_) => const ObservationMapScreen(),
          settings: settings,
        );
      case AppRoutes.export:
        return MaterialPageRoute(
          builder: (_) => const ExportScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SpeciesListScreen(),
          settings: settings,
        );
    }
  }
}
