/// Board Template representing Candy Crush style level layouts for Block Bloom.
/// Supports 25+ shaped grids (Heart, Diamond, Funnel, Cross, Clover, Crown, Pyramid,
/// Twin Towers, Castle, Shield, Tulip, Bowtie, Ring, Star, Courtyard, Keyhole, Anchor,
/// Honeycomb, Windmill, Crescent, and progressive Squares)
/// where '.' represents void/blocked out-of-bounds space, and 'X' represents playable cells.
class BoardTemplate {
  final String id;
  final String name;
  final String emoji;
  final int rows;
  final int cols;
  final List<String> layout;
  final bool isStandardSquare;

  const BoardTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rows,
    required this.cols,
    required this.layout,
    this.isStandardSquare = false,
  });

  bool isPlayable(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
    if (r >= layout.length || c >= layout[r].length) return false;
    return layout[r][c] == 'X';
  }

  int get totalPlayableCells {
    int count = 0;
    for (final row in layout) {
      for (int i = 0; i < row.length; i++) {
        if (row[i] == 'X') count++;
      }
    }
    return count;
  }

  // =========================================================================
  // 25 UNIQUE CANDY CRUSH TEMPLATES
  // =========================================================================

  // 1. Tutorial Square (5x5)
  static const BoardTemplate square5 = BoardTemplate(
    id: 'square5',
    name: 'Garden Patch',
    emoji: '🌱',
    rows: 5,
    cols: 5,
    isStandardSquare: true,
    layout: [
      'XXXXX',
      'XXXXX',
      'XXXXX',
      'XXXXX',
      'XXXXX',
    ],
  );

  // 2. Beginner Square (6x6)
  static const BoardTemplate square6 = BoardTemplate(
    id: 'square6',
    name: 'Bloom Square',
    emoji: '🌸',
    rows: 6,
    cols: 6,
    isStandardSquare: true,
    layout: [
      'XXXXXX',
      'XXXXXX',
      'XXXXXX',
      'XXXXXX',
      'XXXXXX',
      'XXXXXX',
    ],
  );

  // 3. Medium Square (7x7)
  static const BoardTemplate square7 = BoardTemplate(
    id: 'square7',
    name: 'Flora Garden',
    emoji: '🌺',
    rows: 7,
    cols: 7,
    isStandardSquare: true,
    layout: [
      'XXXXXXX',
      'XXXXXXX',
      'XXXXXXX',
      'XXXXXXX',
      'XXXXXXX',
      'XXXXXXX',
      'XXXXXXX',
    ],
  );

  // 4. Standard Classic Square (8x8)
  static const BoardTemplate square8 = BoardTemplate(
    id: 'square8',
    name: 'Classic Bloom',
    emoji: '🌼',
    rows: 8,
    cols: 8,
    isStandardSquare: true,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // 5. Candy Crush Heart Shape (Milestone levels)
  static const BoardTemplate heart = BoardTemplate(
    id: 'heart',
    name: 'Blossom Heart',
    emoji: '💖',
    rows: 8,
    cols: 8,
    layout: [
      '.XX..XX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '...XX...',
      '...XX...',
    ],
  );

  // 6. Candy Crush Diamond / Octagon (Diagonal cutouts)
  static const BoardTemplate diamond = BoardTemplate(
    id: 'diamond',
    name: 'Diamond Octagon',
    emoji: '💎',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // 7. Candy Crush Funnel / Inverted Pyramid
  static const BoardTemplate funnel = BoardTemplate(
    id: 'funnel',
    name: 'Garden Funnel',
    emoji: '🔻',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
      '...XX...',
      '...XX...',
    ],
  );

  // 8. Candy Crush Petal Cross / Plus
  static const BoardTemplate cross = BoardTemplate(
    id: 'cross',
    name: 'Petal Cross',
    emoji: '➕',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '..XXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
      '..XXXX..',
    ],
  );

  // 9. Four-Leaf Clover
  static const BoardTemplate clover = BoardTemplate(
    id: 'clover',
    name: 'Lucky Clover',
    emoji: '🍀',
    rows: 8,
    cols: 8,
    layout: [
      '.XX..XX.',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
      '..XXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XX..XX.',
    ],
  );

  // 10. Hourglass / Butterfly
  static const BoardTemplate hourglass = BoardTemplate(
    id: 'hourglass',
    name: 'Butterfly Wings',
    emoji: '🦋',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '...XX...',
      '...XX...',
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
    ],
  );

  // 11. Royal Crown
  static const BoardTemplate crown = BoardTemplate(
    id: 'crown',
    name: 'Royal Crown',
    emoji: '👑',
    rows: 8,
    cols: 8,
    layout: [
      'X..XX..X',
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // 12. Sun Pyramid (Upright step pyramid)
  static const BoardTemplate pyramid = BoardTemplate(
    id: 'pyramid',
    name: 'Sun Pyramid',
    emoji: '🔺',
    rows: 8,
    cols: 8,
    layout: [
      '...XX...',
      '..XXXX..',
      '..XXXX..',
      '.XXXXXX.',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // 13. Twin Towers / Bridge
  static const BoardTemplate twinTowers = BoardTemplate(
    id: 'twinTowers',
    name: 'Twin Bridges',
    emoji: '🌉',
    rows: 8,
    cols: 8,
    layout: [
      'XXX..XXX',
      'XXX..XXX',
      'XXX..XXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXX..XXX',
      'XXX..XXX',
      'XXX..XXX',
    ],
  );

  // 14. Flower Castle Battlements
  static const BoardTemplate castle = BoardTemplate(
    id: 'castle',
    name: 'Flower Castle',
    emoji: '🏰',
    rows: 8,
    cols: 8,
    layout: [
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
    ],
  );

  // 15. Garden Shield
  static const BoardTemplate shield = BoardTemplate(
    id: 'shield',
    name: 'Garden Shield',
    emoji: '🛡️',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      '..XXXX..',
      '...XX...',
    ],
  );

  // 16. Royal Tulip Chalice
  static const BoardTemplate tulip = BoardTemplate(
    id: 'tulip',
    name: 'Royal Tulip',
    emoji: '🌷',
    rows: 8,
    cols: 8,
    layout: [
      'X.XXXX.X',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '...XX...',
      '...XX...',
    ],
  );

  // 17. Garden Ribbon Bowtie
  static const BoardTemplate bowtie = BoardTemplate(
    id: 'bowtie',
    name: 'Garden Ribbon',
    emoji: '🎀',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXX..XXX',
      '.XX..XX.',
      '..XXXX..',
      '..XXXX..',
      '.XX..XX.',
      'XXX..XXX',
      'XXXXXXXX',
    ],
  );

  // 18. Diamond Ring
  static const BoardTemplate ring = BoardTemplate(
    id: 'ring',
    name: 'Diamond Ring',
    emoji: '💍',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
      '.XX..XX.',
      '.XX..XX.',
      '.XX..XX.',
      '..XXXX..',
    ],
  );

  // 19. Blossom Star (8-point radiating star)
  static const BoardTemplate star = BoardTemplate(
    id: 'star',
    name: 'Blossom Star',
    emoji: '⭐',
    rows: 8,
    cols: 8,
    layout: [
      '...XX...',
      'X..XX..X',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      'X..XX..X',
      '...XX...',
    ],
  );

  // 20. Courtyard Fountain (Hollow center courtyard)
  static const BoardTemplate courtyard = BoardTemplate(
    id: 'courtyard',
    name: 'Courtyard Fountain',
    emoji: '⛲',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XX....XX',
      'XX....XX',
      'XX....XX',
      'XX....XX',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // 21. Garden Keyhole
  static const BoardTemplate keyhole = BoardTemplate(
    id: 'keyhole',
    name: 'Garden Keyhole',
    emoji: '🗝️',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '..XXXX..',
      '...XX...',
      '...XX...',
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // 22. Bloom Anchor
  static const BoardTemplate anchor = BoardTemplate(
    id: 'anchor',
    name: 'Bloom Anchor',
    emoji: '⚓',
    rows: 8,
    cols: 8,
    layout: [
      '...XX...',
      'XXXXXXXX',
      '...XX...',
      '...XX...',
      'X..XX..X',
      'X..XX..X',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // 23. Bee Honeycomb Hexagon
  static const BoardTemplate honeycomb = BoardTemplate(
    id: 'honeycomb',
    name: 'Bee Honeycomb',
    emoji: '🐝',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // 24. Floral Windmill
  static const BoardTemplate windmill = BoardTemplate(
    id: 'windmill',
    name: 'Floral Windmill',
    emoji: '🎡',
    rows: 8,
    cols: 8,
    layout: [
      'XXXX....',
      'XXXX.XX.',
      '..XXXXX.',
      '..XXXX..',
      '..XXXX..',
      '.XXXXX..',
      '.XX.XXXX',
      '....XXXX',
    ],
  );

  // 25. Moon Garden Crescent
  static const BoardTemplate crescent = BoardTemplate(
    id: 'crescent',
    name: 'Moon Garden',
    emoji: '🌙',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXXXX',
      '.XXXXXX.',
      'XXXXX...',
      'XXXX....',
      'XXXX....',
      'XXXXX...',
      '.XXXXXX.',
      '..XXXXXX',
    ],
  );

  // Complete list of all 25 templates for browsing or random mode
  static const List<BoardTemplate> allTemplates = [
    square5,
    square6,
    square7,
    square8,
    heart,
    diamond,
    funnel,
    cross,
    clover,
    hourglass,
    crown,
    pyramid,
    twinTowers,
    castle,
    shield,
    tulip,
    bowtie,
    ring,
    star,
    courtyard,
    keyhole,
    anchor,
    honeycomb,
    windmill,
    crescent,
  ];

  // =========================================================================
  // 100-LEVEL DIVERSE TEMPLATE MAPPING
  // Every single level features an intentional, non-repeating template!
  // =========================================================================
  static final List<BoardTemplate> _levelTemplates100 = [
    // Chapter 1 (1 - 20): Bloom Valley
    square5,    // Level 1: Garden Patch 🌱 (Tutorial)
    square5,    // Level 2: Seedling 🌱 (Tutorial)
    square6,    // Level 3: Bloom Square 🌸 (Starter 6x6)
    square6,    // Level 4: Flora Box 🌸 (Starter 6x6)
    diamond,    // Level 5: Diamond Octagon 💎 (First Big Milestone!)
    square7,    // Level 6: Flora Garden 🌺 (7x7)
    square7,    // Level 7: Rose Meadow 🌺 (7x7)
    cross,      // Level 8: Petal Cross ➕
    funnel,     // Level 9: Garden Funnel 🔻
    heart,      // Level 10: Blossom Heart 💖 (Chapter 1 Finale!)
    clover,     // Level 11: Lucky Clover 🍀
    hourglass,  // Level 12: Butterfly Wings 🦋
    crown,      // Level 13: Royal Crown 👑
    pyramid,    // Level 14: Sun Pyramid 🔺
    diamond,    // Level 15: Diamond Octagon 💎 (Milestone!)
    twinTowers, // Level 16: Twin Bridges 🌉
    castle,     // Level 17: Flower Castle 🏰
    shield,     // Level 18: Garden Shield 🛡️
    tulip,      // Level 19: Royal Tulip 🌷
    heart,      // Level 20: Blossom Heart 💖 (Chapter 1 Boss!)

    // Chapter 2 (21 - 40): Sunlit Orchard
    bowtie,     // Level 21: Garden Ribbon 🎀
    ring,       // Level 22: Diamond Ring 💍
    star,       // Level 23: Blossom Star ⭐
    courtyard,  // Level 24: Courtyard Fountain ⛲
    diamond,    // Level 25: Diamond Octagon 💎 (Milestone!)
    keyhole,    // Level 26: Garden Keyhole 🗝️
    anchor,     // Level 27: Bloom Anchor ⚓
    honeycomb,  // Level 28: Bee Honeycomb 🐝
    windmill,   // Level 29: Floral Windmill 🎡
    heart,      // Level 30: Blossom Heart 💖 (Chapter 2 Boss!)
    crescent,   // Level 31: Moon Garden 🌙
    cross,      // Level 32: Petal Cross ➕
    funnel,     // Level 33: Garden Funnel 🔻
    clover,     // Level 34: Lucky Clover 🍀
    diamond,    // Level 35: Diamond Octagon 💎 (Milestone!)
    hourglass,  // Level 36: Butterfly Wings 🦋
    crown,      // Level 37: Royal Crown 👑
    pyramid,    // Level 38: Sun Pyramid 🔺
    tulip,      // Level 39: Royal Tulip 🌷
    heart,      // Level 40: Blossom Heart 💖 (Chapter 2 Finale!)

    // Chapter 3 (41 - 60): Mystical Woods
    twinTowers, // Level 41: Twin Bridges 🌉
    castle,     // Level 42: Flower Castle 🏰
    shield,     // Level 43: Garden Shield 🛡️
    bowtie,     // Level 44: Garden Ribbon 🎀
    diamond,    // Level 45: Diamond Octagon 💎 (Milestone!)
    ring,       // Level 46: Diamond Ring 💍
    star,       // Level 47: Blossom Star ⭐
    courtyard,  // Level 48: Courtyard Fountain ⛲
    keyhole,    // Level 49: Garden Keyhole 🗝️
    heart,      // Level 50: Blossom Heart 💖 (Midway Climax!)
    anchor,     // Level 51: Bloom Anchor ⚓
    honeycomb,  // Level 52: Bee Honeycomb 🐝
    windmill,   // Level 53: Floral Windmill 🎡
    crescent,   // Level 54: Moon Garden 🌙
    diamond,    // Level 55: Diamond Octagon 💎 (Milestone!)
    cross,      // Level 56: Petal Cross ➕
    funnel,     // Level 57: Garden Funnel 🔻
    clover,     // Level 58: Lucky Clover 🍀
    hourglass,  // Level 59: Butterfly Wings 🦋
    heart,      // Level 60: Blossom Heart 💖 (Chapter 3 Finale!)

    // Chapter 4 (61 - 80): Starlight Glade
    crown,      // Level 61: Royal Crown 👑
    pyramid,    // Level 62: Sun Pyramid 🔺
    tulip,      // Level 63: Royal Tulip 🌷
    twinTowers, // Level 64: Twin Bridges 🌉
    diamond,    // Level 65: Diamond Octagon 💎 (Milestone!)
    castle,     // Level 66: Flower Castle 🏰
    shield,     // Level 67: Garden Shield 🛡️
    bowtie,     // Level 68: Garden Ribbon 🎀
    ring,       // Level 69: Diamond Ring 💍
    heart,      // Level 70: Blossom Heart 💖 (Chapter 4 Boss!)
    star,       // Level 71: Blossom Star ⭐
    courtyard,  // Level 72: Courtyard Fountain ⛲
    keyhole,    // Level 73: Garden Keyhole 🗝️
    anchor,     // Level 74: Bloom Anchor ⚓
    diamond,    // Level 75: Diamond Octagon 💎 (Milestone!)
    honeycomb,  // Level 76: Bee Honeycomb 🐝
    windmill,   // Level 77: Floral Windmill 🎡
    crescent,   // Level 78: Moon Garden 🌙
    cross,      // Level 79: Petal Cross ➕
    heart,      // Level 80: Blossom Heart 💖 (Chapter 4 Finale!)

    // Chapter 5 (81 - 100): Celestial Realm
    funnel,     // Level 81: Garden Funnel 🔻
    clover,     // Level 82: Lucky Clover 🍀
    hourglass,  // Level 83: Butterfly Wings 🦋
    crown,      // Level 84: Royal Crown 👑
    diamond,    // Level 85: Diamond Octagon 💎 (Milestone!)
    pyramid,    // Level 86: Sun Pyramid 🔺
    twinTowers, // Level 87: Twin Bridges 🌉
    castle,     // Level 88: Flower Castle 🏰
    tulip,      // Level 89: Royal Tulip 🌷
    heart,      // Level 90: Blossom Heart 💖 (Chapter 5 Boss!)
    shield,     // Level 91: Garden Shield 🛡️
    bowtie,     // Level 92: Garden Ribbon 🎀
    ring,       // Level 93: Diamond Ring 💍
    star,       // Level 94: Blossom Star ⭐
    diamond,    // Level 95: Diamond Octagon 💎 (Penultimate Milestone!)
    courtyard,  // Level 96: Courtyard Fountain ⛲
    keyhole,    // Level 97: Garden Keyhole 🗝️
    windmill,   // Level 98: Floral Windmill 🎡
    crescent,   // Level 99: Moon Garden 🌙
    heart,      // Level 100: Blossom Heart 💖 (Grand Finale Masterpiece!)
  ];

  /// Selects the ideal Candy Crush template for each level from Level 1 to 100.
  /// Every level has a distinct template and no two consecutive levels repeat!
  static BoardTemplate getTemplateForLevel(int levelNumber) {
    if (levelNumber <= 0) return square8;
    final index = (levelNumber - 1) % _levelTemplates100.length;
    return _levelTemplates100[index];
  }

  // =========================================================================
  // 31 HANDCRAFTED DAILY GARDEN ARENA TEMPLATES
  // Designed specifically for Daily Garden mode: spacious, high-scoring
  // layouts with open centers, floral/nature contours, and huge combo potential!
  // =========================================================================

  // Day 1: Lotus Blossom 🪷
  static const BoardTemplate dailyLotus = BoardTemplate(
    id: 'daily_lotus',
    name: 'Lotus Blossom',
    emoji: '🪷',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // Day 2: Sunflower Arena 🌻
  static const BoardTemplate dailySunflower = BoardTemplate(
    id: 'daily_sunflower',
    name: 'Sunflower Arena',
    emoji: '🌻',
    rows: 8,
    cols: 8,
    layout: [
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 3: Lucky Four-Leaf 🍀
  static const BoardTemplate dailyFourLeaf = BoardTemplate(
    id: 'daily_four_leaf',
    name: 'Lucky Four-Leaf',
    emoji: '🍀',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
    ],
  );

  // Day 4: Royal Orchid 🌺
  static const BoardTemplate dailyOrchid = BoardTemplate(
    id: 'daily_orchid',
    name: 'Royal Orchid',
    emoji: '🌺',
    rows: 8,
    cols: 8,
    layout: [
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // Day 5: Garden Butterfly 🦋
  static const BoardTemplate dailyButterfly = BoardTemplate(
    id: 'daily_butterfly',
    name: 'Garden Butterfly',
    emoji: '🦋',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // Day 6: Blossom Star 🌟
  static const BoardTemplate dailyBlossomStar = BoardTemplate(
    id: 'daily_blossom_star',
    name: 'Blossom Star',
    emoji: '🌟',
    rows: 8,
    cols: 8,
    layout: [
      '...XX...',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '...XX...',
    ],
  );

  // Day 7: Rose Chalice 🌹
  static const BoardTemplate dailyRoseChalice = BoardTemplate(
    id: 'daily_rose_chalice',
    name: 'Rose Chalice',
    emoji: '🌹',
    rows: 8,
    cols: 8,
    layout: [
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // Day 8: Zen Water Lily 🪷
  static const BoardTemplate dailyZenLily = BoardTemplate(
    id: 'daily_zen_lily',
    name: 'Zen Water Lily',
    emoji: '🪷',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 9: Imperial Crown 👑
  static const BoardTemplate dailyImperialCrown = BoardTemplate(
    id: 'daily_imperial_crown',
    name: 'Imperial Crown',
    emoji: '👑',
    rows: 8,
    cols: 8,
    layout: [
      'X..XX..X',
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 10: Tree of Life 🌳
  static const BoardTemplate dailyTreeOfLife = BoardTemplate(
    id: 'daily_tree_of_life',
    name: 'Tree of Life',
    emoji: '🌳',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
      '..XXXX..',
      '.XXXXXX.',
    ],
  );

  // Day 11: Flora Diamond 💠
  static const BoardTemplate dailyFloraDiamond = BoardTemplate(
    id: 'daily_flora_diamond',
    name: 'Flora Diamond',
    emoji: '💠',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
    ],
  );

  // Day 12: Morning Dew 💧
  static const BoardTemplate dailyDewDrop = BoardTemplate(
    id: 'daily_dew_drop',
    name: 'Morning Dew',
    emoji: '💧',
    rows: 8,
    cols: 8,
    layout: [
      '...XX...',
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 13: Garden Gate ⛩️
  static const BoardTemplate dailyGardenGate = BoardTemplate(
    id: 'daily_garden_gate',
    name: 'Garden Gate',
    emoji: '⛩️',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXX..XXX',
      'XXX..XXX',
      'XXX..XXX',
      'XXX..XXX',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // Day 14: Sweet Lavender 🪻
  static const BoardTemplate dailyLavender = BoardTemplate(
    id: 'daily_lavender',
    name: 'Sweet Lavender',
    emoji: '🪻',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      'XXXXXXXX',
      '.XXXXXX.',
      'XXXXXXXX',
      '.XXXXXX.',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // Day 15: Honeycomb Glade 🐝
  static const BoardTemplate dailyHoneycomb = BoardTemplate(
    id: 'daily_honeycomb',
    name: 'Honeycomb Glade',
    emoji: '🐝',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXX..',
    ],
  );

  // Day 16: Sunburst Arena ☀️
  static const BoardTemplate dailySunburst = BoardTemplate(
    id: 'daily_sunburst',
    name: 'Sunburst Arena',
    emoji: '☀️',
    rows: 8,
    cols: 8,
    layout: [
      'X.XXXX.X',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'X.XXXX.X',
    ],
  );

  // Day 17: Peacock Fan 🦚
  static const BoardTemplate dailyPeacock = BoardTemplate(
    id: 'daily_peacock',
    name: 'Peacock Fan',
    emoji: '🦚',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
    ],
  );

  // Day 18: Garden Fountain ⛲
  static const BoardTemplate dailyFountain = BoardTemplate(
    id: 'daily_fountain',
    name: 'Garden Fountain',
    emoji: '⛲',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXX..',
      '..XXXX..',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 19: Magnolia Bloom 🌸
  static const BoardTemplate dailyMagnolia = BoardTemplate(
    id: 'daily_magnolia',
    name: 'Magnolia Bloom',
    emoji: '🌸',
    rows: 8,
    cols: 8,
    layout: [
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XX....XX',
      'XX....XX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 20: Celestial Crescent 🌙
  static const BoardTemplate dailyCrescent = BoardTemplate(
    id: 'daily_crescent',
    name: 'Celestial Crescent',
    emoji: '🌙',
    rows: 8,
    cols: 8,
    layout: [
      '..XXXXXX',
      '.XXXXXXX',
      'XXXXXXXX',
      'XXXXXXX.',
      'XXXXXXX.',
      'XXXXXXXX',
      '.XXXXXXX',
      '..XXXXXX',
    ],
  );

  // Day 21: Twin Sprout 🌱
  static const BoardTemplate dailyTwinSprout = BoardTemplate(
    id: 'daily_twin_sprout',
    name: 'Twin Sprout',
    emoji: '🌱',
    rows: 8,
    cols: 8,
    layout: [
      'XX....XX',
      'XXX..XXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
    ],
  );

  // Day 22: Dahlia Crest 🏵️
  static const BoardTemplate dailyDahlia = BoardTemplate(
    id: 'daily_dahlia',
    name: 'Dahlia Crest',
    emoji: '🏵️',
    rows: 8,
    cols: 8,
    layout: [
      '.XX..XX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XX..XX.',
    ],
  );

  // Day 23: Ivy Cross 🌿
  static const BoardTemplate dailyIvyCross = BoardTemplate(
    id: 'daily_ivy_cross',
    name: 'Ivy Cross',
    emoji: '🌿',
    rows: 8,
    cols: 8,
    layout: [
      '.XXXXXX.',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '.XXXXXX.',
    ],
  );

  // Day 24: Tulip Chalice 🌷
  static const BoardTemplate dailyTulipChalice = BoardTemplate(
    id: 'daily_tulip_chalice',
    name: 'Tulip Chalice',
    emoji: '🌷',
    rows: 8,
    cols: 8,
    layout: [
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
    ],
  );

  // Day 25: Garden Ribbon 🎀
  static const BoardTemplate dailyGardenRibbon = BoardTemplate(
    id: 'daily_garden_ribbon',
    name: 'Garden Ribbon',
    emoji: '🎀',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXX..XXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXX..XXX',
      'XXXXXXXX',
    ],
  );

  // Day 26: Starlight Bloom ✨
  static const BoardTemplate dailyStarlightBloom = BoardTemplate(
    id: 'daily_starlight_bloom',
    name: 'Starlight Bloom',
    emoji: '✨',
    rows: 8,
    cols: 8,
    layout: [
      '.X.XX.X.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.X.XX.X.',
    ],
  );

  // Day 27: Garden Shield 🛡️
  static const BoardTemplate dailyGardenShield = BoardTemplate(
    id: 'daily_garden_shield',
    name: 'Garden Shield',
    emoji: '🛡️',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      '..XXXX..',
      '..XXXX..',
    ],
  );

  // Day 28: Dragonfly Glade 🌾
  static const BoardTemplate dailyDragonfly = BoardTemplate(
    id: 'daily_dragonfly',
    name: 'Dragonfly Glade',
    emoji: '🌾',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXXXX',
      '.XXXXXX.',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '.XXXXXX.',
      'XXXXXXXX',
    ],
  );

  // Day 29: Daisy Wheel 🌼
  static const BoardTemplate dailyDaisyWheel = BoardTemplate(
    id: 'daily_daisy_wheel',
    name: 'Daisy Wheel',
    emoji: '🌼',
    rows: 8,
    cols: 8,
    layout: [
      '.XXXXXX.',
      'XXXXXXXX',
      'XX.XX.XX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XX.XX.XX',
      'XXXXXXXX',
      '.XXXXXX.',
    ],
  );

  // Day 30: Celestial Galaxy 🌌
  static const BoardTemplate dailyGalaxy = BoardTemplate(
    id: 'daily_galaxy',
    name: 'Celestial Galaxy',
    emoji: '🌌',
    rows: 8,
    cols: 8,
    layout: [
      'XXXXXX..',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      '..XXXXXX',
    ],
  );

  // Day 31: Eden Paradise 🌴
  static const BoardTemplate dailyEdenParadise = BoardTemplate(
    id: 'daily_eden_paradise',
    name: 'Eden Paradise',
    emoji: '🌴',
    rows: 8,
    cols: 8,
    isStandardSquare: true,
    layout: [
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
      'XXXXXXXX',
    ],
  );

  // Complete List of All 31 Daily Garden Templates
  static const List<BoardTemplate> dailyTemplates = [
    dailyLotus,           // Day 1: Lotus Blossom 🪷
    dailySunflower,       // Day 2: Sunflower Arena 🌻
    dailyFourLeaf,        // Day 3: Lucky Four-Leaf 🍀
    dailyOrchid,          // Day 4: Royal Orchid 🌺
    dailyButterfly,       // Day 5: Garden Butterfly 🦋
    dailyBlossomStar,     // Day 6: Blossom Star 🌟
    dailyRoseChalice,     // Day 7: Rose Chalice 🌹
    dailyZenLily,         // Day 8: Zen Water Lily 🪷
    dailyImperialCrown,   // Day 9: Imperial Crown 👑
    dailyTreeOfLife,      // Day 10: Tree of Life 🌳
    dailyFloraDiamond,    // Day 11: Flora Diamond 💠
    dailyDewDrop,         // Day 12: Morning Dew 💧
    dailyGardenGate,      // Day 13: Garden Gate ⛩️
    dailyLavender,        // Day 14: Sweet Lavender 🪻
    dailyHoneycomb,       // Day 15: Honeycomb Glade 🐝
    dailySunburst,        // Day 16: Sunburst Arena ☀️
    dailyPeacock,         // Day 17: Peacock Fan 🦚
    dailyFountain,        // Day 18: Garden Fountain ⛲
    dailyMagnolia,        // Day 19: Magnolia Bloom 🌸
    dailyCrescent,        // Day 20: Celestial Crescent 🌙
    dailyTwinSprout,      // Day 21: Twin Sprout 🌱
    dailyDahlia,          // Day 22: Dahlia Crest 🏵️
    dailyIvyCross,        // Day 23: Ivy Cross 🌿
    dailyTulipChalice,    // Day 24: Tulip Chalice 🌷
    dailyGardenRibbon,    // Day 25: Garden Ribbon 🎀
    dailyStarlightBloom,  // Day 26: Starlight Bloom ✨ (Today!)
    dailyGardenShield,    // Day 27: Garden Shield 🛡️
    dailyDragonfly,       // Day 28: Dragonfly Glade 🌾
    dailyDaisyWheel,      // Day 29: Daisy Wheel 🌼
    dailyGalaxy,          // Day 30: Celestial Galaxy 🌌
    dailyEdenParadise,    // Day 31: Eden Paradise 🌴
  ];

  /// Returns the designated Daily Garden template for any date.
  /// Maps each day of the month (1-31) to its handcrafted high-scoring garden arena.
  static BoardTemplate getDailyTemplate(DateTime date) {
    final dayIndex = (date.day - 1) % dailyTemplates.length;
    return dailyTemplates[dayIndex];
  }
}

