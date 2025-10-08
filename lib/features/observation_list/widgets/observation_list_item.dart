import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/observation.dart';

class ObservationListItem extends StatelessWidget {
  const ObservationListItem({
    super.key,
    required this.observation,
    required this.dateFormat,
  });

  final Observation observation;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final commonName = observation.species.commonName;
    final rawLocation = observation.address?.trim() ?? '';
    final location =
        rawLocation.isNotEmpty ? rawLocation : '';
    final metadataStyle = Theme.of(context).textTheme.bodySmall;

    return ListTile(
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
                observation.timestamp != null
                    ? dateFormat.format(observation.timestamp!)
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
    );
  }
}
