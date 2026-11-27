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
  const ObservationListFilterChanged(this.type, {this.year, this.yardListId});

  final ObservationType type;
  final int? year;

  /// The yard list to show, when the user picks one.
  final String? yardListId;

  @override
  List<Object?> get props => [type, year, yardListId];
}

class ObservationListYardListsChanged extends ObservationListEvent {
  const ObservationListYardListsChanged(this.snapshot);

  final YardListsSnapshot snapshot;

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
