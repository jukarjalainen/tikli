// BLoC managing the state and logic of the observation input form.
// Handles validation, duplicate prevention, and formatting before saving via ObservationRepository.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/enums/observation_type.dart';
import '../../../core/models/species.dart';
import '../../../core/repositories/observation_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/reverse_geocoding_service.dart';

part 'observation_form_event.dart';
part 'observation_form_state.dart';

class ObservationFormBloc
    extends Bloc<ObservationFormEvent, ObservationFormState> {
  ObservationFormBloc({
    required ObservationRepository observationRepository,
    required LocationService locationService,
    required List<Species> selectedSpecies,
    LatLng? initialPosition,
    DateTime? initialTimestamp,
  }) : _observationRepository = observationRepository,
       _locationService = locationService,
       super(
         ObservationFormState(
           selectedSpecies: selectedSpecies,
           position: initialPosition,
           timestamp: initialTimestamp ?? DateTime.now(),
         ),
       ) {
    on<ObservationFormLocationRequested>(_onLocationRequested);
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
  final LocationService _locationService;
  final ReverseGeocodingService _reverseGeocodingService =
      ReverseGeocodingService();

  Future<void> _onLocationRequested(
    ObservationFormLocationRequested event,
    Emitter<ObservationFormState> emit,
  ) async {
    final resolved = await _locationService.getCurrentLocation();
    if (resolved == null) {
      return;
    }
    if (state.position == resolved) {
      return;
    }
    emit(state.copyWith(position: resolved));
  }

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

  // when location is changed (either by GPS or manually), we want to update the address using reverse geocoding
  Future<void> _onLocationChanged(
    ObservationLocationChanged event,
    Emitter<ObservationFormState> emit,
  ) async {
    // 1. update the position in the state immediately so that the UI can reflect the new location (e.g. on map preview)
    emit(state.copyWith(position: event.position));

    // 2. get the municipality for the new coordinates using reverse geocoding and update the state with the new address
    try {
      final address = await _reverseGeocodingService.getAddressFromCoordinates(
        event.position,
      );
      if (address != null) {
        // update the state with the new address, but only if the position hasn't changed again in the meantime (to avoid showing wrong address if user quickly changes location multiple times)
        emit(state.copyWith(address: address));
      }
    } catch (_) {
      // if the reverse geocoding fails for any reason, we can choose to either keep the old address or clear it. Here we choose to keep the old address to avoid losing potentially valid location info.
    }
  }

  void _onLocationCleared(
    ObservationFormLocationCleared event,
    Emitter<ObservationFormState> emit,
  ) {
    emit(state.copyWith(clearPosition: true, clearAddress: true));
  }

  void _onAddressChanged(
    ObservationAddressChanged event,
    Emitter<ObservationFormState> emit,
  ) {
    // updating the address in the state immediately without reverse geocoding, since we assume that if user is manually entering an address, they know what they are doing and don't need the app to validate it by looking up coordinates
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
          errorMessage: 'Valitse vähintään yksi laji.',
        ),
      );
      return;
    }
    if (state.selectedTypes.isEmpty) {
      emit(
        state.copyWith(
          status: ObservationFormStatus.failure,
          errorMessage: 'Valitse vähintään yksi pinnatyyppi.',
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
      // Haetaan kaikki jo tallennetut havainnot vertailua varten
      final allObservations = _observationRepository.getAll();

      for (final species in state.selectedSpecies) {
        final typesToSave = Set<ObservationType>.from(state.selectedTypes);

        // Etsitään tälle kyseiselle lajille jo olemassa olevat havainnot
        final existingObs =
            allObservations.where((o) => o.species.id == species.id).toList();

        // 1. Poista elis tallennettavista, jos se on jo havaittu
        if (existingObs.any((o) => o.type == ObservationType.life)) {
          typesToSave.remove(ObservationType.life);
        }

        // 2. Poista pihapinna tallennettavista, jos se on jo havaittu
        if (existingObs.any((o) => o.type == ObservationType.yard)) {
          typesToSave.remove(ObservationType.yard);
        }

        // 3. Poista vuodenpinna, jos se on jo havaittu TÄNÄ VUONNA
        if (state.timestamp != null) {
          final currentYear = state.timestamp!.year;
          if (existingObs.any(
            (o) =>
                o.type == ObservationType.yearly &&
                o.timestamp?.year == currentYear,
          )) {
            typesToSave.remove(ObservationType.yearly);
          }
        }

        // Tarkistetaan, pitääkö lajille luoda automaattisesti myös elis.
        // (Jos käyttäjä valitsi vuosi- tai pihapinnan, mutta lajista ei ole elistä olemassa)
        final requiresLifeEntry =
            (state.selectedTypes.contains(ObservationType.yearly) ||
                state.selectedTypes.contains(ObservationType.yard)) &&
            !existingObs.any((o) => o.type == ObservationType.life);

        if (requiresLifeEntry) {
          typesToSave.add(ObservationType.life);
        }

        // Tallennetaan vain ne pinnat, joita listalla on jäljellä
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
