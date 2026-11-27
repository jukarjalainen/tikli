// Main UI screen displaying a scrollable list of saved bird observations.
// Reacts to state changes from the ObservationListBloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/enums/observation_type.dart';
import '../../../shared/widgets/binoculars_icon.dart';
import '../bloc/observation_list_bloc.dart';
import '../widgets/observation_list_item.dart';

class ObservationListScreen extends StatefulWidget {
  const ObservationListScreen({super.key});

  @override
  State<ObservationListScreen> createState() => _ObservationListScreenState();
}

class _ObservationListScreenState extends State<ObservationListScreen> {
  late final DateFormat _dateFormat;
  late final PageController _pageController;

  // Large number to simulate infinite scrolling
  static const int _virtualPageCount = 10000;
  static const int _typeCount = 3; // ObservationType.values.length

  int _getPageIndexForType(ObservationType type) {
    return ObservationType.values.indexOf(type);
  }

  ObservationType _getTypeForPageIndex(int index) {
    // Use modulo to wrap around the observation types
    final actualIndex = index % _typeCount;
    return ObservationType.values[actualIndex];
  }

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('d.M.yyyy HH:mm');
    final initialType = context.read<ObservationListBloc>().state.filterType;
    final initialTypeIndex = _getPageIndexForType(initialType);

    // Start in the middle to allow swiping in both directions
    _pageController = PageController(
      initialPage: (_virtualPageCount ~/ 2) + initialTypeIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ObservationListBloc, ObservationListState>(
          buildWhen:
              (previous, current) =>
                  previous.filterType != current.filterType ||
                  previous.shownCustomList != current.shownCustomList,
          builder: (context, state) {
            return Text(state.choiceFor(state.filterType).label);
          },
        ),
        backgroundColor: const Color(0xFF57BF32),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const BinocularsIcon(showStar: false),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.speciesList);
          },
          tooltip: 'Lisää havainto',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Tulosta havainnot',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.export);
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed:
                () => Navigator.of(context).pushNamed(AppRoutes.observationMap),
          ),
        ],
      ),
      body: BlocBuilder<ObservationListBloc, ObservationListState>(
        builder: (context, state) {
          if (state.status == ObservationListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sync PageController with current filter type when changed via dropdown
          if (_pageController.hasClients) {
            final currentPage = _pageController.page?.round() ?? 0;
            final currentType = _getTypeForPageIndex(currentPage);

            if (currentType != state.filterType) {
              final targetTypeIndex = _getPageIndexForType(state.filterType);
              final currentPageBase = currentPage - (currentPage % _typeCount);
              final targetPage = currentPageBase + targetTypeIndex;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            }
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: _virtualPageCount,
            onPageChanged: (index) {
              final newType = _getTypeForPageIndex(index);
              if (newType != state.filterType) {
                context.read<ObservationListBloc>().add(
                  ObservationListFilterChanged(newType),
                );
              }
            },
            itemBuilder: (context, pageIndex) {
              final pageType = _getTypeForPageIndex(pageIndex);

              final displayObservations = state.observationsFor(pageType);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ListDropdown(
                                key: ValueKey(state.choiceFor(pageType)),
                                state: state,
                                shown: state.choiceFor(pageType),
                              ),
                            ),
                            if (pageType == ObservationType.yearly) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  initialValue: state.shownYear,
                                  decoration: const InputDecoration(
                                    labelText: 'Vuosi',
                                  ),
                                  items:
                                      state.availableYears
                                          .map(
                                            (year) => DropdownMenuItem(
                                              value: year,
                                              child: Text(year.toString()),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    context.read<ObservationListBloc>().add(
                                      ObservationListFilterChanged(
                                        ObservationType.yearly,
                                        year: value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _ObservationCountBadge(
                            count: displayObservations.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        displayObservations.isEmpty
                            ? _EmptyState(
                              message:
                                  pageType == ObservationType.custom &&
                                          state.customLists.isEmpty
                                      ? 'Ei omia listoja. Lisää lista '
                                          'havaintolomakkeella.'
                                      : 'No observations for this filter',
                            )
                            : ListView.separated(
                              itemCount: displayObservations.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final observation = displayObservations[index];
                                return ObservationListItem(
                                  key: ValueKey(observation.id),
                                  observation: observation,
                                  dateFormat: _dateFormat,
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Picks the list to show from every list: the yearly list, the life list and
/// each custom list.
class _ListDropdown extends StatelessWidget {
  const _ListDropdown({super.key, required this.state, required this.shown});

  static const pickerKey = Key('observationListPicker');

  final ObservationListState state;

  /// The list this page shows.
  final ObservationListChoice shown;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ObservationListChoice>(
      key: pickerKey,
      initialValue: shown,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Lista'),
      items: [
        for (final choice in state.listChoices)
          DropdownMenuItem(
            value: choice,
            child: Text(choice.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (choice) {
        if (choice == null) return;
        context.read<ObservationListBloc>().add(
          ObservationListFilterChanged(
            choice.type,
            customListId: choice.customList?.id,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ObservationCountBadge extends StatelessWidget {
  const _ObservationCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.4)),
      ),
      child: Text(
        'Yhteensä: $count',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }
}
