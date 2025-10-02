import 'package:flutter/material.dart';

import '../../../core/models/species.dart';

class SpeciesListItem extends StatelessWidget {
  const SpeciesListItem({
    super.key,
    required this.species,
    required this.selected,
    required this.yearlyObserved,
    required this.lifeObserved,
    required this.yardObserved,
    required this.onTap,
  });

  final Species species;
  final bool selected;
  final bool yearlyObserved;
  final bool lifeObserved;
  final bool yardObserved;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFF57BF32);

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.black87;
    final flags = <Widget>[
      if (yearlyObserved) _buildFlag('V'),
      if (lifeObserved) _buildFlag('E'),
      if (yardObserved) _buildFlag('P'),
    ];

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    species.commonName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (flags.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Wrap(spacing: 6, children: flags),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlag(String label) {
    final backgroundColor =
        selected ? Colors.white.withOpacity(0.2) : const Color(0xFFE6F2E2);
    final borderColor =
        selected ? Colors.white.withOpacity(0.4) : const Color(0xFFB7D8AF);
    final flagTextColor = selected ? Colors.white : _selectedColor;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: flagTextColor,
        ),
      ),
    );
  }
}
