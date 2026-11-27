// Main UI screen displaying a scrollable list of saved bird observations.
// Reacts to state changes from the ObservationListBloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/enums/observation_type.dart';
import '../../../core/models/observation.dart';
import '../../../shared/widgets/binoculars_icon.dart';
import '../bloc/observation_list_bloc.dart';
import '../widgets/observation_list_item.dart';

class ObservationListScreen extends StatelessWidget {
  const ObservationListScreen({super.key});

  static final DateFormat _dateFormat = DateFormat('d.M.yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ObservationListBloc, ObservationListState>(
          buildWhen:
              (previous, current) =>
                  previous.filterType != current.filterType ||
                  previous.shownCustomList != current.shownCustomList ||
                  previous.customLists != current.customLists,
          builder: (context, state) => _ListDropdown(state: state),
        ),
        titleSpacing: 8,
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
          return _ObservationListBody(state: state, dateFormat: _dateFormat);
        },
      ),
    );
  }
}

/// Picks the list to show from every list: the yearly list, the life list and
/// each custom list. Sits in the app bar in place of a heading.
class _ListDropdown extends StatelessWidget {
  const _ListDropdown({required this.state});

  static const pickerKey = Key('observationListPicker');

  final ObservationListState state;

  @override
  Widget build(BuildContext context) {
    // The app bar's title style, so the chosen list reads as the heading.
    final titleStyle = DefaultTextStyle.of(context).style;
    final choices = state.listChoices;
    return DropdownButtonHideUnderline(
      child: DropdownButton<ObservationListChoice>(
        key: pickerKey,
        value: state.choiceFor(state.filterType),
        isExpanded: true,
        iconEnabledColor: titleStyle.color,
        selectedItemBuilder:
            (context) => [
              for (final choice in choices)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    choice.label,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
        items: [
          for (final choice in choices)
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
      ),
    );
  }
}

/// The year picker for the yearly list, and the species of the list the app
/// bar shows with their count floating in the bottom right corner.
class _ObservationListBody extends StatelessWidget {
  const _ObservationListBody({required this.state, required this.dateFormat});

  static const listAreaKey = Key('observationListArea');

  final ObservationListState state;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final type = state.filterType;
    final displayObservations = state.observationsFor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type == ObservationType.yearly)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _YearDropdown(state: state),
          ),
        Expanded(
          child: Stack(
            key: listAreaKey,
            children: [
              Positioned.fill(
                child: _SpeciesList(
                  state: state,
                  observations: displayObservations,
                  dateFormat: dateFormat,
                ),
              ),
              Positioned(
                right: 16,
                // Above the phone's own navigation buttons, which the app is
                // drawn under.
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                child: _ObservationCountBadge(
                  count: displayObservations.length,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The species of the list the app bar shows, or why there are none.
class _SpeciesList extends StatelessWidget {
  const _SpeciesList({
    required this.state,
    required this.observations,
    required this.dateFormat,
  });

  final ObservationListState state;
  final List<Observation> observations;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return _EmptyState(
        message:
            state.filterType == ObservationType.custom &&
                    state.customLists.isEmpty
                ? 'Ei omia listoja. Lisää lista havaintolomakkeella.'
                : 'No observations for this filter',
      );
    }
    return ListView.separated(
      // Room to scroll the last species up from under the count badge and the
      // phone's navigation buttons.
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 64,
      ),
      itemCount: observations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final observation = observations[index];
        return ObservationListItem(
          key: ValueKey(observation.id),
          observation: observation,
          dateFormat: dateFormat,
        );
      },
    );
  }
}

/// Picks the year the yearly list shows.
class _YearDropdown extends StatelessWidget {
  const _YearDropdown({required this.state});

  final ObservationListState state;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: state.shownYear,
      decoration: const InputDecoration(labelText: 'Vuosi'),
      items:
          state.availableYears
              .map(
                (year) =>
                    DropdownMenuItem(value: year, child: Text(year.toString())),
              )
              .toList(),
      onChanged: (value) {
        context.read<ObservationListBloc>().add(
          ObservationListFilterChanged(ObservationType.yearly, year: value),
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

/// The species count. Floats over the list, so it is opaque: the species
/// scroll underneath it.
class _ObservationCountBadge extends StatelessWidget {
  const _ObservationCountBadge({required this.count});

  static const badgeKey = Key('observationCountBadge');

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      key: badgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          primary.withValues(alpha: 0.12),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
