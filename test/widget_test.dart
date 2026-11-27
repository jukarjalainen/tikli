import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tikli/app.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/repositories/species_repository.dart';

import 'helpers/observation_fakes.dart';

class _FakeSpeciesRepository extends Fake implements SpeciesRepository {
  @override
  Future<List<Species>> loadSpecies() async => const [talitiainen];
}

void main() {
  testWidgets('renders initial species list screen', (tester) async {
    // The letter shortcuts need a taller screen than the 800x600 default.
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Answer the location permission check made at startup.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => switch (call.method) {
        'checkPermission' => 3, // LocationPermission.always
        'isLocationServiceEnabled' => true,
        _ => null,
      },
    );

    await tester.pumpWidget(
      TikliApp(
        observationRepository: FakeObservationRepository(),
        speciesRepository: _FakeSpeciesRepository(),
        yardListRepository: fakeYardListRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Valitse lajit'), findsOneWidget);
    expect(find.text('Talitiainen'), findsOneWidget);
  });
}
