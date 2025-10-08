import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../core/repositories/observation_repository.dart';

part 'observation_list_event.dart';
part 'observation_list_state.dart';

class ObservationListBloc
    extends Bloc<ObservationListEvent, ObservationListState> {
  ObservationListBloc({required ObservationRepository observationRepository})
    : _observationRepository = observationRepository,
      super(const ObservationListState()) {
    on<ObservationListSubscriptionRequested>(_onSubscriptionRequested);
    on<ObservationListDataChanged>(_onDataChanged);
    on<ObservationListFilterChanged>(_onFilterChanged);
  }

  final ObservationRepository _observationRepository;
  StreamSubscription<List<Observation>>? _subscription;

  Future<void> _onSubscriptionRequested(
    ObservationListSubscriptionRequested event,
    Emitter<ObservationListState> emit,
  ) async {
    emit(state.copyWith(status: ObservationListStatus.loading));
    await _subscription?.cancel();
    _subscription = _observationRepository.watchAll().listen(
      (observations) => add(ObservationListDataChanged(observations)),
    );
    add(ObservationListDataChanged(_observationRepository.getAll()));
  }

  void _onDataChanged(
    ObservationListDataChanged event,
    Emitter<ObservationListState> emit,
  ) {
    int? targetYear;
    if (state.filterType == ObservationType.yearly) {
      targetYear = state.selectedYear;
      if (targetYear == null) {
        final yearlyObservations =
            event.observations
                .where(
                  (observation) =>
                      observation.type == ObservationType.yearly &&
                      observation.timestamp != null,
                )
                .toList();
        if (yearlyObservations.isNotEmpty) {
          yearlyObservations.sort(
            (a, b) => b.timestamp!.compareTo(a.timestamp!),
          );
          targetYear = yearlyObservations.first.timestamp!.year;
        } else {
          targetYear = DateTime.now().year;
        }
      }
    }
    final filtered = _applyFilter(
      event.observations,
      state.filterType,
      targetYear,
    );
    emit(
      state.copyWith(
        status: ObservationListStatus.ready,
        observations: event.observations,
        visibleObservations: filtered,
        selectedYear: targetYear,
        clearSelectedYear:
            state.filterType == ObservationType.yearly ? false : true,
      ),
    );
  }

  void _onFilterChanged(
    ObservationListFilterChanged event,
    Emitter<ObservationListState> emit,
  ) {
    final year =
        event.type == ObservationType.yearly
            ? (event.year ?? state.selectedYear ?? DateTime.now().year)
            : null;
    final filtered = _applyFilter(state.observations, event.type, year);
    emit(
      state.copyWith(
        filterType: event.type,
        selectedYear: year,
        clearSelectedYear: event.type == ObservationType.yearly ? false : true,
        visibleObservations: filtered,
      ),
    );
  }

  List<Observation> _applyFilter(
    List<Observation> observations,
    ObservationType type,
    int? year,
  ) {
    final filtered = <Observation>[];
    final seenSpeciesIds = <String>{};
    for (final observation in observations) {
      if (observation.type != type) {
        continue;
      }
      if (type == ObservationType.yearly) {
        if (observation.timestamp == null) {
          continue; // Skip yearly observations without timestamp
        }
        final targetYear = year ?? DateTime.now().year;
        if (observation.timestamp!.year != targetYear) {
          continue;
        }
      }
      final speciesId = observation.species.id;
      if (seenSpeciesIds.contains(speciesId)) {
        continue;
      }
      seenSpeciesIds.add(speciesId);
      filtered.add(observation);
    }
    return filtered;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
