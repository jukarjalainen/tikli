// BLoC (Business Logic Component) managing the state of the observation list.
// Listens to the ObservationRepository stream and updates the UI state when data changes.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../core/models/custom_list.dart';
import '../../../core/repositories/observation_repository.dart';
import '../../../core/repositories/custom_list_repository.dart';
import '../../../core/utils/clock.dart';

part 'observation_list_event.dart';
part 'observation_list_state.dart';

class ObservationListBloc
    extends Bloc<ObservationListEvent, ObservationListState> {
  ObservationListBloc({
    required ObservationRepository observationRepository,
    required CustomListRepository customListRepository,
    Clock clock = DateTime.now,
  }) : _observationRepository = observationRepository,
       _customListRepository = customListRepository,
       _clock = clock,
       super(ObservationListState(currentYear: clock().year)) {
    on<ObservationListSubscriptionRequested>(_onSubscriptionRequested);
    on<ObservationListDataChanged>(_onDataChanged);
    on<ObservationListCustomListsChanged>(_onCustomListsChanged);
    on<ObservationListFilterChanged>(_onFilterChanged);
    on<ObservationListYearCheckRequested>(_onYearCheckRequested);
    on<ObservationListObservationDeleted>(_onObservationDeleted);
  }

  final ObservationRepository _observationRepository;
  final CustomListRepository _customListRepository;
  final Clock _clock;
  StreamSubscription<List<Observation>>? _subscription;
  StreamSubscription<CustomListsSnapshot>? _customListsSubscription;

  Future<void> _onSubscriptionRequested(
    ObservationListSubscriptionRequested event,
    Emitter<ObservationListState> emit,
  ) async {
    emit(state.copyWith(status: ObservationListStatus.loading));
    await _subscription?.cancel();
    await _customListsSubscription?.cancel();
    _subscription = _observationRepository.watchAll().listen(
      (observations) => add(ObservationListDataChanged(observations)),
    );
    _customListsSubscription = _customListRepository.watch().listen(
      (snapshot) => add(ObservationListCustomListsChanged(snapshot)),
    );
    add(ObservationListDataChanged(_observationRepository.getAll()));
  }

  void _onDataChanged(
    ObservationListDataChanged event,
    Emitter<ObservationListState> emit,
  ) {
    emit(
      _withResolvedYears(
        state.copyWith(
          status: ObservationListStatus.ready,
          observations: event.observations,
        ),
      ),
    );
  }

  void _onCustomListsChanged(
    ObservationListCustomListsChanged event,
    Emitter<ObservationListState> emit,
  ) {
    final activeChanged = event.snapshot.activeId != state.activeCustomListId;
    final next = state.copyWith(
      customLists: event.snapshot.lists,
      activeCustomListId: event.snapshot.activeId,
      // A newly chosen active list is shown right away.
      clearSelectedCustomList: activeChanged,
    );
    emit(_withResolvedYears(_withResolvedCustomList(next)));
  }

  void _onFilterChanged(
    ObservationListFilterChanged event,
    Emitter<ObservationListState> emit,
  ) {
    emit(
      _withResolvedCustomList(
        _withResolvedYears(
          state.copyWith(filterType: event.type),
          requestedYear: event.year,
        ),
        requestedCustomListId: event.customListId,
      ),
    );
  }

  void _onYearCheckRequested(
    ObservationListYearCheckRequested event,
    Emitter<ObservationListState> emit,
  ) {
    emit(_withResolvedYears(state));
  }

  /// Brings [next] up to date with the clock and picks the selected year.
  ///
  /// The selection follows the current year, so a new list starts when the year
  /// changes. An older year stays selected while the user is browsing it and it
  /// still has observations. [requestedYear] is a year the user just picked.
  ObservationListState _withResolvedYears(
    ObservationListState next, {
    int? requestedYear,
  }) {
    final dated = next.copyWith(currentYear: _clock().year);
    if (dated.filterType != ObservationType.yearly) {
      return dated.copyWith(clearSelectedYear: true);
    }
    final browsedYear =
        next.selectedYear == state.currentYear ? null : next.selectedYear;
    final year = requestedYear ?? browsedYear;
    return dated.copyWith(
      selectedYear:
          dated.availableYears.contains(year) ? year : dated.currentYear,
    );
  }

  /// Picks the custom list [next] shows.
  ///
  /// The active list is shown unless the user is browsing another list that
  /// still exists. [requestedCustomListId] is a list the user just picked.
  ObservationListState _withResolvedCustomList(
    ObservationListState next, {
    String? requestedCustomListId,
  }) {
    final id = requestedCustomListId ?? next.selectedCustomListId;
    final exists = next.customLists.any((list) => list.id == id);
    if (id == null || !exists || id == next.activeCustomListId) {
      return next.copyWith(clearSelectedCustomList: true);
    }
    return next.copyWith(selectedCustomListId: id);
  }

  Future<void> _onObservationDeleted(
    ObservationListObservationDeleted event,
    Emitter<ObservationListState> emit,
  ) async {
    await _observationRepository.deleteObservation(event.id);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _customListsSubscription?.cancel();
    return super.close();
  }
}
