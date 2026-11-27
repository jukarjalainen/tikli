/// The list an observation belongs to. Every user has the yearly and life
/// lists. [custom] observations belong to a list the user named, see
/// `Observation.customListId`.
enum ObservationType { yearly, life, custom }

extension ObservationTypeTitle on ObservationType {
  String get label {
    switch (this) {
      case ObservationType.yearly:
        return 'Vuodenpinna';
      case ObservationType.custom:
        return 'Oma lista';
      case ObservationType.life:
        return 'Elämänpinna';
    }
  }

  String get storageKey {
    switch (this) {
      case ObservationType.yearly:
        return 'yearly';
      case ObservationType.custom:
        return 'custom';
      case ObservationType.life:
        return 'life';
    }
  }
}

extension ObservationTypeParser on ObservationType {
  // Factory method to parse ObservationType from a storage key
  static ObservationType fromStorageKey(String key) {
    switch (key) {
      case 'yearly':
        return ObservationType.yearly;
      case 'custom':
        return ObservationType.custom;
      case 'life':
        return ObservationType.life;
      default:
        throw ArgumentError('Invalid storage key for ObservationType: $key');
    }
  }
}
