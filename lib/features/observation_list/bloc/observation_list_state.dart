part of 'observation_list_bloc.dart';

enum ObservationListStatus { initial, loading, ready, empty, failure }

class ObservationListState extends Equatable {
  const ObservationListState({
    required this.currentYear,
    this.status = ObservationListStatus.initial,
    this.observations = const [],
    this.filterType = ObservationType.yearly,
    this.selectedYear,
    this.yardLists = const [],
    this.activeYardListId,
    this.selectedYardListId,
    this.errorMessage,
  });

  /// The calendar year whose yearly list is open for new observations.
  final int currentYear;
  final ObservationListStatus status;
  final List<Observation> observations;
  final ObservationType filterType;
  final int? selectedYear;

  /// All yard lists, oldest first.
  final List<YardList> yardLists;

  /// The yard list last saved to, shown on the yard list page by default.
  final String? activeYardListId;

  /// Another yard list the user is browsing, or null for the active one.
  final String? selectedYardListId;
  final String? errorMessage;

  ObservationListState copyWith({
    int? currentYear,
    ObservationListStatus? status,
    List<Observation>? observations,
    ObservationType? filterType,
    int? selectedYear,
    bool clearSelectedYear = false,
    List<YardList>? yardLists,
    String? activeYardListId,
    String? selectedYardListId,
    bool clearSelectedYardList = false,
    String? errorMessage,
  }) {
    return ObservationListState(
      currentYear: currentYear ?? this.currentYear,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      filterType: filterType ?? this.filterType,
      selectedYear:
          clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      yardLists: yardLists ?? this.yardLists,
      activeYardListId: activeYardListId ?? this.activeYardListId,
      selectedYardListId:
          clearSelectedYardList
              ? null
              : (selectedYardListId ?? this.selectedYardListId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// The year the yearly list shows.
  int get shownYear => selectedYear ?? currentYear;

  /// The id of the yard list the yard list page shows.
  String? get shownYardListId => selectedYardListId ?? activeYardListId;

  YardList? yardListById(String? id) {
    for (final list in yardLists) {
      if (list.id == id) return list;
    }
    return null;
  }

  /// The yard list the yard list page shows.
  YardList? get shownYardList => yardListById(shownYardListId);

  /// The yard list new yard observations go to.
  YardList? get activeYardList => yardListById(activeYardListId);

  /// Every list the observations menu offers, in page order: the yearly list,
  /// each yard list, then the life list.
  List<ObservationListChoice> get listChoices => [
    const ObservationListChoice(ObservationType.yearly),
    if (yardLists.isEmpty)
      const ObservationListChoice(ObservationType.yard)
    else
      for (final list in yardLists)
        ObservationListChoice(ObservationType.yard, yardList: list),
    const ObservationListChoice(ObservationType.life),
  ];

  /// The list the page of [type] shows.
  ObservationListChoice choiceFor(ObservationType type) {
    if (type != ObservationType.yard) return ObservationListChoice(type);
    return ObservationListChoice(type, yardList: shownYardList);
  }

  /// The current year, even while its list is still empty, and every year that
  /// has yearly observations. Newest first.
  List<int> get availableYears {
    final years = <int>{
      currentYear,
      for (final observation in observations)
        if (observation.type == ObservationType.yearly &&
            observation.timestamp != null)
          observation.timestamp!.year,
    };
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// The list of [type], with each species counted once.
  ///
  /// The yearly list only holds the observations of [shownYear], and the yard
  /// list only those of [shownYardListId].
  List<Observation> observationsFor(ObservationType type) {
    final seenSpeciesIds = <String>{};
    return [
      for (final observation in observations)
        if (observation.type == type &&
            switch (type) {
              ObservationType.yearly =>
                observation.timestamp?.year == shownYear,
              ObservationType.yard =>
                observation.yardListId == shownYardListId,
              ObservationType.life => true,
            } &&
            seenSpeciesIds.add(observation.species.id))
          observation,
    ];
  }

  @override
  List<Object?> get props => [
    currentYear,
    status,
    observations,
    filterType,
    selectedYear,
    yardLists,
    activeYardListId,
    selectedYardListId,
    errorMessage,
  ];
}

/// One list the observations menu can show: a list type and, for yard lists,
/// which yard list.
class ObservationListChoice extends Equatable {
  const ObservationListChoice(this.type, {this.yardList});

  final ObservationType type;

  /// The yard list, for a yard list choice once the yard lists have loaded.
  final YardList? yardList;

  String get label => switch (type) {
    ObservationType.yearly => 'Vuodenpinnat',
    ObservationType.life => 'Elämänpinnat',
    ObservationType.yard =>
      yardList == null ? 'Pihapinnat' : 'Pihapinnat ${yardList!.name}',
  };

  @override
  List<Object?> get props => [type, yardList?.id];
}
