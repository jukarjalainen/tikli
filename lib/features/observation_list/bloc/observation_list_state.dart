part of 'observation_list_bloc.dart';

enum ObservationListStatus { initial, loading, ready, empty, failure }

class ObservationListState extends Equatable {
  const ObservationListState({
    required this.currentYear,
    this.status = ObservationListStatus.initial,
    this.observations = const [],
    this.filterType = ObservationType.yearly,
    this.selectedYear,
    this.customLists = const [],
    this.activeCustomListId,
    this.selectedCustomListId,
    this.errorMessage,
  });

  /// The calendar year whose yearly list is open for new observations.
  final int currentYear;
  final ObservationListStatus status;
  final List<Observation> observations;
  final ObservationType filterType;
  final int? selectedYear;

  /// All custom lists, oldest first.
  final List<CustomList> customLists;

  /// The custom list last saved to, shown on the custom list page by default.
  final String? activeCustomListId;

  /// Another custom list the user is browsing, or null for the active one.
  final String? selectedCustomListId;
  final String? errorMessage;

  ObservationListState copyWith({
    int? currentYear,
    ObservationListStatus? status,
    List<Observation>? observations,
    ObservationType? filterType,
    int? selectedYear,
    bool clearSelectedYear = false,
    List<CustomList>? customLists,
    String? activeCustomListId,
    String? selectedCustomListId,
    bool clearSelectedCustomList = false,
    String? errorMessage,
  }) {
    return ObservationListState(
      currentYear: currentYear ?? this.currentYear,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      filterType: filterType ?? this.filterType,
      selectedYear:
          clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      customLists: customLists ?? this.customLists,
      activeCustomListId: activeCustomListId ?? this.activeCustomListId,
      selectedCustomListId:
          clearSelectedCustomList
              ? null
              : (selectedCustomListId ?? this.selectedCustomListId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// The year the yearly list shows.
  int get shownYear => selectedYear ?? currentYear;

  /// The id of the custom list the custom list page shows: the one picked,
  /// else the one last saved to, else the oldest. Null without custom lists.
  String? get shownCustomListId =>
      selectedCustomListId ??
      activeCustomList?.id ??
      (customLists.isEmpty ? null : customLists.first.id);

  CustomList? customListById(String? id) {
    for (final list in customLists) {
      if (list.id == id) return list;
    }
    return null;
  }

  /// The custom list the custom list page shows.
  CustomList? get shownCustomList => customListById(shownCustomListId);

  /// The custom list last saved to.
  CustomList? get activeCustomList => customListById(activeCustomListId);

  /// Every list the observations menu offers, in page order: the yearly list,
  /// the life list, then each custom list by its name.
  List<ObservationListChoice> get listChoices => [
    const ObservationListChoice(ObservationType.yearly),
    const ObservationListChoice(ObservationType.life),
    if (customLists.isEmpty)
      const ObservationListChoice(ObservationType.custom)
    else
      for (final list in customLists)
        ObservationListChoice(ObservationType.custom, customList: list),
  ];

  /// The list the page of [type] shows.
  ObservationListChoice choiceFor(ObservationType type) {
    if (type != ObservationType.custom) return ObservationListChoice(type);
    return ObservationListChoice(type, customList: shownCustomList);
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
  /// The yearly list only holds the observations of [shownYear], and the
  /// custom list page only those of [shownCustomListId].
  List<Observation> observationsFor(ObservationType type) {
    final seenSpeciesIds = <String>{};
    return [
      for (final observation in observations)
        if (observation.type == type &&
            switch (type) {
              ObservationType.yearly =>
                observation.timestamp?.year == shownYear,
              ObservationType.custom =>
                observation.customListId == shownCustomListId,
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
    customLists,
    activeCustomListId,
    selectedCustomListId,
    errorMessage,
  ];
}

/// One list the observations menu can show: the yearly list, the life list or
/// a custom list.
class ObservationListChoice extends Equatable {
  const ObservationListChoice(this.type, {this.customList});

  final ObservationType type;

  /// The custom list, for a custom list choice. Null on the custom list page
  /// while the user has no custom lists.
  final CustomList? customList;

  String get label => switch (type) {
    ObservationType.yearly => 'Vuodenpinnat',
    ObservationType.life => 'Elämänpinnat',
    ObservationType.custom => customList?.name ?? 'Omat listat',
  };

  @override
  List<Object?> get props => [type, customList?.id];
}
