import 'package:flutter/material.dart';

import '../../../core/models/species.dart';

class SpeciesListItem extends StatelessWidget {
  const SpeciesListItem({
    super.key,
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final Species species;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFF57BF32);

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected ? _selectedColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              species.commonName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
