import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/species.dart';
import '../../../core/repositories/observation_repository.dart';

part 'observation_form_event.dart';
part 'observation_form_state.dart';

class ObservationFormBloc
    extends Bloc<ObservationFormEvent, ObservationFormState> {
  ObservationFormBloc({
    required ObservationRepository observationRepository,
    required List<Species> selectedSpecies,
    LatLng? initialPosition,
    DateTime? initialTimestamp,
  }) : _observationRepository = observationRepository,
       super(
         ObservationFormState(
           selectedSpecies: selectedSpecies,
           position: initialPosition ?? const LatLng(60.1699, 24.9384),
           timestamp: initialTimestamp ?? DateTime.now(),
         ),
       ) {
    on<ObservationTypeToggled>(_onTypeToggled);
    on<ObservationFormTimestampChanged>(_onTimestampChanged);
    on<ObservationFormTimestampCleared>(_onTimestampCleared);
    on<ObservationFormLocationChanged>(_onLocationChanged);
    on<ObservationFormLocationCleared>(_onLocationCleared);
    on<ObservationFormAddressChanged>(_onAddressChanged);
    on<ObservationFormNotesChanged>(_onNotesChanged);
    on<ObservationFormSpeciesRemoved>(_onSpeciesRemoved);
    on<ObservationFormSubmitted>(_onSubmitted);
  }

  final ObservationRepository _observationRepository;

  void _onTypeToggled(
    ObservationTypeToggled event,
    Emitter<ObservationFormState> emit,
  ) {
    final updated = Set<ObservationType>.from(state.selectedTypes);
    if (updated.contains(event.type)) {
      updated.remove(event.type);
    } else {
      updated.add(event.type);
    }
    emit(state.copyWith(selectedTypes: updated));
  }

  void _onTimestampChanged(
    ObservationFormTimestampChanged event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(timestamp: event.timestamp));
  }

  void _onTimestampCleared(
    ObservationFormTimestampCleared event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(clearTimestamp: true));
  }

  void _onLocationChanged(
    ObservationFormLocationChanged event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(position: event.position));
  }

  void _onLocationCleared(
    ObservationFormLocationCleared event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(clearPosition: true, clearAddress: true));
  }

  void _onAddressChanged(
    ObservationFormAddressChanged event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(address: event.address));
  }

  void _onNotesChanged(
    ObservationFormNotesChanged event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  void _onSpeciesRemoved(
    ObservationFormSpeciesRemoved event,
    Emitter<ObservationFormState> emit,
  ) {
    final updated = List<Species>.from(state.selectedSpecies);
    if (!updated.remove(event.species)) {
      return;
    }
    emit(state.copyWith(selectedSpecies: updated));
  }

  Future<void> _onSubmitted(
    ObservationFormSubmitted event,
    Emitter<ObservationFormState> emit,
  ) async {
    if (state.selectedSpecies.isEmpty) {
      emit(
        state.copyWith(
          status: ObservationFormStatus.failure,
          errorMessage: 'Valitse vahintaan yksi laji.',
        ),
      );
      return;
    }
    if (state.selectedTypes.isEmpty) {
      emit(
        state.copyWith(
          status: ObservationFormStatus.failure,
          errorMessage: 'Valitse vahintaan yksi pinnatyyppi.',
        ),
      );
      return;
    }

    // Validate: yearly observations require a timestamp
    if (state.selectedTypes.contains(ObservationType.yearly) &&
        state.timestamp == null) {
      emit(
        state.copyWith(
          status: ObservationFormStatus.failure,
          errorMessage: 'Vuodenpinnat vaativat havaintoajan.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ObservationFormStatus.saving));
    try {
      final lifeSpeciesIds =
          _observationRepository
              .getAll()
              .where((observation) => observation.type == ObservationType.life)
              .map((observation) => observation.species.id)
              .toSet();
      for (final species in state.selectedSpecies) {
        final typesToSave = Set<ObservationType>.from(state.selectedTypes);
        final requiresLifeEntry =
            (typesToSave.contains(ObservationType.yearly) ||
                typesToSave.contains(ObservationType.yard)) &&
            !typesToSave.contains(ObservationType.life) &&
            !lifeSpeciesIds.contains(species.id);
        if (requiresLifeEntry) {
          typesToSave.add(ObservationType.life);
        }
        for (final type in typesToSave) {
          await _observationRepository.addObservation(
            species: species,
            type: type,
            timestamp: state.timestamp,
            position: state.position,
            address:
                state.address?.trim().isEmpty == true ? null : state.address,
            notes: state.notes?.trim().isEmpty == true ? null : state.notes,
          );
          if (type == ObservationType.life) {
            lifeSpeciesIds.add(species.id);
          }
        }
      }
      emit(state.copyWith(status: ObservationFormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: ObservationFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
