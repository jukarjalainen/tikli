import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/enums/observation_type.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../bloc/observation_list_bloc.dart';
import '../widgets/observation_list_item.dart';

class ObservationListScreen extends StatefulWidget {
  const ObservationListScreen({super.key});

  @override
  State<ObservationListScreen> createState() => _ObservationListScreenState();
}

class _ObservationListScreenState extends State<ObservationListScreen> {
  late final DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('d.M.yyyy HH:mm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Observations'),
        backgroundColor: const Color(0xFF57BF32),
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

          final filter = state.filterType;
          final observations = state.visibleObservations;

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
                            initialValue: filter,
                            decoration: const InputDecoration(
                              labelText: 'List type',
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
                        if (filter == ObservationType.yearly) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: state.selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year',
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
                      child: _ObservationCountBadge(count: observations.length),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    observations.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                          itemCount: observations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final observation = observations[index];
                            return ObservationListItem(
                              observation: observation,
                              dateFormat: _dateFormat,
                            );
                          },
                        ),
              ),
            ],
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
        'Total: $count',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }
}
