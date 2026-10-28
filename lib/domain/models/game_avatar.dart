import 'package:flutter/material.dart';

class GameAvatarItem {
  final String id;
  final String name;
  final String subtitle;
  final String? assetPath;
  final String emoji;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color borderColor;

  const GameAvatarItem({
    required this.id,
    required this.name,
    required this.subtitle,
    this.assetPath,
    required this.emoji,
    required this.gradientColors,
    required this.accentColor,
    this.borderColor = const Color(0xFFFFC800),
  });
}

class GameAvatarCatalog {
  static const List<GameAvatarItem> avatars = [
    GameAvatarItem(
      id: 'avatar_rose',
      name: 'Rose Bloom',
      subtitle: 'Radiant & Elegant',
      assetPath: 'assets/avatars/avatar_rose.jpg',
      emoji: '🌸',
      gradientColors: [Color(0xFFFF758C), Color(0xFFFF7EB3), Color(0xFFC9184A)],
      accentColor: Color(0xFFFF758C),
    ),
    GameAvatarItem(
      id: 'avatar_sunflower',
      name: 'Sun Gem',
      subtitle: 'Warm & Cheerful',
      assetPath: 'assets/avatars/avatar_sunflower.jpg',
      emoji: '🌻',
      gradientColors: [Color(0xFFFFE066), Color(0xFFFFB703), Color(0xFFFB8500)],
      accentColor: Color(0xFFFFB703),
    ),
    GameAvatarItem(
      id: 'avatar_lotus',
      name: 'Mystic Lotus',
      subtitle: 'Serene & Glowing',
      assetPath: 'assets/avatars/avatar_lotus.jpg',
      emoji: '🪷',
      gradientColors: [Color(0xFF4CC9F0), Color(0xFF7209B7), Color(0xFFF72585)],
      accentColor: Color(0xFF4CC9F0),
    ),
    GameAvatarItem(
      id: 'avatar_butterfly',
      name: 'Monarch Wing',
      subtitle: 'Free & Vivid',
      emoji: '🦋',
      gradientColors: [Color(0xFF7B2CBF), Color(0xFF3A0CA3), Color(0xFF0077B6)],
      accentColor: Color(0xFF9D4EDD),
    ),
    GameAvatarItem(
      id: 'avatar_honeybee',
      name: 'Bumble Crown',
      subtitle: 'Sweet & Busy',
      emoji: '🐝',
      gradientColors: [Color(0xFFFFD166), Color(0xFFF4A261), Color(0xFFE76F51)],
      accentColor: Color(0xFFFFC800),
    ),
    GameAvatarItem(
      id: 'avatar_ladybug',
      name: 'Lucky Bug',
      subtitle: 'Fortune & Charm',
      emoji: '🐞',
      gradientColors: [Color(0xFFFF4D6D), Color(0xFFC9184A), Color(0xFF590D22)],
      accentColor: Color(0xFFFF4D6D),
    ),
    GameAvatarItem(
      id: 'avatar_fox',
      name: 'Forest Fox',
      subtitle: 'Clever & Swift',
      emoji: '🦊',
      gradientColors: [Color(0xFFFF9E00), Color(0xFFE85D04), Color(0xFF9D0208)],
      accentColor: Color(0xFFFF9E00),
    ),
    GameAvatarItem(
      id: 'avatar_owl',
      name: 'Starlight Owl',
      subtitle: 'Wise Guardian',
      emoji: '🦉',
      gradientColors: [Color(0xFF4361EE), Color(0xFF3F37C9), Color(0xFF1B263B)],
      accentColor: Color(0xFF4CC9F0),
    ),
    GameAvatarItem(
      id: 'avatar_bunny',
      name: 'Meadow Bunny',
      subtitle: 'Gentle & Soft',
      emoji: '🐰',
      gradientColors: [Color(0xFFA2D2FF), Color(0xFFBDE0FE), Color(0xFFFFAFCC)],
      accentColor: Color(0xFFBDE0FE),
    ),
    GameAvatarItem(
      id: 'avatar_tulip',
      name: 'Spring Tulip',
      subtitle: 'Fresh Blossom',
      emoji: '🌷',
      gradientColors: [Color(0xFFFF70A6), Color(0xFFFF9770), Color(0xFFE056FD)],
      accentColor: Color(0xFFFF70A6),
    ),
    GameAvatarItem(
      id: 'avatar_daisy',
      name: 'Golden Daisy',
      subtitle: 'Pure Sunshine',
      emoji: '🌼',
      gradientColors: [Color(0xFFFFF3B0), Color(0xFFE09F3E), Color(0xFF9E2A2B)],
      accentColor: Color(0xFFFFD166),
    ),
    GameAvatarItem(
      id: 'avatar_gem',
      name: 'Prism Crystal',
      subtitle: 'Gleaming Jewel',
      emoji: '💎',
      gradientColors: [Color(0xFF48CAE4), Color(0xFF0096C7), Color(0xFF03045E)],
      accentColor: Color(0xFF48CAE4),
    ),
    GameAvatarItem(
      id: 'avatar_crown',
      name: 'Royal Crown',
      subtitle: 'Garden Sovereign',
      emoji: '👑',
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
      accentColor: Color(0xFFFFD700),
    ),
    GameAvatarItem(
      id: 'avatar_hibiscus',
      name: 'Tropical Bloom',
      subtitle: 'Island Spirit',
      emoji: '🌺',
      gradientColors: [Color(0xFFFF5D8F), Color(0xFFFF1654), Color(0xFF8B0000)],
      accentColor: Color(0xFFFF5D8F),
    ),
    GameAvatarItem(
      id: 'avatar_rainbow',
      name: 'Rainbow Flora',
      subtitle: 'Prismatic Magic',
      emoji: '🌈',
      gradientColors: [Color(0xFFFF5964), Color(0xFFFFE74C), Color(0xFF35A7FF)],
      accentColor: Color(0xFF6EE7B7),
    ),
  ];

  static GameAvatarItem? getById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return avatars.firstWhere(
        (a) => a.id == id || a.assetPath == id,
      );
    } catch (_) {
      return null;
    }
  }
}
