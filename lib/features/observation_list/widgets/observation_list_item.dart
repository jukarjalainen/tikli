import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/models/observation.dart';
import '../bloc/observation_list_bloc.dart';

class ObservationListItem extends StatefulWidget {
  const ObservationListItem({
    super.key,
    required this.observation,
    required this.dateFormat,
  });

  final Observation observation;
  final DateFormat dateFormat;

  @override
  State<ObservationListItem> createState() => _ObservationListItemState();
}

class _ObservationListItemState extends State<ObservationListItem> {
  bool _showDelete = false;

  void _handleLongPress() {
    setState(() => _showDelete = true);
  }

  void _handleDismissDelete() {
    if (_showDelete) {
      setState(() => _showDelete = false);
    }
  }

  void _handleDeletePressed() {
    setState(() => _showDelete = false);
    context.read<ObservationListBloc>().add(
      ObservationListObservationDeleted(widget.observation.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commonName = widget.observation.species.commonName;
    final rawLocation = widget.observation.address?.trim() ?? '';
    final location = rawLocation.isNotEmpty ? rawLocation : '';
    final metadataStyle = Theme.of(context).textTheme.bodySmall;

    return ListTile(
      onLongPress: _handleLongPress,
      onTap: _showDelete ? _handleDismissDelete : null,
      tileColor:
          _showDelete
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2)
              : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(commonName, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.observation.timestamp != null
                    ? widget.dateFormat.format(widget.observation.timestamp!)
                    : '',
                style: metadataStyle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location,
                  style: metadataStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder:
            (child, animation) =>
                ScaleTransition(scale: animation, child: child),
        child:
            _showDelete
                ? IconButton(
                  key: const ValueKey('delete'),
                  icon: Icon(
                    MdiIcons.trashCan,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: 'Poista havainto',
                  onPressed: _handleDeletePressed,
                )
                : const SizedBox.shrink(key: ValueKey('placeholder')),
      ),
    );
  }
}
