import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/observation_type.dart';
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
    final initial = commonName.isNotEmpty ? commonName[0].toUpperCase() : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF57BF32),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        commonName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(observation.timestamp)),
          if (observation.address != null) Text(observation.address!),
          Text(
            'Lat ${observation.position.latitude.toStringAsFixed(4)}, Lng ${observation.position.longitude.toStringAsFixed(4)}',
          ),
        ],
      ),
      trailing: Text(
        observation.type.label,
        style: const TextStyle(color: Color(0xFF57BF32)),
      ),
    );
  }
}
