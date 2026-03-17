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

  String _titleForType(ObservationType type) {
    switch (type) {
      case ObservationType.yearly:
        return 'Vuodenpinnat';
      case ObservationType.life:
        return 'Elämänpinnat';
      case ObservationType.yard:
        return 'Pihapinnat';
    }
    return 'Pinnat';
  }

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
              (previous, current) => previous.filterType != current.filterType,
          builder: (context, state) {
            return Text(_titleForType(state.filterType));
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

              // Get observations for this page's type
              final bloc = context.read<ObservationListBloc>();
              final pageObservations =
                  bloc.state.observations
                      .where((obs) => obs.type == pageType)
                      .toList();

              // For yearly, filter by selected year
              final displayObservations =
                  pageType == ObservationType.yearly
                      ? pageObservations
                          .where(
                            (obs) => obs.timestamp?.year == state.selectedYear,
                          )
                          .toList()
                      : pageObservations;

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
                              child: DropdownButtonFormField<ObservationType>(
                                initialValue: state.filterType,
                                decoration: const InputDecoration(
                                  labelText: 'Pinnatyyppi',
                                ),
                                items:
                                    ObservationType.values
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type.label),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  context.read<ObservationListBloc>().add(
                                    ObservationListFilterChanged(value),
                                  );
                                },
                              ),
                            ),
                            if (state.filterType == ObservationType.yearly) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: state.selectedYear,
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
                            ? const _EmptyState()
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No observations for this filter'),
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
