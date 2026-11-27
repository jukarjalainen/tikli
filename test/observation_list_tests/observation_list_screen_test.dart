import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/models/custom_list.dart';
import 'package:tikli/features/observation_list/bloc/observation_list_bloc.dart';
import 'package:tikli/features/observation_list/presentation/observation_list_screen.dart';
import 'package:tikli/shared/widgets/year_rollover_watcher.dart';

import '../helpers/observation_fakes.dart';

void main() {
  final newYearsEve = DateTime(2026, 12, 31, 23, 59);
  final newYearsDay = DateTime(2027, 1, 1);

  late DateTime now;

  /// Shows the screen with one yearly observation made in 2026, and the
  /// custom lists [customLists].
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<CustomList>? customLists,
  }) async {
    final repository = FakeObservationRepository([
      testObservation('last-year', DateTime(2026, 5, 1)),
    ]);
    await tester.pumpWidget(
      BlocProvider(
        create:
            (_) => ObservationListBloc(
              observationRepository: repository,
              customListRepository: fakeCustomListRepository(
                customLists: customLists ?? [pihapinna, mokki],
              ),
              clock: () => now,
            )..add(const ObservationListSubscriptionRequested()),
        child: const YearRolloverWatcher(
          child: MaterialApp(home: ObservationListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  int? dropdownYear(WidgetTester tester) {
    return tester
        .state<FormFieldState<int>>(find.byType(DropdownButtonFormField<int>))
        .value;
  }

  void expectEmptyList(WidgetTester tester, {required int year}) {
    expect(dropdownYear(tester), year);
    expect(find.text('Yhteensä: 0'), findsOneWidget);
    expect(find.text('Talitiainen'), findsNothing);
  }

  testWidgets('shows an empty current year after last year', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);

    expectEmptyList(tester, year: 2027);
  });

  testWidgets('opens a former list from the year dropdown', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026').last);
    await tester.pumpAndSettle();

    expect(dropdownYear(tester), 2026);
    expect(find.text('Yhteensä: 1'), findsOneWidget);
    expect(find.text('Talitiainen'), findsOneWidget);
  });

  const listPicker = Key('observationListPicker');

  Future<void> openListPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(listPicker));
    await tester.pumpAndSettle();
  }

  /// The name of the list the app bar dropdown shows.
  String? shownList(WidgetTester tester) {
    return tester
        .widget<DropdownButton<ObservationListChoice>>(find.byKey(listPicker))
        .value
        ?.label;
  }

  testWidgets('picks the list in the app bar instead of a heading', (
    tester,
  ) async {
    now = newYearsDay;
    await pumpScreen(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(listPicker),
      ),
      findsOneWidget,
    );
    expect(find.text('Vuodenpinnat'), findsOneWidget);
    expect(shownList(tester), 'Vuodenpinnat');
  });

  testWidgets('does not change the list on a sideways swipe', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);
    expect(find.byType(PageView), findsNothing);

    for (final dx in [-400.0, 400.0]) {
      await tester.drag(find.byType(Scaffold), Offset(dx, 0));
      await tester.pumpAndSettle();

      expect(shownList(tester), 'Vuodenpinnat');
      expect(dropdownYear(tester), 2027);
    }
  });

  testWidgets('fits a long list name in the app bar on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final longList = CustomList(
      id: 'long',
      name: 'Kesämökin rantasaunan takapihan lintulauta',
      createdAt: DateTime(2022),
    );
    now = newYearsDay;
    await pumpScreen(tester, customLists: [longList]);

    await openListPicker(tester);
    await tester.tap(find.text(longList.name).last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(shownList(tester), longList.name);
  });

  testWidgets('shows the year picker only for Vuodenpinnat', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

    for (final label in ['Elämänpinnat', 'Pihapinna', 'Vuodenpinnat']) {
      await openListPicker(tester);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();

      expect(shownList(tester), label);
      expect(
        find.byType(DropdownButtonFormField<int>),
        label == 'Vuodenpinnat' ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('offers every list in one dropdown, Vuodenpinnat first', (
    tester,
  ) async {
    now = newYearsDay;
    await pumpScreen(tester);
    expect(find.text('Vuodenpinnat'), findsOneWidget);

    await openListPicker(tester);

    // The open menu lists them top to bottom in this order.
    final tops = [
      for (final label in [
        'Vuodenpinnat',
        'Elämänpinnat',
        'Pihapinna',
        'Mökki',
      ])
        tester.getTopLeft(find.text(label).last).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(4));
  });

  testWidgets('opens a custom list from the list dropdown', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);

    await openListPicker(tester);
    await tester.tap(find.text('Mökki').last);
    await tester.pumpAndSettle();

    expect(find.text('Mökki'), findsOneWidget);
    expect(shownList(tester), 'Mökki');
    expect(find.text('Yhteensä: 0'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
  });

  testWidgets('points to the form while there are no custom lists', (
    tester,
  ) async {
    now = newYearsDay;
    await pumpScreen(tester, customLists: const []);

    await openListPicker(tester);
    await tester.tap(find.text('Omat listat').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Ei omia listoja. Lisää lista havaintolomakkeella.'),
      findsOneWidget,
    );
  });

  testWidgets('starts the new list when the app is resumed', (tester) async {
    now = newYearsEve;
    await pumpScreen(tester);
    expect(dropdownYear(tester), 2026);

    now = newYearsDay;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expectEmptyList(tester, year: 2027);
  });

  testWidgets('starts the new list while the app stays open', (tester) async {
    now = newYearsEve;
    await pumpScreen(tester);
    expect(dropdownYear(tester), 2026);

    now = newYearsDay;
    await tester.pump(YearRolloverWatcher.checkInterval);
    await tester.pumpAndSettle();

    expectEmptyList(tester, year: 2027);
  });
}
