import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/domain/models/game_avatar.dart';

/// Highly stylized, circular game avatar supporting:
/// 1. Catalog avatars (3D renders & glossy medallions)
/// 2. Local asset paths
/// 3. Network URLs (e.g. Google Sign-In photo)
/// 4. Elegant fallback initial letter or flower symbol
class GameAvatarWidget extends StatelessWidget {
  final String? avatarIdOrUrl;
  final String fallbackLetter;
  final double size;
  final bool showBorder;
  final bool isSelected;
  final double borderWidth;
  final Color? customBorderColor;

  const GameAvatarWidget({
    super.key,
    required this.avatarIdOrUrl,
    this.fallbackLetter = '🌸',
    this.size = 78.0,
    this.showBorder = true,
    this.isSelected = false,
    this.borderWidth = 2.5,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatarItem = GameAvatarCatalog.getById(avatarIdOrUrl);
    final borderColor = customBorderColor ??
        (isSelected
            ? const Color(0xFF00E5FF)
            : (avatarItem?.borderColor ?? const Color(0xFFFFC800)));

    final coreWidget = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _buildAvatarContent(avatarItem),
      ),
    );

    if (!showBorder) {
      return coreWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? const [
                  Color(0xFFE0F7FA),
                  Color(0xFF00E5FF),
                  Color(0xFF0091EA),
                ]
              : [
                  const Color(0xFFFFEC99),
                  borderColor,
                  const Color(0xFFB8860B),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? const Color(0xFF00E5FF) : borderColor)
                .withValues(alpha: isSelected ? 0.65 : 0.35),
            blurRadius: isSelected ? 16 : 10,
            spreadRadius: isSelected ? 2 : 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF00152F),
        ),
        child: ClipOval(
          child: coreWidget,
        ),
      ),
    );
  }

  Widget _buildAvatarContent(GameAvatarItem? avatarItem) {
    // 1. If catalog item has a bundled asset image
    if (avatarItem != null &&
        avatarItem.assetPath != null &&
        avatarItem.assetPath!.isNotEmpty) {
      return Image.asset(
        avatarItem.assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildGlossyMedallion(avatarItem),
      );
    }

    // 2. If it's a catalog item with vector/emoji & glossy radial background
    if (avatarItem != null) {
      return _buildGlossyMedallion(avatarItem);
    }

    // 3. If it's a direct network URL (e.g. Google Sign-In)
    if (avatarIdOrUrl != null &&
        (avatarIdOrUrl!.startsWith('http://') ||
            avatarIdOrUrl!.startsWith('https://'))) {
      return Image.network(
        avatarIdOrUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackInitial(),
      );
    }

    // 4. If it's a raw asset path
    if (avatarIdOrUrl != null && avatarIdOrUrl!.startsWith('assets/')) {
      return Image.asset(
        avatarIdOrUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackInitial(),
      );
    }

    // 5. If it's a local file from device storage
    if (avatarIdOrUrl != null && !avatarIdOrUrl!.startsWith('assets/')) {
      final cleanPath = avatarIdOrUrl!.replaceFirst('file://', '');
      try {
        final file = File(cleanPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackInitial(),
          );
        }
      } catch (_) {}
    }

    // 6. Default Fallback
    return _buildFallbackInitial();
  }

  /// Glossy 3D Medallion Avatar with specular light arc and centered vibrant symbol
  Widget _buildGlossyMedallion(GameAvatarItem item) {
    final emojiSize = size * 0.44;

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Radial Gradient Fill
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.3),
              radius: 0.9,
              colors: item.gradientColors,
            ),
          ),
        ),

        // Deep Inner Shadow for 3D depth
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.95,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),

        // Top Specular Gloss Reflection Arc
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size * 0.48,
          child: ClipPath(
            clipper: _GlossArcClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Centered Emoji Symbol with drop shadow
        Center(
          child: Text(
            item.emoji,
            style: TextStyle(
              fontSize: emojiSize,
              height: 1.0,
              shadows: const [
                Shadow(
                  color: Color(0x80000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
                Shadow(
                  color: Color(0x66FFFFFF),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Initial letter fallback displayed inside the avatar circle (e.g. 'A')
  Widget _buildFallbackInitial() {
    final letter = fallbackLetter.trim().isNotEmpty
        ? fallbackLetter.trim()[0].toUpperCase()
        : '🌸';

    final isEmoji = RegExp(
            r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])')
        .hasMatch(letter);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C2B54),
            Color(0xFF00152F),
          ],
        ),
      ),
      child: Center(
        child: isEmoji
            ? Text(
                letter,
                style: TextStyle(fontSize: size * 0.45),
              )
            : Text(
                letter,
                style: GoogleFonts.chakraPetch(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFC800),
                  letterSpacing: 1.0,
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                    Shadow(
                      color: Color(0x80FFC800),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _GlossArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.3,
      size.width,
      size.height * 0.85,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
