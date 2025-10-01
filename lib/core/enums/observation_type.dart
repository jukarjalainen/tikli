enum ObservationType { yearly, yard, life }

extension ObservationTypeTitle on ObservationType {
  String get label {
    switch (this) {
      case ObservationType.yearly:
        return 'Vuodenpinna';
      case ObservationType.yard:
        return 'Pihapinna';
      case ObservationType.life:
        return 'Elamanpinna';
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
