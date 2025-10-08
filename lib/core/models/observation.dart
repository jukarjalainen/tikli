import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../enums/observation_type.dart';
import 'species.dart';

class Observation extends Equatable {
  const Observation({
    required this.id,
    required this.species,
    required this.type,
    this.timestamp,
    this.position,
    this.notes,
    this.address,
  });

  final String id;
  final Species species;
  final ObservationType type;
  final DateTime? timestamp;
  final LatLng? position;
  final String? address;
  final String? notes;

  Observation copyWith({
    String? id,
    Species? species,
    ObservationType? type,
    DateTime? timestamp,
    LatLng? position,
    String? address,
    String? notes,
  }) {
    return Observation(
      id: id ?? this.id,
      species: species ?? this.species,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      position: position ?? this.position,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    species,
    type,
    timestamp,
    position,
    address,
    notes,
  ];
}
