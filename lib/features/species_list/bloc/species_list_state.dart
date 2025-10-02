part of 'species_list_bloc.dart';

enum SpeciesListStatus { initial, loading, ready, failure }

class SpeciesListState extends Equatable {
  const SpeciesListState({
    this.status = SpeciesListStatus.initial,
    this.species = const [],
    this.selectedSpeciesIds = const <String>{},
    this.errorMessage,
  });

  final SpeciesListStatus status;
  final List<Species> species;
  final Set<String> selectedSpeciesIds;
  final String? errorMessage;

  SpeciesListState copyWith({
    SpeciesListStatus? status,
    List<Species>? species,
    Set<String>? selectedSpeciesIds,
    String? errorMessage,
  }) {
    return SpeciesListState(
      status: status ?? this.status,
      species: species ?? this.species,
      selectedSpeciesIds: selectedSpeciesIds ?? this.selectedSpeciesIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    species,
    selectedSpeciesIds,
    errorMessage,
  ];

  bool get hasSelection => selectedSpeciesIds.isNotEmpty;
}
