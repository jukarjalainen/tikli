// Manages the navigation and routing logic for the entire application. 
// Defines the routes and maps them to their respective screens.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_router.dart';
import 'core/constants/app_routes.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';
import 'core/services/location_permission_service.dart';
import 'core/services/location_service.dart';
import 'features/observation_list/bloc/observation_list_bloc.dart';
import 'features/species_list/bloc/species_list_bloc.dart';

class TikliApp extends StatefulWidget {
  const TikliApp({
    super.key,
    required this.observationRepository,
    required this.speciesRepository,
  });

  final ObservationRepository observationRepository;
  final SpeciesRepository speciesRepository;

  @override
  State<TikliApp> createState() => _TikliAppState();
}

class _TikliAppState extends State<TikliApp> {
  late final AppRouter _router;
  late final LocationPermissionService _locationPermissionService;
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(observationRepository: widget.observationRepository);
    _locationPermissionService = LocationPermissionService();
    _locationService = LocationService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationPermissionService.ensurePermission();
    });
  }

  @override
  void dispose() {
    widget.observationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ObservationRepository>.value(
          value: widget.observationRepository,
        ),
        RepositoryProvider<SpeciesRepository>.value(
          value: widget.speciesRepository,
        ),
        RepositoryProvider<LocationService>.value(value: _locationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    SpeciesListBloc(speciesRepository: widget.speciesRepository)
                      ..add(const SpeciesListRequested()),
          ),
          BlocProvider(
            create:
                (context) => ObservationListBloc(
                  observationRepository: widget.observationRepository,
                )..add(const ObservationListSubscriptionRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'Tikli',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF57BF32),
            ),
            useMaterial3: true,
          ),
          initialRoute: AppRoutes.speciesList,
          onGenerateRoute: _router.onGenerateRoute,
        ),
      ),
    );
  }
}
