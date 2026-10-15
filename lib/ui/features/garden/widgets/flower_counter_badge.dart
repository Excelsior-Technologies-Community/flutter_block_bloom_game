import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flower Counter Badge matching exact Figma design:
/// Pill background with flower count, pink flower icon, and leaf attached.
class FlowerCounterBadge extends StatelessWidget {
  const FlowerCounterBadge({
    super.key,
    required this.count,
    this.badgeAsset = 'assets/flower_view_design.png',
  });

  final int count;
  final String badgeAsset;

  String _formatCount(int count) {
    final str = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Leaf placed in BACK so its stem is naturally tucked behind the pill
        Positioned(
          right: -16,
          bottom: -4,
          child: Image.asset(
            'assets/leaf.png',
            width: 34,
            height: 30,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (ctx, err, st) => Image.asset(
              'assets/garden_leaf.png',
              width: 34,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (c2, e2, s2) => const SizedBox.shrink(),
            ),
          ),
        ),

        // 2. Double-lobed Pill Badge background rendered ON TOP of the leaf stem
        Image.asset(
          badgeAsset,
          width: 96,
          height: 48,
          fit: BoxFit.fill,
          errorBuilder: (ctx, err, st) => Image.asset(
            'assets/flower_view_design.png',
            width: 96,
            height: 48,
            fit: BoxFit.fill,
          ),
        ),

        // 3. Flower Count Text (Left Lobe)
        Positioned(
          left: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              _formatCount(count),
              style: GoogleFonts.chakraPetch(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFE699),
              ),
            ),
          ),
        ),

        // 4. Pink Flower Icon (Right Lobe)
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Image.asset(
              'assets/game_flower.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (ctx, err, st) => Image.asset(
                'assets/flower.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (c2, e2, s2) => const Text('🌸', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

