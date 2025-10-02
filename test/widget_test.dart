import 'package:flutter_test/flutter_test.dart';

import 'package:tikli/app.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/core/repositories/species_repository.dart';

void main() {
  testWidgets('renders initial species list screen', (tester) async {
    await tester.pumpWidget(
      TikliApp(
        observationRepository: ObservationRepository(),
        speciesRepository: SpeciesRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Select species'), findsOneWidget);
  });
}
