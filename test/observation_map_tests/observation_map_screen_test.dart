import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/features/observation_list/bloc/observation_list_bloc.dart';
import 'package:tikli/features/observation_map/presentation/observation_map_screen.dart';

import '../helpers/observation_fakes.dart';

class _MockObservationRepository extends Mock
    implements ObservationRepository {}

void main() {
  testWidgets('observation map is fixed north-up and cannot rotate', (
    tester,
  ) async {
    final observation = Observation(
      id: '1',
      species: const Species(id: 'tikli', commonName: 'Tikli'),
      type: ObservationType.yearly,
      timestamp: DateTime(2026, 5, 1),
      position: const LatLng(60.17, 24.94),
    );
    final repository = _MockObservationRepository();
    when(() => repository.getAll()).thenReturn([observation]);
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => Stream.value([observation]));

    final bloc = ObservationListBloc(
      observationRepository: repository,
      yardListRepository: fakeYardListRepository(),
    )..add(const ObservationListSubscriptionRequested());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ObservationListBloc>.value(
          value: bloc,
          child: const ObservationMapScreen(),
        ),
      ),
    );
    // Let the bloc process its subscription and data events.
    for (var i = 0; i < 10 && find.byType(FlutterMap).evaluate().isEmpty; i++) {
      await tester.pump();
    }
    expect(find.byType(FlutterMap), findsOneWidget);

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final interaction = map.options.interactionOptions;
    expect(map.options.initialRotation, 0);
    expect(InteractiveFlag.hasRotate(interaction.flags), isFalse);
    expect(InteractiveFlag.hasDrag(interaction.flags), isTrue);
    expect(InteractiveFlag.hasPinchZoom(interaction.flags), isTrue);
    expect(
      interaction.cursorKeyboardRotationOptions.isKeyTrigger,
      isNotNull,
    );
  });
}
