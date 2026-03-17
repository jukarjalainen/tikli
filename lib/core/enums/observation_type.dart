enum ObservationType { yearly, yard, life }

extension ObservationTypeTitle on ObservationType {
  String get label {
    switch (this) {
      case ObservationType.yearly:
        return 'Vuodenpinna';
      case ObservationType.yard:
        return 'Pihapinna';
      case ObservationType.life:
        return 'Elämänpinna';
    }
  }

  String get storageKey {
    switch (this) {
      case ObservationType.yearly:
        return 'yearly';
      case ObservationType.yard:
        return 'yard';
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
      case 'yard':
        return ObservationType.yard;
      case 'life':
        return ObservationType.life;
      default:
        throw ArgumentError('Invalid storage key for ObservationType: $key');
    }
  }
}
