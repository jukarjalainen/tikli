import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/repositories/custom_list_repository.dart';
import 'package:tikli/core/services/location_service.dart';
import 'package:tikli/core/services/reverse_geocoding_service.dart';
import 'package:tikli/features/observation_form/bloc/observation_form_bloc.dart';

import '../helpers/observation_fakes.dart';

/// Answers location lookups with [location], or with [pending] when set,
/// and remembers what it found like the real service.
class _FakeLocationService extends Fake implements LocationService {
  LatLng? location;
  Completer<LatLng?>? pending;
  var calls = 0;

  @override
  LatLng? lastLocation;

  @override
  Future<LatLng?> getCurrentLocation() async {
    calls++;
    final found = await (pending?.future ?? Future.value(location));
    if (found != null) lastLocation = found;
    return found;
  }
}

class _FakeReverseGeocodingService extends Fake
    implements ReverseGeocodingService {
  @override
  Future<String?> lookupDescription(LatLng position) async => null;
}

void main() {
  late FakeObservationRepository observations;
  late CustomListRepository customLists;
  late _FakeLocationService locationService;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ObservationFormBloc createBloc({LatLng? initialPosition}) {
    final bloc = ObservationFormBloc(
      observationRepository: observations,
      customListRepository: customLists,
      locationService: locationService,
      reverseGeocodingService: _FakeReverseGeocodingService(),
      selectedSpecies: const [talitiainen],
      initialPosition: initialPosition,
      initialTimestamp: DateTime(2026, 6, 1),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  /// Saves talitiainen to a custom list only, after [prepare] has had
  /// its say on the form.
  Future<ObservationFormBloc> saveCustomListObservation({
    void Function(ObservationFormBloc bloc)? prepare,
  }) async {
    final bloc =
        createBloc()..add(const ObservationTypeToggled(ObservationType.yearly));
    if (prepare != null) {
      prepare(bloc);
    } else {
      bloc.add(const ObservationTypeToggled(ObservationType.custom));
    }
    await settle();
    bloc.add(const ObservationFormSubmitted());
    await settle();
    await settle();
    expect(bloc.state.status, ObservationFormStatus.success);
    return bloc;
  }

  List<String?> savedCustomListIds() => [
    for (final obs in observations.getAll())
      if (obs.type == ObservationType.custom) obs.customListId,
  ];

  setUp(() async {
    observations = FakeObservationRepository();
    locationService = _FakeLocationService();
    customLists = fakeCustomListRepository(
      customLists: [pihapinna, mokki],
      activeCustomListId: 'pihapinna',
    );
    await settle();
  });

  tearDown(() {
    observations.dispose();
    customLists.dispose();
  });

  test('offers every custom list and preselects the last used one', () {
    final bloc = createBloc();

    expect(bloc.state.customLists, [pihapinna, mokki]);
    expect(bloc.state.selectedCustomList, pihapinna);
  });

  test('asks for a custom list when there is none yet', () async {
    customLists.dispose();
    customLists = fakeCustomListRepository();
    await settle();
    final bloc =
        createBloc()
          ..add(const ObservationTypeToggled(ObservationType.yearly))
          ..add(const ObservationTypeToggled(ObservationType.custom));
    await settle();
    expect(bloc.state.customLists, isEmpty);
    expect(bloc.state.selectedCustomListId, isNull);

    bloc.add(const ObservationFormSubmitted());
    await settle();

    expect(bloc.state.errorMessage, 'Valitse oma lista.');
    expect(observations.getAll(), isEmpty);
  });

  test('saves to the preselected custom list', () async {
    await saveCustomListObservation();

    expect(savedCustomListIds(), ['pihapinna']);
  });

  test('picking a custom list ticks the custom list checkbox', () async {
    final bloc =
        createBloc()..add(const ObservationFormCustomListSelected('mokki'));
    await settle();

    expect(bloc.state.selectedCustomListId, 'mokki');
    expect(bloc.state.selectedTypes, contains(ObservationType.custom));
  });

  test('saves to the picked custom list and preselects it next time', () async {
    await saveCustomListObservation(
      prepare:
          (bloc) => bloc.add(const ObservationFormCustomListSelected('mokki')),
    );

    expect(savedCustomListIds(), ['mokki']);
    expect(customLists.current!.activeId, 'mokki');
    expect(createBloc().state.selectedCustomList, mokki);
  });

  test('saves a species once per custom list', () async {
    await saveCustomListObservation();
    await saveCustomListObservation();
    expect(savedCustomListIds(), ['pihapinna']);

    await saveCustomListObservation(
      prepare:
          (bloc) => bloc.add(const ObservationFormCustomListSelected('mokki')),
    );

    expect(savedCustomListIds(), ['pihapinna', 'mokki']);
    expect(
      observations.getAll().where((obs) => obs.type == ObservationType.life),
      hasLength(1),
    );
  });

  test('adds a new custom list and saves to it', () async {
    await saveCustomListObservation(
      prepare:
          (bloc) => bloc.add(const ObservationFormCustomListAdded('Saari')),
    );

    final saari = customLists.current!.lists.last;
    expect(saari.name, 'Saari');
    expect(savedCustomListIds(), [saari.id]);
    expect(customLists.current!.activeId, saari.id);
  });

  test('reports a taken custom list name', () async {
    final bloc =
        createBloc()..add(const ObservationFormCustomListAdded('mökki'));
    await settle();
    await settle();

    expect(bloc.state.errorMessage, 'Lista "mökki" on jo olemassa.');
    expect(customLists.current!.lists, [pihapinna, mokki]);
    expect(bloc.state.selectedCustomListId, 'pihapinna');
  });

  group('current location', () {
    const home = LatLng(60.17, 24.94);
    const elsewhere = LatLng(61.5, 23.8);

    test('moves the map to the location the user asked for', () async {
      locationService.location = home;
      final bloc = createBloc(initialPosition: elsewhere)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 1);
      expect(bloc.state.isLocating, isFalse);
    });

    test('moves the map back even when the position is unchanged', () async {
      locationService.location = home;
      final bloc = createBloc(initialPosition: home)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();
      bloc.add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 2);
    });

    test('reports a location the user asked for that is unavailable', () async {
      final bloc = createBloc(initialPosition: elsewhere)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, elsewhere);
      expect(bloc.state.recenterCount, 0);
      expect(bloc.state.isLocating, isFalse);
      expect(bloc.state.status, ObservationFormStatus.failure);
      expect(bloc.state.errorMessage, 'Sijaintia ei saatu.');
    });

    test('says nothing when the location is unavailable on opening', () async {
      final bloc = createBloc()..add(const ObservationFormLocationRequested());
      await settle();

      expect(bloc.state.position, isNull);
      expect(bloc.state.status, ObservationFormStatus.editing);
      expect(bloc.state.errorMessage, isNull);
    });

    test('uses the location found on opening without moving the map', () async {
      locationService.location = home;
      final bloc = createBloc()..add(const ObservationFormLocationRequested());
      await settle();
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 0);
    });

    test('moves to the last known location before the lookup ends', () async {
      locationService
        ..lastLocation = home
        ..pending = Completer<LatLng?>();
      final bloc = createBloc(initialPosition: elsewhere)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 1);
      expect(bloc.state.isLocating, isTrue);

      // A few metres off: not worth moving the map again.
      locationService.pending!.complete(const LatLng(60.17005, 24.94));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 1);
      expect(bloc.state.isLocating, isFalse);
    });

    test('moves again when the fresh location is elsewhere', () async {
      locationService
        ..lastLocation = elsewhere
        ..location = home;
      final bloc =
          createBloc()
            ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 2);
      expect(bloc.state.isLocating, isFalse);
    });

    test('stays at the last known location if the lookup fails', () async {
      locationService.lastLocation = home;
      final bloc = createBloc(initialPosition: elsewhere)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();

      expect(bloc.state.position, home);
      expect(bloc.state.recenterCount, 1);
      expect(bloc.state.isLocating, isFalse);
      expect(bloc.state.status, ObservationFormStatus.editing);
    });

    test('ignores another request while looking up the location', () async {
      locationService.pending = Completer<LatLng?>();
      final bloc = createBloc(initialPosition: elsewhere)
        ..add(const ObservationFormLocationRequested(recenter: true));
      await settle();
      expect(bloc.state.isLocating, isTrue);

      bloc.add(const ObservationFormLocationRequested(recenter: true));
      await settle();
      locationService.pending!.complete(home);
      await settle();

      expect(locationService.calls, 1);
      expect(bloc.state.recenterCount, 1);
      expect(bloc.state.isLocating, isFalse);
    });
  });
}
