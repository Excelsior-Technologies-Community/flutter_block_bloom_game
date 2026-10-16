import 'package:flutter/material.dart';
import 'package:block_bloom/domain/models/board_template.dart';

/// Contoured Board Frame that dynamically outlines the board texture,
/// drop shadows, and beveled rim to follow the exact silhouette of any
/// Candy Crush style template (Heart, Diamond, Cross, Funnel, etc.).
class ContouredBoardFrame extends StatelessWidget {
  final BoardTemplate? template;
  final int gridSize;
  final Widget child;

  const ContouredBoardFrame({
    super.key,
    required this.template,
    required this.gridSize,
    required this.child,
  });

  static Path computeTemplatePath(Size size, BoardTemplate? template, int gridSize) {
    final W = size.width;
    final H = size.height;

    // Standard square optimization: smooth 14px rounded rectangle
    if (template == null || template.isStandardSquare) {
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, W, H),
            const Radius.circular(14.0),
          ),
        );
    }

    const double outerPadding = 7.0;
    const double innerPadding = 2.5;
    const double spacing = 3.0;

    final double availableWidth = W - (outerPadding * 2) - (innerPadding * 2);
    final double cellWidth = (availableWidth - (gridSize - 1) * spacing) / gridSize;
    final double cellStride = cellWidth + spacing;

    Path combined = Path();
    bool hasAdded = false;

    // Inflate cells by 6.5px so adjacent cells merge seamlessly and outer edges extend to the border
    const double borderMargin = 6.5;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (template.isPlayable(r, c)) {
          final cellLeft = outerPadding + innerPadding + (c * cellStride);
          final cellTop = outerPadding + innerPadding + (r * cellStride);

          final cellRect = Rect.fromLTWH(cellLeft, cellTop, cellWidth, cellWidth);
          final inflatedRect = cellRect.inflate(borderMargin);
          final rrect = RRect.fromRectAndRadius(
            inflatedRect,
            const Radius.circular(9.0),
          );

          final cellPath = Path()..addRRect(rrect);
          if (!hasAdded) {
            combined = cellPath;
            hasAdded = true;
          } else {
            combined = Path.combine(PathOperation.union, combined, cellPath);
          }
        }
      }
    }

    if (!hasAdded) {
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, W, H),
            const Radius.circular(14.0),
          ),
        );
    }

    return combined;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final path = computeTemplatePath(size, template, gridSize);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Outer 3D Drop Shadows and Ambient Glow following template contour
            CustomPaint(
              size: size,
              painter: _ContouredShadowPainter(path: path),
            ),

            // 2. Board Container with Rectangle 11.png texture clipped to template contour
            ClipPath(
              clipper: _PathClipper(path: path),
              child: Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/Rectangle 11.png'),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    colorFilter: ColorFilter.mode(
                      Color(0xFF003675),
                      BlendMode.srcATop,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(7.0),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  final Path path;
  const _PathClipper({required this.path});

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => oldClipper.path != path;
}

class _ContouredShadowPainter extends CustomPainter {
  final Path path;
  const _ContouredShadowPainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep black drop shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.65), 10.0, true);
    // Cyan-blue ambient backlight glow
    canvas.drawShadow(path, const Color(0xFF007AFF).withValues(alpha: 0.35), 14.0, true);
  }

  @override
  bool shouldRepaint(_ContouredShadowPainter oldDelegate) => oldDelegate.path != path;
}
