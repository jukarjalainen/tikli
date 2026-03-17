import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

// Ensure the ObservationTypeParser extension is explicitly imported
import '../enums/observation_type.dart';
import 'species.dart';

class Observation extends Equatable {
  // Constructor for creating an Observation object
  const Observation({
    required this.id, // Unique identifier for the observation
    required this.species, // The species being observed
    required this.type, // The type/category of the observation
    this.timestamp, // Optional timestamp for when the observation occurred
    this.position, // Optional geographical position (latitude and longitude)
    this.notes, // Optional notes about the observation
    this.address, // Optional address or location description
  });

  // Fields representing the properties of an observation
  final String id; // Unique ID for the observation
  final Species species; // The species associated with the observation
  final ObservationType type; // The type of observation (e.g., sighting, sound)
  final DateTime? timestamp; // The date and time of the observation
  final LatLng? position; // The geographical position of the observation
  final String? address; // The address or description of the location
  final String? notes; // Additional notes about the observation

  // Method to create a copy of the current Observation with modified fields
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
      id:
          id ??
          this.id, // Use the new ID if provided, otherwise keep the current ID
      species: species ?? this.species, // Use the new species if provided
      type: type ?? this.type, // Use the new type if provided
      timestamp:
          timestamp ?? this.timestamp, // Use the new timestamp if provided
      position: position ?? this.position, // Use the new position if provided
      address: address ?? this.address, // Use the new address if provided
      notes: notes ?? this.notes, // Use the new notes if provided
    );
  }

  // Equatable props to enable value comparison for Observation objects
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

  // Converts the Observation object into a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Store the observation ID
      'speciesId': species.id, // Store only the species ID
      'type': type.storageKey, // Store the type identifier
      'timestamp':
          timestamp?.toIso8601String(), // Convert timestamp to ISO 8601 string
      'latitude': position?.latitude, // Store latitude if position is available
      'longitude':
          position?.longitude, // Store longitude if position is available
      'address': address, // Store the address
      'notes': notes, // Store the notes
    };
  }

  // Factory method to create an Observation object from a map
  factory Observation.fromMap(Map<String, dynamic> map, Species species) {
    return Observation(
      id: map['id'] as String,
      species: species,
      type: ObservationTypeParser.fromStorageKey(map['type'] as String),
      timestamp:
          map['timestamp'] != null
              ? DateTime.parse(map['timestamp'] as String)
              : null,
      position:
          map['latitude'] != null && map['longitude'] != null
              ? LatLng(map['latitude'] as double, map['longitude'] as double)
              : null,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
