import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/data/services/audio_service.dart';

/// Navigation item configuration model
class GardenNavItemData {
  final String label;
  final String iconAsset;

  const GardenNavItemData({
    required this.label,
    required this.iconAsset,
  });
}

/// Custom Bottom Navigation Bar for My Garden Screen
/// Implements exact Figma design specs:
/// Item size: 75px x 68px, radius 10px, 1px border.
/// Active fill: LinearGradient(#94C745 to #1A3C0E)
/// Active border: LinearGradient(#527E27 to #DBF19A)
/// Typography: Chakra Petch 700 10px #FFFFFF center.
class GardenNavBar extends StatelessWidget {
  const GardenNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  static const List<GardenNavItemData> navItems = [
    GardenNavItemData(
      label: 'OVERVIEW',
      iconAsset: 'assets/nav_icon/overview.png',
    ),
    GardenNavItemData(
      label: 'DECORATE',
      iconAsset: 'assets/nav_icon/decorate.png',
    ),
    GardenNavItemData(
      label: 'THEMES',
      iconAsset: 'assets/nav_icon/themes.png',
    ),
    GardenNavItemData(
      label: 'STATS',
      iconAsset: 'assets/nav_icon/stats.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001126),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFC800),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (index) {
          final isSelected = index == selectedIndex;
          final item = navItems[index];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GardenNavItem(
                label: item.label,
                iconAsset: item.iconAsset,
                isSelected: isSelected,
                onTap: () => onItemSelected(index),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Custom Navigation Item Widget matching exact Figma specs
class GardenNavItem extends StatelessWidget {
  const GardenNavItem({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playClickSound();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 75),
        height: 68,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF94C745), Color(0xFF1A3C0E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: isSelected
              ? const GradientBorder(
                  width: 1,
                  gradient: LinearGradient(
                    colors: [Color(0xFF527E27), Color(0xFFDBF19A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : Border.all(
                  color: const Color(0xFF103975).withValues(alpha: 0.5),
                  width: 1.0,
                ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x4094C745),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon from nav_icon folder (Vector Layout: 24px x 26px, Gradient: #FFFFFF to #E9CC70)
            isSelected
                ? ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFE9CC70)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Image.asset(
                      iconAsset,
                      width: 24,
                      height: 26,
                      color: Colors.white,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => Icon(
                        _getFallbackIcon(label),
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Image.asset(
                    iconAsset,
                    width: 24,
                    height: 26,
                    color: const Color(0xFFB0C4DE),
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => Icon(
                      _getFallbackIcon(label),
                      size: 24,
                      color: const Color(0xFFB0C4DE),
                    ),
                  ),

            // Typography: Chakra Petch 700 10px #FFFFFF center
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.chakraPetch(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFFB0C4DE),
                height: 1.0,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFallbackIcon(String label) {
    switch (label) {
      case 'OVERVIEW':
        return Icons.eco_rounded;
      case 'DECORATE':
        return Icons.park_rounded;
      case 'THEMES':
        return Icons.palette_rounded;
      case 'STATS':
        return Icons.bar_chart_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

/// Custom Gradient Border painter for exact 1px linear gradient border
class GradientBorder extends BoxBorder {
  const GradientBorder({
    required this.gradient,
    this.width = 1.0,
  });

  final Gradient gradient;
  final double width;

  @override
  BorderSide get top => BorderSide(width: width);
  @override
  BorderSide get bottom => BorderSide(width: width);

  BorderSide get left => BorderSide.none;
  BorderSide get right => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    if (borderRadius != null) {
      final rrect = borderRadius.toRRect(rect.deflate(width / 2));
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return GradientBorder(
      gradient: gradient,
      width: width * t,
    );
  }
}
