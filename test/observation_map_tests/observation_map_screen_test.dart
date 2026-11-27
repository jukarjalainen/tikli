import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/custom_list.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/models/species.dart';
import 'package:tikli/core/repositories/custom_list_repository.dart';
import 'package:tikli/core/repositories/observation_repository.dart';
import 'package:tikli/features/observation_list/bloc/observation_list_bloc.dart';
import 'package:tikli/features/observation_map/presentation/observation_map_screen.dart';
import 'package:tikli/features/observation_map/widgets/observation_cluster_marker.dart';
import 'package:tikli/features/observation_map/widgets/observation_cluster_sheet.dart';

class _MockObservationRepository extends Mock
    implements ObservationRepository {}

class _MockCustomListRepository extends Mock implements CustomListRepository {}

const _helsinki = LatLng(60.17, 24.94);
// About 1 km north of _helsinki.
const _nearHelsinki = LatLng(60.179, 24.94);
const _oulu = LatLng(65.01, 25.47);
const _tampere = LatLng(61.50, 23.76);

final _mokki = CustomList(
  id: 'mokki',
  name: 'Mökki',
  createdAt: DateTime(2026, 1, 1),
);
final _pihapinna = CustomList(
  id: 'pihapinna',
  name: 'Pihapinna',
  createdAt: DateTime(2026, 2, 1),
);

Observation _observation(
  String id,
  String species, {
  LatLng? position = _helsinki,
  ObservationType type = ObservationType.yearly,
  int year = 2026,
  String? customListId,
}) {
  return Observation(
    id: id,
    species: Species(id: species.toLowerCase(), commonName: species),
    type: type,
    timestamp: DateTime(year, 5, 1),
    position: position,
    customListId: customListId,
  );
}

/// Opens the map with [observations], the current year being 2026. The
/// observations page shows the yearly list, or the list [filter] picks before
/// the map opens, as the map is only reached from that page.
Future<ObservationListBloc> _pumpMap(
  WidgetTester tester,
  List<Observation> observations, {
  ObservationListFilterChanged? filter,
}) async {
  final repository = _MockObservationRepository();
  when(() => repository.getAll()).thenReturn(observations);
  when(
    () => repository.watchAll(),
  ).thenAnswer((_) => Stream.value(observations));

  // A plain stream stands in for CustomListRepository.watch(), whose async*
  // generator runs in the test's fake-async zone: cancelling it in
  // bloc.close() during tear-down waits on microtasks nothing flushes any
  // more, so the test would never complete.
  final customListRepository = _MockCustomListRepository();
  when(() => customListRepository.watch()).thenAnswer(
    (_) => Stream.value(
      CustomListsSnapshot(lists: [_mokki, _pihapinna], activeId: _mokki.id),
    ),
  );

  final bloc = ObservationListBloc(
    observationRepository: repository,
    customListRepository: customListRepository,
    clock: () => DateTime(2026, 6, 1),
  )..add(const ObservationListSubscriptionRequested());
  addTearDown(bloc.close);

  if (filter != null) {
    // Lets the custom lists arrive before one of them is picked.
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
    bloc.add(filter);
    await _settle(tester);
  }

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ObservationListBloc>.value(
        value: bloc,
        child: const ObservationMapScreen(),
      ),
    ),
  );
  await _settle(tester);
  return bloc;
}

/// Lets the bloc process its events and the map rebuild.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder get _markers => find.byType(ObservationClusterMarker);

void main() {
  testWidgets('observation map is fixed north-up and cannot rotate', (
    tester,
  ) async {
    await _pumpMap(tester, [_observation('1', 'Tikli')]);
    expect(find.byType(FlutterMap), findsOneWidget);

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final interaction = map.options.interactionOptions;
    expect(map.options.initialRotation, 0);
    expect(InteractiveFlag.hasRotate(interaction.flags), isFalse);
    expect(InteractiveFlag.hasDrag(interaction.flags), isTrue);
    expect(InteractiveFlag.hasPinchZoom(interaction.flags), isTrue);
    expect(interaction.cursorKeyboardRotationOptions.isKeyTrigger, isNotNull);
  });

  group('shows the list open on the observations page', () {
    final observations = [
      _observation('y2026', 'Tikli'),
      _observation('y2025', 'Peippo', position: _oulu, year: 2025),
      _observation(
        'life',
        'Talitiainen',
        position: _tampere,
        type: ObservationType.life,
      ),
      _observation(
        'mokki',
        'Käpytikka',
        position: _oulu,
        type: ObservationType.custom,
        customListId: _mokki.id,
      ),
      _observation(
        'piha',
        'Varis',
        position: _tampere,
        type: ObservationType.custom,
        customListId: _pihapinna.id,
      ),
    ];

    testWidgets('only the observations of the yearly list of the year', (
      tester,
    ) async {
      await _pumpMap(tester, observations);

      expect(find.text('Havaintokartta · Vuodenpinnat 2026'), findsOneWidget);
      expect(find.text('Tikli'), findsOneWidget);
      expect(find.text('Peippo'), findsNothing);
      expect(find.text('Talitiainen'), findsNothing);
      expect(find.text('Käpytikka'), findsNothing);
      expect(find.text('Varis'), findsNothing);
    });

    testWidgets('only the observations of the custom list open', (
      tester,
    ) async {
      await _pumpMap(
        tester,
        observations,
        filter: ObservationListFilterChanged(
          ObservationType.custom,
          customListId: _mokki.id,
        ),
      );

      expect(find.text('Havaintokartta · Mökki'), findsOneWidget);
      expect(find.text('Käpytikka'), findsOneWidget);
      expect(find.text('Varis'), findsNothing);
      expect(find.text('Tikli'), findsNothing);
      expect(find.text('Talitiainen'), findsNothing);
    });

    testWidgets('each species of the life list once', (tester) async {
      await _pumpMap(tester, [
        ...observations,
        _observation(
          'life2',
          'Talitiainen',
          position: _helsinki,
          type: ObservationType.life,
        ),
      ], filter: const ObservationListFilterChanged(ObservationType.life));

      expect(find.text('Havaintokartta · Elämänpinnat'), findsOneWidget);
      expect(find.text('Talitiainen'), findsOneWidget);
      expect(_markers, findsOneWidget);
    });

    testWidgets('names the list when it has nothing on the map', (
      tester,
    ) async {
      await _pumpMap(tester, [
        _observation('1', 'Tikli', position: null),
        _observation('2', 'Peippo', year: 2025),
      ]);

      expect(find.byType(FlutterMap), findsNothing);
      expect(
        find.text('Listalla "Vuodenpinnat 2026" ei ole havaintoja kartalla.'),
        findsOneWidget,
      );
    });
  });

  group('groups observations', () {
    testWidgets('at the same spot into one marker naming every species', (
      tester,
    ) async {
      await _pumpMap(tester, [
        _observation('1', 'Tikli'),
        _observation('2', 'Talitiainen'),
        // Far enough to get a marker of its own, near enough to be on screen.
        _observation('3', 'Peippo', position: _tampere),
      ]);

      expect(_markers, findsNWidgets(2));
      final helsinkiMarker = find.ancestor(
        of: find.text('Tikli'),
        matching: _markers,
      );
      expect(
        find.descendant(of: helsinkiMarker, matching: find.text('Talitiainen')),
        findsOneWidget,
      );
    });

    testWidgets('of more than 10 observations under their count', (
      tester,
    ) async {
      await _pumpMap(tester, [
        for (var i = 0; i < 11; i++) _observation('$i', 'Laji $i'),
      ]);

      expect(_markers, findsOneWidget);
      expect(find.text('11 havaintoa'), findsOneWidget);
      expect(find.text('Laji 0'), findsNothing);
    });

    testWidgets('apart when zoomed in and again when zoomed out', (
      tester,
    ) async {
      await _pumpMap(tester, [
        _observation('1', 'Tikli'),
        _observation('2', 'Talitiainen', position: _nearHelsinki),
      ]);
      expect(_markers, findsOneWidget);

      // Zoom 14 puts the two about 200 pixels apart, both on screen.
      const between = LatLng(60.1745, 24.94);
      final controller = MapController.of(tester.element(_markers));
      controller.move(between, 14);
      await _settle(tester);
      expect(_markers, findsNWidgets(2));

      controller.move(between, 6);
      await _settle(tester);
      expect(_markers, findsOneWidget);
    });

    testWidgets('and separates them when the group is tapped', (tester) async {
      await _pumpMap(tester, [
        _observation('1', 'Tikli'),
        _observation('2', 'Talitiainen', position: _nearHelsinki),
      ]);
      expect(_markers, findsOneWidget);

      await tester.tap(find.text('Tikli'));
      await _settle(tester);

      expect(_markers, findsNWidgets(2));
      expect(find.byType(ObservationClusterSheet), findsNothing);
    });

    testWidgets('at one spot and lists them when tapped', (tester) async {
      await _pumpMap(tester, [
        _observation('1', 'Tikli'),
        _observation('2', 'Talitiainen'),
      ]);

      await tester.tap(find.text('Tikli'));
      await _settle(tester);

      final sheet = find.byType(ObservationClusterSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('2 havaintoa')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Talitiainen')),
        findsOneWidget,
      );
    });
  });
}
