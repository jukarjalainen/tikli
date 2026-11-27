part of 'observation_form_bloc.dart';

enum ObservationFormStatus { editing, saving, success, failure }

class ObservationFormState extends Equatable {
  ObservationFormState({
    required List<Species> selectedSpecies,
    this.position,
    this.timestamp,
    Set<ObservationType>? selectedTypes,
    this.municipality,
    this.customLists = const [],
    this.selectedCustomListId,
    this.status = ObservationFormStatus.editing,
    this.errorMessage,
    this.isLocating = false,
    this.recenterCount = 0,
  }) : selectedSpecies = List.unmodifiable(selectedSpecies),
       selectedTypes = selectedTypes ?? {ObservationType.yearly};

  final List<Species> selectedSpecies;
  final Set<ObservationType> selectedTypes;
  final LatLng? position;
  final DateTime? timestamp;
  final String? municipality;

  /// The custom lists to pick from, oldest first.
  final List<CustomList> customLists;

  /// The custom list the observation is saved to, if any.
  final String? selectedCustomListId;
  final ObservationFormStatus status;
  final String? errorMessage;

  /// Whether a location lookup the user asked for is in progress.
  final bool isLocating;

  /// Goes up by one each time a location lookup the user asked for finishes,
  /// telling the map to move to [position].
  final int recenterCount;

  ObservationFormState copyWith({
    List<Species>? selectedSpecies,
    Set<ObservationType>? selectedTypes,
    LatLng? position,
    bool clearPosition = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
    String? municipality,
    bool clearmunicipality = false,
    List<CustomList>? customLists,
    String? selectedCustomListId,
    ObservationFormStatus? status,
    String? errorMessage,
    bool? isLocating,
    int? recenterCount,
  }) {
    return ObservationFormState(
      selectedSpecies:
          selectedSpecies != null
              ? List<Species>.unmodifiable(selectedSpecies)
              : this.selectedSpecies,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      position: clearPosition ? null : (position ?? this.position),
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      municipality:
          clearmunicipality ? null : (municipality ?? this.municipality),
      customLists: customLists ?? this.customLists,
      selectedCustomListId: selectedCustomListId ?? this.selectedCustomListId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isLocating: isLocating ?? this.isLocating,
      recenterCount: recenterCount ?? this.recenterCount,
    );
  }

  bool get isSaving => status == ObservationFormStatus.saving;

  CustomList? get selectedCustomList {
    for (final list in customLists) {
      if (list.id == selectedCustomListId) return list;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    selectedSpecies,
    selectedTypes,
    position,
    timestamp,
    municipality,
    customLists,
    selectedCustomListId,
    status,
    errorMessage,
    isLocating,
    recenterCount,
  ];
}
