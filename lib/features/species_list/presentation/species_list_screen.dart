import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/species.dart';
import '../../../core/enums/observation_type.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../bloc/species_list_bloc.dart';
import '../../observation_list/bloc/observation_list_bloc.dart';
import '../widgets/species_list_item.dart';

class SpeciesListScreen extends StatelessWidget {
  const SpeciesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Valitse lajit'),
        backgroundColor: const Color(0xFF56BF32),
      ),
      body: BlocBuilder<SpeciesListBloc, SpeciesListState>(
        builder: (context, state) {
          switch (state.status) {
            case SpeciesListStatus.initial:
            case SpeciesListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case SpeciesListStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Failed to load species'),
              );
            case SpeciesListStatus.ready:
              return _SpeciesListView(
                species: state.species,
                selectedIds: state.selectedSpeciesIds,
              );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<SpeciesListBloc, SpeciesListState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.hasSelection
                        ? () => _onConfirmSelection(context, state)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57BF32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Seuraava'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onConfirmSelection(BuildContext context, SpeciesListState state) {
    final selected =
        state.species
            .where((species) => state.selectedSpeciesIds.contains(species.id))
            .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valitse ainakin yksi laji.')),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.observationForm, arguments: selected);
  }
}

class _SpeciesListView extends StatefulWidget {
  const _SpeciesListView({required this.species, required this.selectedIds});

  final List<Species> species;
  final Set<String> selectedIds;

  @override
  State<_SpeciesListView> createState() => _SpeciesListViewState();
}

class _SpeciesListViewState extends State<_SpeciesListView> {
  static const _shortcutLetters = [
    'A',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'P',
    'R',
    'S',
    'T',
    'U',
    'V',
  ];

  static const double _itemExtent = 64;
  static const double _topPadding = 8;

  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _letterToIndex = {};

  @override
  void initState() {
    super.initState();
    _rebuildAnchors();
  }

  @override
  void didUpdateWidget(covariant _SpeciesListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      _rebuildAnchors();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _rebuildAnchors() {
    _letterToIndex.clear();
    for (var i = 0; i < widget.species.length; i++) {
      final letter = _firstLetter(widget.species[i].commonName);
      _letterToIndex.putIfAbsent(letter, () => i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final observations = context.select(
      (ObservationListBloc bloc) => bloc.state.observations,
    );
    final currentYear = DateTime.now().year;
    final yearlyObservedIds = <String>{};
    final lifeObservedIds = <String>{};
    final yardObservedIds = <String>{};

    for (final observation in observations) {
      switch (observation.type) {
        case ObservationType.yearly:
          if (observation.timestamp.year == currentYear) {
            yearlyObservedIds.add(observation.species.id);
          }
          break;
        case ObservationType.life:
          lifeObservedIds.add(observation.species.id);
          break;
        case ObservationType.yard:
          yardObservedIds.add(observation.species.id);
          break;
      }
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: _topPadding, bottom: 120),
          itemCount: widget.species.length,
          itemExtent: _itemExtent,
          itemBuilder: (context, index) {
            final item = widget.species[index];
            final isSelected = widget.selectedIds.contains(item.id);
            return SpeciesListItem(
              species: item,
              selected: isSelected,
              yearlyObserved: yearlyObservedIds.contains(item.id),
              lifeObserved: lifeObservedIds.contains(item.id),
              yardObserved: yardObservedIds.contains(item.id),
              onTap:
                  () => context.read<SpeciesListBloc>().add(
                    SpeciesSelectionToggled(item.id),
                  ),
            );
          },
        ),
        Positioned(
          top: _topPadding,
          bottom: 120, // Account for bottom button space
          right: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                _shortcutLetters.map((letter) {
                  final isEnabled = _letterToIndex.containsKey(letter);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _ShortcutButton(
                      letter: letter,
                      enabled: isEnabled,
                      onTap: isEnabled ? () => _scrollToLetter(letter) : null,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _scrollToLetter(String letter) async {
    if (!_scrollController.hasClients) {
      return;
    }
    final index = _letterToIndex[letter];
    if (index == null) {
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (index * _itemExtent) + _topPadding;
    final clampedOffset = targetOffset.clamp(0, maxExtent).toDouble();
    await _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  String _firstLetter(String text) {
    if (text.isEmpty) {
      return '';
    }
    return text[0].toUpperCase();
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.letter,
    required this.enabled,
    this.onTap,
  });

  final String letter;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        enabled ? const Color(0xFF57BF32) : Colors.grey[300];
    final textColor = enabled ? Colors.white : Colors.grey[600];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
