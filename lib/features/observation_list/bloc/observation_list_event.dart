part of 'observation_list_bloc.dart';

abstract class ObservationListEvent extends Equatable {
  const ObservationListEvent();

  @override
  List<Object?> get props => const [];
}

class ObservationListSubscriptionRequested extends ObservationListEvent {
  const ObservationListSubscriptionRequested();
}

class ObservationListDataChanged extends ObservationListEvent {
  const ObservationListDataChanged(this.observations);

  final List<Observation> observations;

  @override
  List<Object?> get props => [observations];
}

class ObservationListFilterChanged extends ObservationListEvent {
  const ObservationListFilterChanged(this.type, {this.year, this.customListId});

  final ObservationType type;
  final int? year;

  /// The custom list to show, when the user picks one.
  final String? customListId;

  @override
  List<Object?> get props => [type, year, customListId];
}

class ObservationListCustomListsChanged extends ObservationListEvent {
  const ObservationListCustomListsChanged(this.snapshot);

  final CustomListsSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// Asks the bloc to check whether the calendar year has changed.
class ObservationListYearCheckRequested extends ObservationListEvent {
  const ObservationListYearCheckRequested();
}

class ObservationListObservationDeleted extends ObservationListEvent {
  const ObservationListObservationDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
