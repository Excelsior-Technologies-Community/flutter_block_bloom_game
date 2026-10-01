import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flower Counter Badge matching exact Figma design:
/// Pill background with flower count, pink flower icon, and leaf attached.
class FlowerCounterBadge extends StatelessWidget {
  const FlowerCounterBadge({
    super.key,
    required this.count,
  });

  final int count;

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
      alignment: Alignment.centerRight,
      children: [
        Container(
          height: 38,
          constraints: const BoxConstraints(minWidth: 100),
          decoration: BoxDecoration(
            color: const Color(0xFF001126),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFFFC800),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatCount(count),
                style: GoogleFonts.chakraPetch(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/small_flower.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/game_flower.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (c2, e2, s2) => const Text('🌸', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -6,
          child: Image.asset(
            'assets/garden_leaf.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Image.asset(
              'assets/garden_leaf2.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (c2, e2, s2) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

