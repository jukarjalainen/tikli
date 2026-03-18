part of 'observation_form_bloc.dart';

abstract class ObservationFormEvent extends Equatable {
  const ObservationFormEvent();

  @override
  List<Object?> get props => const [];
}

class ObservationTypeToggled extends ObservationFormEvent {
  const ObservationTypeToggled(this.type);

  final ObservationType type;

  @override
  List<Object?> get props => [type];
}

class ObservationFormTimestampChanged extends ObservationFormEvent {
  const ObservationFormTimestampChanged(this.timestamp);

  final DateTime timestamp;

  @override
  List<Object?> get props => [timestamp];
}

class ObservationFormLocationRequested extends ObservationFormEvent {
  const ObservationFormLocationRequested();
}

class ObservationFormLocationChanged extends ObservationFormEvent {
  const ObservationFormLocationChanged(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

class ObservationFormAddressChanged extends ObservationFormEvent {
  const ObservationFormAddressChanged(this.address);

  final String address;

  @override
  List<Object?> get props => [address];
}

class ObservationFormNotesChanged extends ObservationFormEvent {
  const ObservationFormNotesChanged(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

class ObservationFormTimestampCleared extends ObservationFormEvent {
  const ObservationFormTimestampCleared();
}

class ObservationFormLocationCleared extends ObservationFormEvent {
  const ObservationFormLocationCleared();
}

class ObservationFormSpeciesRemoved extends ObservationFormEvent {
  const ObservationFormSpeciesRemoved(this.species);

  final Species species;

  @override
  List<Object?> get props => [species];
}

class ObservationFormSubmitted extends ObservationFormEvent {
  const ObservationFormSubmitted();
}

class ObservationLocationChanged extends ObservationFormEvent {
  const ObservationLocationChanged(this.position);
  final LatLng position;

  @override
  List<Object?> get props => [position];
}

class ObservationAddressChanged extends ObservationFormEvent {
  const ObservationAddressChanged(this.address);
  final String address;

  @override
  List<Object?> get props => [address];
}