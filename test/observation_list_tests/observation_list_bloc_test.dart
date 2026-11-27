import 'package:flutter_test/flutter_test.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/models/observation.dart';
import 'package:tikli/core/repositories/custom_list_repository.dart';
import 'package:tikli/features/observation_list/bloc/observation_list_bloc.dart';

import '../helpers/observation_fakes.dart';

void main() {
  final newYearsEve = DateTime(2026, 12, 31, 23, 59);
  final newYearsDay = DateTime(2027, 1, 1);
  final lastYears = testObservation('last-year', DateTime(2026, 5, 1));

  late DateTime now;
  late FakeObservationRepository repository;
  late CustomListRepository customLists;
  late ObservationListBloc bloc;

  /// Lets the bloc work through its queued events.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> startBloc(
    List<Observation> observations, {
    String? lastUsedCustomListId = 'pihapinna',
  }) async {
    repository = FakeObservationRepository(observations);
    customLists = fakeCustomListRepository(
      customLists: [pihapinna, mokki],
      activeCustomListId: lastUsedCustomListId,
    );
    bloc = ObservationListBloc(
      observationRepository: repository,
      customListRepository: customLists,
      clock: () => now,
    )..add(const ObservationListSubscriptionRequested());
    await settle();
  }

  Future<void> send(ObservationListEvent event) async {
    bloc.add(event);
    await settle();
  }

  Future<void> selectYear(int year) {
    return send(
      ObservationListFilterChanged(ObservationType.yearly, year: year),
    );
  }

  List<String> shownIds() {
    return bloc.state
        .observationsFor(ObservationType.yearly)
        .map((observation) => observation.id)
        .toList();
  }

  List<String> shownCustomListIds() {
    return bloc.state
        .observationsFor(ObservationType.custom)
        .map((observation) => observation.id)
        .toList();
  }

  tearDown(() async {
    await bloc.close();
    repository.dispose();
    customLists.dispose();
  });

  test('starts an empty list for a new year', () async {
    now = newYearsDay;
    await startBloc([lastYears]);

    expect(bloc.state.selectedYear, 2027);
    expect(bloc.state.availableYears, [2027, 2026]);
    expect(shownIds(), isEmpty);
  });

  test('selects the current year when observations load later', () async {
    now = newYearsDay;
    await startBloc(const []);

    repository.replaceAll([lastYears]);
    await settle();

    expect(bloc.state.selectedYear, 2027);
    expect(bloc.state.availableYears, [2027, 2026]);
  });

  test('moves to the new list when the year changes', () async {
    now = newYearsEve;
    await startBloc([lastYears]);
    expect(bloc.state.selectedYear, 2026);
    expect(shownIds(), ['last-year']);

    now = newYearsDay;
    await send(const ObservationListYearCheckRequested());

    expect(bloc.state.currentYear, 2027);
    expect(bloc.state.selectedYear, 2027);
    expect(shownIds(), isEmpty);

    await selectYear(2026);
    expect(shownIds(), ['last-year']);
  });

  test('keeps an older year selected when the year changes', () async {
    now = newYearsEve;
    await startBloc([
      lastYears,
      testObservation('older', DateTime(2025, 5, 1)),
    ]);
    await selectYear(2025);

    now = newYearsDay;
    await send(const ObservationListYearCheckRequested());

    expect(bloc.state.currentYear, 2027);
    expect(bloc.state.selectedYear, 2025);
    expect(shownIds(), ['older']);
  });

  test('notices a new year when observations change', () async {
    now = newYearsEve;
    await startBloc([lastYears]);

    now = newYearsDay;
    repository.replaceAll([
      testObservation('this-year', newYearsDay),
      lastYears,
    ]);
    await settle();

    expect(bloc.state.selectedYear, 2027);
    expect(shownIds(), ['this-year']);
  });

  test('returns to the current year when the browsed year empties', () async {
    now = newYearsDay;
    await startBloc([lastYears]);
    await selectYear(2026);

    await send(const ObservationListObservationDeleted('last-year'));

    expect(bloc.state.selectedYear, 2027);
    expect(bloc.state.availableYears, [2027]);
  });

  group('custom lists', () {
    final atHome = testObservation(
      'home',
      DateTime(2026, 5, 1),
      type: ObservationType.custom,
      customListId: 'pihapinna',
    );
    final atCabin = testObservation(
      'cabin',
      DateTime(2026, 6, 1),
      type: ObservationType.custom,
      customListId: 'mokki',
    );

    test('shows the last used custom list', () async {
      now = newYearsDay;
      await startBloc([atHome, atCabin]);

      expect(bloc.state.activeCustomListId, 'pihapinna');
      expect(bloc.state.customLists, [pihapinna, mokki]);
      expect(shownCustomListIds(), ['home']);
    });

    test('shows the oldest custom list before any is used', () async {
      now = newYearsDay;
      await startBloc([atHome, atCabin], lastUsedCustomListId: null);

      expect(bloc.state.activeCustomListId, isNull);
      expect(shownCustomListIds(), ['home']);
    });

    test('opens another custom list from the dropdown', () async {
      now = newYearsDay;
      await startBloc([atHome, atCabin]);

      await send(
        const ObservationListFilterChanged(
          ObservationType.custom,
          customListId: 'mokki',
        ),
      );

      expect(bloc.state.selectedCustomListId, 'mokki');
      expect(shownCustomListIds(), ['cabin']);
    });

    test('shows the last used list again after saving to it', () async {
      now = newYearsDay;
      await startBloc([atHome, atCabin]);
      await send(
        const ObservationListFilterChanged(
          ObservationType.custom,
          customListId: 'mokki',
        ),
      );

      await customLists.setActive('mokki');
      await settle();
      await customLists.setActive('pihapinna');
      await settle();

      expect(bloc.state.activeCustomListId, 'pihapinna');
      expect(bloc.state.selectedCustomListId, isNull);
      expect(shownCustomListIds(), ['home']);
    });

    test('lists a custom list added in the observation form', () async {
      now = newYearsDay;
      await startBloc([atHome, atCabin]);

      await customLists.create('Saari');
      await settle();

      expect(bloc.state.customLists.map((list) => list.name), [
        'Pihapinna',
        'Mökki',
        'Saari',
      ]);
      expect(shownCustomListIds(), ['home']);
    });

    test('counts a species once in each custom list', () async {
      now = newYearsDay;
      await startBloc([
        atHome,
        testObservation(
          'home-again',
          DateTime(2026, 7, 1),
          type: ObservationType.custom,
        ),
        atCabin,
      ]);
      expect(shownCustomListIds(), ['home']);

      await send(
        const ObservationListFilterChanged(
          ObservationType.custom,
          customListId: 'mokki',
        ),
      );
      expect(shownCustomListIds(), ['cabin']);
    });
  });

  test('counts a species once in each year', () async {
    now = newYearsDay;
    await startBloc([
      testObservation('second', DateTime(2027, 1, 2)),
      testObservation('first', DateTime(2027, 1, 1)),
      lastYears,
    ]);
    expect(shownIds(), ['second']);

    await selectYear(2026);
    expect(shownIds(), ['last-year']);
  });
}
