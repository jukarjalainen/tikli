import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/features/observation_list/bloc/observation_list_bloc.dart';
import 'package:tikli/features/observation_list/presentation/observation_list_screen.dart';
import 'package:tikli/shared/widgets/year_rollover_watcher.dart';

import '../helpers/observation_fakes.dart';

void main() {
  final newYearsEve = DateTime(2026, 12, 31, 23, 59);
  final newYearsDay = DateTime(2027, 1, 1);

  late DateTime now;

  /// Shows the screen with one yearly observation made in 2026.
  Future<void> pumpScreen(WidgetTester tester) async {
    final repository = FakeObservationRepository([
      testObservation('last-year', DateTime(2026, 5, 1)),
    ]);
    await tester.pumpWidget(
      BlocProvider(
        create:
            (_) => ObservationListBloc(
              observationRepository: repository,
              yardListRepository: fakeYardListRepository(
                yardLists: [koti, mokki],
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

  Future<void> openListPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('observationListPicker')));
    await tester.pumpAndSettle();
  }

  testWidgets('offers every list in one dropdown, Vuodenpinnat first', (
    tester,
  ) async {
    now = newYearsDay;
    await pumpScreen(tester);
    expect(find.text('Vuodenpinnat'), findsNWidgets(2)); // Title and dropdown.

    await openListPicker(tester);

    // The open menu lists them top to bottom in this order.
    final tops = [
      for (final label in [
        'Vuodenpinnat',
        'Pihapinnat Koti',
        'Pihapinnat Mökki',
        'Elämänpinnat',
      ])
        tester.getTopLeft(find.text(label).last).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(4));
  });

  testWidgets('opens a yard list from the list dropdown', (tester) async {
    now = newYearsDay;
    await pumpScreen(tester);

    await openListPicker(tester);
    await tester.tap(find.text('Pihapinnat Mökki').last);
    await tester.pumpAndSettle();

    expect(find.text('Pihapinnat Mökki'), findsNWidgets(2));
    expect(find.text('Yhteensä: 0'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
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
