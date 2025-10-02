import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/species.dart';
import '../../../core/repositories/species_repository.dart';

part 'species_list_event.dart';
part 'species_list_state.dart';

class SpeciesListBloc extends Bloc<SpeciesListEvent, SpeciesListState> {
  SpeciesListBloc({required SpeciesRepository speciesRepository})
    : _speciesRepository = speciesRepository,
      super(const SpeciesListState()) {
    on<SpeciesListRequested>(_onRequested);
    on<SpeciesSelectionToggled>(_onSelectionToggled);
    on<SpeciesSelectionCleared>(_onSelectionCleared);
  }

  final SpeciesRepository _speciesRepository;

  Future<void> _onRequested(
    SpeciesListRequested event,
    Emitter<SpeciesListState> emit,
  ) async {
    emit(state.copyWith(status: SpeciesListStatus.loading));
    try {
      final species = await _speciesRepository.loadSpecies();
      emit(state.copyWith(status: SpeciesListStatus.ready, species: species));
    } catch (error) {
      emit(
        state.copyWith(
          status: SpeciesListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onSelectionToggled(
    SpeciesSelectionToggled event,
    Emitter<SpeciesListState> emit,
  ) {
    final updated = Set<String>.from(state.selectedSpeciesIds);
    if (updated.contains(event.speciesId)) {
      updated.remove(event.speciesId);
    } else {
      updated.add(event.speciesId);
    }
    emit(state.copyWith(selectedSpeciesIds: updated));
  }

  void _onSelectionCleared(
    SpeciesSelectionCleared event,
    Emitter<SpeciesListState> emit,
  ) {
    emit(state.copyWith(selectedSpeciesIds: <String>{}));
  }
}
