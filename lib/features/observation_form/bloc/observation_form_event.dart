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

/// Looks up the user's current location and uses it as the position.
class ObservationFormLocationRequested extends ObservationFormEvent {
  const ObservationFormLocationRequested({this.recenter = false});

  /// Whether the user asked for this, so the map should move to the location
  /// and a failure should be reported. The lookup made when the form opens
  /// leaves this false.
  final bool recenter;

  @override
  List<Object?> get props => [recenter];
}

class ObservationFormLocationChanged extends ObservationFormEvent {
  const ObservationFormLocationChanged(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

class ObservationFormmunicipalityChanged extends ObservationFormEvent {
  const ObservationFormmunicipalityChanged(this.municipality);

  final String municipality;

  @override
  List<Object?> get props => [municipality];
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

/// Picks the custom list the observation is saved to.
class ObservationFormCustomListSelected extends ObservationFormEvent {
  const ObservationFormCustomListSelected(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Creates a custom list named [name] and picks it.
class ObservationFormCustomListAdded extends ObservationFormEvent {
  const ObservationFormCustomListAdded(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}
