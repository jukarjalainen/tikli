import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tikli/core/enums/observation_type.dart';
import 'package:tikli/core/repositories/yard_list_repository.dart';
import 'package:tikli/core/services/location_service.dart';
import 'package:tikli/core/services/reverse_geocoding_service.dart';
import 'package:tikli/features/observation_form/bloc/observation_form_bloc.dart';

import '../helpers/observation_fakes.dart';

class _FakeLocationService extends Fake implements LocationService {}

class _FakeReverseGeocodingService extends Fake
    implements ReverseGeocodingService {
  @override
  Future<String?> lookupDescription(LatLng position) async => null;
}

void main() {
  late FakeObservationRepository observations;
  late YardListRepository yardLists;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ObservationFormBloc createBloc() {
    final bloc = ObservationFormBloc(
      observationRepository: observations,
      yardListRepository: yardLists,
      locationService: _FakeLocationService(),
      reverseGeocodingService: _FakeReverseGeocodingService(),
      selectedSpecies: const [talitiainen],
      initialTimestamp: DateTime(2026, 6, 1),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  /// Saves talitiainen as a yard observation only, after [prepare] has had
  /// its say on the form.
  Future<ObservationFormBloc> saveYardObservation({
    void Function(ObservationFormBloc bloc)? prepare,
  }) async {
    final bloc = createBloc()
      ..add(const ObservationTypeToggled(ObservationType.yearly));
    if (prepare != null) {
      prepare(bloc);
    } else {
      bloc.add(const ObservationTypeToggled(ObservationType.yard));
    }
    await settle();
    bloc.add(const ObservationFormSubmitted());
    await settle();
    await settle();
    expect(bloc.state.status, ObservationFormStatus.success);
    return bloc;
  }

  List<String?> yardListIdsOfYardObservations() => [
    for (final obs in observations.getAll())
      if (obs.type == ObservationType.yard) obs.yardListId,
  ];

  setUp(() async {
    observations = FakeObservationRepository();
    yardLists = fakeYardListRepository(yardLists: [koti, mokki]);
    await settle();
  });

  tearDown(() {
    observations.dispose();
    yardLists.dispose();
  });

  test('offers every yard list and preselects the last used one', () {
    final bloc = createBloc();

    expect(bloc.state.yardLists, [koti, mokki]);
    expect(bloc.state.selectedYardList, koti);
  });

  test('saves a yard observation to the preselected yard list', () async {
    await saveYardObservation();

    expect(yardListIdsOfYardObservations(), ['default']);
  });

  test('picking a yard list ticks the yard list type', () async {
    final bloc = createBloc()..add(const ObservationFormYardListSelected('mokki'));
    await settle();

    expect(bloc.state.selectedYardListId, 'mokki');
    expect(bloc.state.selectedTypes, contains(ObservationType.yard));
  });

  test('saves to the picked yard list and preselects it next time', () async {
    await saveYardObservation(
      prepare: (bloc) => bloc.add(const ObservationFormYardListSelected('mokki')),
    );

    expect(yardListIdsOfYardObservations(), ['mokki']);
    expect(yardLists.current!.activeId, 'mokki');
    expect(createBloc().state.selectedYardList, mokki);
  });

  test('saves a species once per yard list', () async {
    await saveYardObservation();
    await saveYardObservation();
    expect(yardListIdsOfYardObservations(), ['default']);

    await saveYardObservation(
      prepare: (bloc) => bloc.add(const ObservationFormYardListSelected('mokki')),
    );

    expect(yardListIdsOfYardObservations(), ['default', 'mokki']);
    expect(
      observations.getAll().where((obs) => obs.type == ObservationType.life),
      hasLength(1),
    );
  });

  test('adds a new yard list and saves to it', () async {
    await saveYardObservation(
      prepare: (bloc) => bloc.add(const ObservationFormYardListAdded('Saari')),
    );

    final saari = yardLists.current!.lists.last;
    expect(saari.name, 'Saari');
    expect(yardListIdsOfYardObservations(), [saari.id]);
    expect(yardLists.current!.activeId, saari.id);
  });

  test('reports a taken yard list name', () async {
    final bloc = createBloc()..add(const ObservationFormYardListAdded('mökki'));
    await settle();
    await settle();

    expect(bloc.state.errorMessage, 'Pihapinna "mökki" on jo olemassa.');
    expect(yardLists.current!.lists, [koti, mokki]);
    expect(bloc.state.selectedYardListId, 'default');
  });
}
