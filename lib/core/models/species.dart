// Data model representing a bird species. 
// Used across the application for identification and listing purposes.

import 'package:equatable/equatable.dart';

class Species extends Equatable {
  const Species({required this.id, required this.commonName});

  /// A species entered by the user because the species list does not have it.
  ///
  /// Only the id is stored with an observation, so it has to carry the name:
  /// see [Species.unlisted].
  factory Species.rare(String name) {
    return Species(
      id: '$_rareIdPrefix${name.toLowerCase().replaceAll(' ', '_')}',
      commonName: name,
    );
  }

  /// The species for a stored [id] that the species list does not have.
  ///
  /// A rare species gets its name back from the id, in lower case because the
  /// id does not record the original casing.
  factory Species.unlisted(String id) {
    final name =
        id.startsWith(_rareIdPrefix)
            ? id.substring(_rareIdPrefix.length).replaceAll('_', ' ')
            : _retiredNames[id];
    return Species(id: id, commonName: name ?? 'Tuntematon laji ($id)');
  }

  static const _rareIdPrefix = 'rare_';

  /// Species removed from the species list that may still have observations.
  /// Their ids must not be reused for other species.
  static const _retiredNames = {
    '120': 'Metsähanhi',
    '123': 'Mustahaikara',
    '240': 'Tundraurpiainen',
  };

  final String id;
  final String commonName;

  @override
  List<Object?> get props => [id, commonName];
}
