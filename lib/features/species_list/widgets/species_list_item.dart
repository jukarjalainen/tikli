import 'package:flutter/material.dart';

import '../../../core/models/species.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

  // Constants matching shortcut positioning from species_list_screen.dart
  static const double _shortcutRightMargin = 8.0;
  static const double _shortcutButtonWidth = 32.0;
  static const double _shortcutTotalWidth =
      _shortcutRightMargin + _shortcutButtonWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : Colors.black87;
    final flags = <Widget>[
      if (yearlyObserved) _buildBinocularFlag('V'),
      if (lifeObserved) _buildStarFlag('E'),
      if (yardObserved) _buildHouseFlag('P'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  SizedBox(
                    width: _shortcutTotalWidth,
                  ), // Margin relative to shortcuts
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBinocularFlag(String label) {
    final bodyColor = selected ? Colors.white : const Color(0xFFA5D6A7);
    final accentColor = selected ? _selectedColor : const Color(0xFF1B5E20);
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(MdiIcons.binoculars, color: bodyColor, size: 24),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarFlag(String label) {
    final starColor = selected ? Colors.white : const Color(0xFFFFD54F);
    final letterColor = selected ? _selectedColor : const Color(0xFF8D6E63);
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: starColor, size: 26),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: letterColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseFlag(String label) {
    final houseColor = selected ? Colors.white : const Color(0xFFD7E9FF);
    final letterColor = selected ? _selectedColor : const Color(0xFF1E88E5);
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.house_rounded, color: houseColor, size: 24),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: letterColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleFlag(String label) {
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
