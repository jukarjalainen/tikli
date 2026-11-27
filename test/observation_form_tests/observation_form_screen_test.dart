import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/repositories/custom_list_repository.dart';
import 'package:tikli/core/repositories/species_repository.dart';
import 'package:tikli/core/services/location_service.dart';
import 'package:tikli/core/services/reverse_geocoding_service.dart';
import 'package:tikli/features/observation_form/bloc/observation_form_bloc.dart';
import 'package:tikli/features/observation_form/presentation/observation_form_screen.dart';
import 'package:tikli/features/species_list/bloc/species_list_bloc.dart';

import '../helpers/observation_fakes.dart';

const _home = LatLng(60.17, 24.94);
const _elsewhere = LatLng(61.5, 23.8);

class _FakeLocationService extends Fake implements LocationService {
  var calls = 0;

  @override
  LatLng? get lastLocation => null;

  @override
  Future<LatLng?> getCurrentLocation() async {
    calls++;
    return _home;
  }
}

class _FakeReverseGeocodingService extends Fake
    implements ReverseGeocodingService {
  @override
  Future<String?> lookupDescription(LatLng position) async => null;
}

class _FakeSpeciesRepository extends Fake implements SpeciesRepository {}

void main() {
  late Directory tempDir;
  late FakeObservationRepository observations;
  late CustomListRepository customLists;
  late _FakeLocationService locationService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tikli_form_test');
    // The screen keeps map tiles in the temporary directory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    observations = FakeObservationRepository();
    customLists = fakeCustomListRepository();
    locationService = _FakeLocationService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    observations.dispose();
    customLists.dispose();
    tempDir.deleteSync(recursive: true);
  });

  Future<ObservationFormBloc> pumpForm(WidgetTester tester) async {
    final formBloc = ObservationFormBloc(
      observationRepository: observations,
      customListRepository: customLists,
      locationService: locationService,
      reverseGeocodingService: _FakeReverseGeocodingService(),
      selectedSpecies: const [talitiainen],
      initialPosition: _elsewhere,
    );
    addTearDown(formBloc.close);
    final speciesBloc = SpeciesListBloc(
      speciesRepository: _FakeSpeciesRepository(),
    );
    addTearDown(speciesBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: formBloc),
            BlocProvider.value(value: speciesBloc),
          ],
          child: const ObservationFormScreen(selectedSpecies: [talitiainen]),
        ),
      ),
    );
    await tester.pump();
    return formBloc;
  }

  /// Unmounts the form and lets its map tile requests run out, so no
  /// timers are left pending when the test ends.
  Future<void> closeForm(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  LatLng mapCenter(WidgetTester tester) =>
      MapCamera.of(tester.element(find.byType(TileLayer))).center;

  testWidgets('the location button sits in the top right corner of the map', (
    tester,
  ) async {
    await pumpForm(tester);

    final button = find.byTooltip('Oma sijainti');
    expect(button, findsOneWidget);

    final map = tester.getRect(find.byType(FlutterMap));
    final buttonRect = tester.getRect(button);
    expect(map.contains(buttonRect.center), isTrue);
    expect(buttonRect.center.dx, greaterThan(map.center.dx));
    expect(buttonRect.center.dy, lessThan(map.center.dy));
    await closeForm(tester);
  });

  testWidgets('the location button moves the map to the current location', (
    tester,
  ) async {
    final bloc = await pumpForm(tester);
    expect(mapCenter(tester), _elsewhere);

    final button = find.byTooltip('Oma sijainti');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pump();

    expect(locationService.calls, 1);
    expect(bloc.state.position, _home);
    expect(mapCenter(tester).latitude, closeTo(_home.latitude, 1e-9));
    expect(mapCenter(tester).longitude, closeTo(_home.longitude, 1e-9));
    await closeForm(tester);
  });
}
