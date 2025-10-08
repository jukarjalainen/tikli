import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Custom widget that creates navigation icons:
/// - Star with binoculars inside (showStar: true)
/// - Binoculars with plus inside (showStar: false)
class BinocularsIcon extends StatelessWidget {
  const BinocularsIcon({
    super.key,
    required this.showStar,
    this.color = Colors.white,
    this.size = 45.0,
  });

  final bool
  showStar; // true for star with binoculars, false for binoculars with plus
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (showStar) {
      // Large star with smaller binoculars inside
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Large star background
            Positioned.fill(
              child: Icon(Icons.star, color: color, size: size * 1.1),
            ),
            // Smaller binoculars centered in the star
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: size * 0.25,
                  left: size * 0.20,
                ), // Slight adjustment for star shape
                child: Icon(
                  MdiIcons.eye,
                  color: const Color(0xFF57BF32),
                  size: size * 0.44,
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Large binoculars with smaller plus inside
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Large binoculars background
          Positioned.fill(
            child: Icon(MdiIcons.binoculars, color: color, size: size),
          ),
          // Smaller plus sign with adjustable position
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: size * 0.15, // ← Move DOWN (positive) or UP (negative)
                left: size * 0.10, // ← Move RIGHT (positive) or LEFT (negative)
              ),
              child: Icon(
                MdiIcons.plusThick,
                color: const Color.fromARGB(255, 39, 141, 2),
                size: size * 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
