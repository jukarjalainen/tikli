// Data model representing a bird species. 
// Used across the application for identification and listing purposes.

import 'package:equatable/equatable.dart';

class Species extends Equatable {
  const Species({required this.id, required this.commonName});

  final String id;
  final String commonName;

  @override
  List<Object?> get props => [id, commonName];
}
