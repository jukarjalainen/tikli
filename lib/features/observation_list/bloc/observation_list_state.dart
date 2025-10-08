part of 'observation_list_bloc.dart';

enum ObservationListStatus { initial, loading, ready, empty, failure }

class ObservationListState extends Equatable {
  const ObservationListState({
    this.status = ObservationListStatus.initial,
    this.observations = const [],
    this.visibleObservations = const [],
    this.filterType = ObservationType.yearly,
    this.selectedYear,
    this.errorMessage,
  });

  final ObservationListStatus status;
  final List<Observation> observations;
  final List<Observation> visibleObservations;
  final ObservationType filterType;
  final int? selectedYear;
  final String? errorMessage;

  ObservationListState copyWith({
    ObservationListStatus? status,
    List<Observation>? observations,
    List<Observation>? visibleObservations,
    ObservationType? filterType,
    int? selectedYear,
    bool clearSelectedYear = false,
    String? errorMessage,
  }) {
    return ObservationListState(
      status: status ?? this.status,
      observations: observations ?? this.observations,
      visibleObservations: visibleObservations ?? this.visibleObservations,
      filterType: filterType ?? this.filterType,
      selectedYear:
          clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<int> get availableYears {
    final years =
        observations
            .where((observation) =>
                observation.type == ObservationType.yearly &&
                observation.timestamp != null)
            .map((observation) => observation.timestamp!.year)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (years.isEmpty) {
      years.add(DateTime.now().year);
    }
    return years;
  }

  bool get isEmpty => visibleObservations.isEmpty;

  @override
  List<Object?> get props => [
    status,
    observations,
    visibleObservations,
    filterType,
    selectedYear,
    errorMessage,
  ];
}
