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
    final location = observation.address?.trim() ?? '';
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
          Text(location.isNotEmpty ? location : 'Paikkatieto puuttuu'),
        ],
      ),
      trailing: Text(
        observation.type.label,
        style: const TextStyle(color: Color(0xFF57BF32)),
      ),
    );
  }
}
