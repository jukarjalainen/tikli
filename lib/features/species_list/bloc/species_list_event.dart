part of 'species_list_bloc.dart';

abstract class SpeciesListEvent extends Equatable {
  const SpeciesListEvent();

  @override
  List<Object?> get props => const [];
}

class SpeciesListRequested extends SpeciesListEvent {
  const SpeciesListRequested();
}

class SpeciesSelectionToggled extends SpeciesListEvent {
  const SpeciesSelectionToggled(this.speciesId);

  final String speciesId;

  @override
  List<Object?> get props => [speciesId];
}

class SpeciesSelectionCleared extends SpeciesListEvent {
  const SpeciesSelectionCleared();
}
