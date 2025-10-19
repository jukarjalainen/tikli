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
  const ObservationListFilterChanged(this.type, {this.year});

  final ObservationType type;
  final int? year;

  @override
  List<Object?> get props => [type, year];
}

class ObservationListObservationDeleted extends ObservationListEvent {
  const ObservationListObservationDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
