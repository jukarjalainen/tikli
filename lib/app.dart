// Manages the navigation and routing logic for the entire application.
// Defines the routes and maps them to their respective screens.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_router.dart';
import 'core/constants/app_routes.dart';
import 'core/repositories/observation_repository.dart';
import 'core/repositories/species_repository.dart';
import 'core/repositories/yard_list_repository.dart';
import 'core/services/location_permission_service.dart';
import 'core/services/location_service.dart';
import 'core/services/reverse_geocoding_service.dart';
import 'features/observation_list/bloc/observation_list_bloc.dart';
import 'features/species_list/bloc/species_list_bloc.dart';
import 'shared/widgets/year_rollover_watcher.dart';

class TikliApp extends StatefulWidget {
  const TikliApp({
    super.key,
    required this.observationRepository,
    required this.speciesRepository,
    required this.yardListRepository,
  });

  final ObservationRepository observationRepository;
  final SpeciesRepository speciesRepository;
  final YardListRepository yardListRepository;

  @override
  State<TikliApp> createState() => _TikliAppState();
}

class _TikliAppState extends State<TikliApp> {
  late final AppRouter _router;
  late final LocationPermissionService _locationPermissionService;
  late final LocationService _locationService;
  late final ReverseGeocodingService _reverseGeocodingService;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(
      observationRepository: widget.observationRepository,
      yardListRepository: widget.yardListRepository,
    );
    _locationPermissionService = LocationPermissionService();
    _locationService = LocationService();
    _reverseGeocodingService = ReverseGeocodingService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationPermissionService.ensurePermission();
    });
  }

  @override
  void dispose() {
    _reverseGeocodingService.dispose();
    widget.observationRepository.dispose();
    widget.yardListRepository.dispose();
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
        RepositoryProvider<YardListRepository>.value(
          value: widget.yardListRepository,
        ),
        RepositoryProvider<LocationService>.value(value: _locationService),
        RepositoryProvider<ReverseGeocodingService>.value(
          value: _reverseGeocodingService,
        ),
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
                  yardListRepository: widget.yardListRepository,
                )..add(const ObservationListSubscriptionRequested()),
          ),
        ],
        child: YearRolloverWatcher(
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
      ),
    );
  }
}
