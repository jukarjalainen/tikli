part of 'observation_form_bloc.dart';

enum ObservationFormStatus { editing, saving, success, failure }

class ObservationFormState extends Equatable {
  ObservationFormState({
    required List<Species> selectedSpecies,
    this.position,
    this.timestamp,
    Set<ObservationType>? selectedTypes,
    this.address,
    this.status = ObservationFormStatus.editing,
    this.errorMessage,
  }) : selectedSpecies = List.unmodifiable(selectedSpecies),
       selectedTypes = selectedTypes ?? {ObservationType.yearly};

  final List<Species> selectedSpecies;
  final Set<ObservationType> selectedTypes;
  final LatLng? position;
  final DateTime? timestamp;
  final String? address;
  final ObservationFormStatus status;
  final String? errorMessage;

  ObservationFormState copyWith({
    List<Species>? selectedSpecies,
    Set<ObservationType>? selectedTypes,
    LatLng? position,
    bool clearPosition = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
    String? address,
    bool clearAddress = false,
    ObservationFormStatus? status,
    String? errorMessage,
  }) {
    return ObservationFormState(
      selectedSpecies:
          selectedSpecies != null
              ? List<Species>.unmodifiable(selectedSpecies)
              : this.selectedSpecies,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      position: clearPosition ? null : (position ?? this.position),
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      address: clearAddress ? null : (address ?? this.address),
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isSaving => status == ObservationFormStatus.saving;

  @override
  List<Object?> get props => [
    selectedSpecies,
    selectedTypes,
    position,
    timestamp,
    address,
    status,
    errorMessage,
  ];
}
