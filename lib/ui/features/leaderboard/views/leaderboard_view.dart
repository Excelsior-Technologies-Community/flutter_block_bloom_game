import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/user_progress.dart';

/// Leaderboard View matching exact Figma specifications & mobile device screenshot:
/// - Fetches REAL user records from Firebase Firestore (collection: 'users')
/// - Clean tight card layout (Rectangle 29) eliminating huge blank gaps
/// - Arched floral header title "LEADERBOARD"
/// - Custom Tab Selector: WEEKLY & GLOBAL with Glossy Green active pill
/// - Rank 1, 2, 3 with Gold, Silver, Bronze badges
/// - Ranks 4-10 standard rows
/// - Highlighted "YOU" row (Rectangle 60): 5-stop Gold horizontal gradient fill with black bold text
class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  int _selectedTab = 0; // 0 = WEEKLY, 1 = GLOBAL
  List<_LeaderboardEntry>? _realFirestoreEntries;
  int _actualUserRank = 150;

  // Default Fallback Weekly Entries matching screenshot mock data
  final List<_LeaderboardEntry> _defaultWeeklyEntries = const [
    _LeaderboardEntry(
      name: 'JK TIMBA',
      score: 5000,
      rank: 1,
      crownAsset: 'assets/leaderboard_icons/gold_crown.png',
    ),
    _LeaderboardEntry(
      name: 'DEVAYAT MAMA',
      score: 5000,
      rank: 2,
      crownAsset: 'assets/leaderboard_icons/silver_crown.png',
    ),
    _LeaderboardEntry(
      name: 'JAYMIN DABHODA',
      score: 5000,
      rank: 3,
      crownAsset: 'assets/leaderboard_icons/platinum_crown.png',
    ),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 4),
    _LeaderboardEntry(name: 'GOPAL BHARWAD', score: 5000, rank: 5),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 6),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 7),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 8),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 9),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 5000, rank: 10),
  ];

  // Default Fallback Global Entries
  final List<_LeaderboardEntry> _defaultGlobalEntries = const [
    _LeaderboardEntry(
      name: 'BLOOM KING 👑',
      score: 98500,
      rank: 1,
      crownAsset: 'assets/leaderboard_icons/gold_crown.png',
    ),
    _LeaderboardEntry(
      name: 'DEVAYAT MAMA',
      score: 86200,
      rank: 2,
      crownAsset: 'assets/leaderboard_icons/silver_crown.png',
    ),
    _LeaderboardEntry(
      name: 'FLOWER MASTER 🌸',
      score: 74800,
      rank: 3,
      crownAsset: 'assets/leaderboard_icons/platinum_crown.png',
    ),
    _LeaderboardEntry(name: 'JK TIMBA', score: 65400, rank: 4),
    _LeaderboardEntry(name: 'JAYMIN DABHODA', score: 58900, rank: 5),
    _LeaderboardEntry(name: 'GOPAL BHARWAD', score: 51300, rank: 6),
    _LeaderboardEntry(name: 'GARDEN QUEEN 🌿', score: 44700, rank: 7),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 39200, rank: 8),
    _LeaderboardEntry(name: 'BLOCK STAR ⭐', score: 33600, rank: 9),
    _LeaderboardEntry(name: 'PETAL PRO 🌼', score: 19200, rank: 10),
  ];

  late Future<UserProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = ref.read(progressRepositoryProvider).getProgress();
    _fetchRealUsersFromFirestore();
  }

  /// Fetches real user documents from Cloud Firestore
  Future<void> _fetchRealUsersFromFirestore() async {
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('highestScore', descending: true)
          .limit(100)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final realEntries = <_LeaderboardEntry>[];
        int rank = 1;
        int? userRankFound;

        for (final doc in querySnap.docs) {
          final data = doc.data();
          final name = (data['displayName'] as String?) ??
              (data['name'] as String?) ??
              'Gardener ${doc.id.substring(0, math.min(4, doc.id.length))}';
          final score = (data['highestScore'] as num?)?.toInt() ??
              (data['totalScore'] as num?)?.toInt() ??
              0;

          final crownAsset = rank == 1
              ? 'assets/leaderboard_icons/gold_crown.png'
              : (rank == 2
                  ? 'assets/leaderboard_icons/silver_crown.png'
                  : (rank == 3
                      ? 'assets/leaderboard_icons/platinum_crown.png'
                      : null));

          if (rank <= 10) {
            realEntries.add(_LeaderboardEntry(
              name: name.toUpperCase(),
              score: score,
              rank: rank,
              crownAsset: crownAsset,
            ));
          }

          final currentUserId = ref.read(authViewModelProvider).user?.uid;
          if (currentUserId != null && (doc.id == currentUserId || data['uid'] == currentUserId)) {
            userRankFound = rank;
          }

          rank++;
        }

        if (mounted) {
          setState(() {
            _realFirestoreEntries = realEntries;
            if (userRankFound != null) {
              _actualUserRank = userRankFound;
            }
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Firestore leaderboard fetch note: $e');
    }
  }

  /// Merges real Firestore entries with default backfills if fewer than 10 real users exist
  List<_LeaderboardEntry> _getDisplayList(List<_LeaderboardEntry> fallbackList) {
    if (_realFirestoreEntries != null && _realFirestoreEntries!.isNotEmpty) {
      final merged = List<_LeaderboardEntry>.from(_realFirestoreEntries!);
      if (merged.length < 10) {
        // Backfill remaining ranks with fallback entries
        for (int i = merged.length; i < 10; i++) {
          final fallbackItem = fallbackList[i];
          merged.add(_LeaderboardEntry(
            name: fallbackItem.name,
            score: fallbackItem.score,
            rank: i + 1,
            crownAsset: fallbackItem.crownAsset,
          ));
        }
      }
      return merged;
    }
    return fallbackList;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.displayName ?? 'YOU';

    return FutureBuilder<UserProgress>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final userScore = progress?.highestScore ?? 0;
        final displayUserScore = userScore > 0 ? userScore : 5000;
        final userRank = _selectedTab == 0 ? _actualUserRank : (_actualUserRank + 98);

        final rawList = _selectedTab == 0 ? _defaultWeeklyEntries : _defaultGlobalEntries;
        final currentList = _getDisplayList(rawList);

        return Scaffold(
          backgroundColor: const Color(0xFF001026),
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fullscreen Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/splash_img.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF001026),
                  ),
                ),
              ),

              // 2. Ambient Dark Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.50),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Main Screen Content Structure inside Positioned.fill
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Back Button Row (Top Left)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AudioService.instance.playClickSound();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001834),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFC800),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // SizedBox Height
                        const SizedBox(height: 25),

                        // 2. Floral Header Title "LEADERBOARD"
                        FloralHeaderTitle(
                          title: 'LEADERBOARD',
                          fontSize: math.min(size.width * 0.09, 32.0),
                          flowerSize: math.min(size.width * 0.11, 42.0),
                          curveAmount: 16.0,
                          verticalOffset: -20.0,
                          letterSpacing: 1.5,
                        ),

                        // SizedBox Height Space
                        const SizedBox(height: 22),

                        // 3. Tabs Selector: WEEKLY & GLOBAL
                        _buildTabSelector(size),

                        // SizedBox Height Space
                        const SizedBox(height: 22),

                        // 4. Big Card Container with back_design.png Background Image & 3 Crown Badges inside
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Container(
                            width: math.min(size.width - 32, 344),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001834),
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage('assets/leaderboard_icons/back_design.png'),
                                fit: BoxFit.fill,
                                colorFilter: ColorFilter.mode(
                                  Color(0xFF001834),
                                  BlendMode.modulate,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                foregroundPainter: _FiveStopGoldBorderPainter(
                                  strokeWidth: 1.5,
                                  radius: 12.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Table Header Row: RANK | PLAYER | SCORE
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 36,
                                              child: Text(
                                                'RANK',
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'PLAYER',
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'SCORE',
                                              style: GoogleFonts.chakraPetch(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Gold Gradient Divider Line after RANK, PLAYER, SCORE
                                      Container(
                                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                                        height: 1,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFFC800),
                                              Color(0xFF814D00),
                                              Color(0xFF6B4000),
                                              Color(0xFF814D00),
                                              Color(0xFFFFC800),
                                            ],
                                            stops: [0.0, 0.46, 0.72, 0.85, 1.0],
                                          ),
                                        ),
                                      ),

                                      // Ranks 1 to 10 Rows (Gold, Silver, Platinum Crown icons for Top 3)
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount: currentList.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 5),
                                        itemBuilder: (context, index) {
                                          final item = currentList[index];
                                          return _buildLeaderboardRow(item);
                                        },
                                      ),

                                      const SizedBox(height: 8),

                                      // Highlighted Bottom "YOU" Row (Rectangle 60 Specs)
                                      _buildHighlightUserRow(
                                        rank: userRank,
                                        name: userName.isNotEmpty ? userName : 'YOU',
                                        score: displayUserScore,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  /// Builds the 2-Tab Selector Container (WEEKLY & GLOBAL) with 5-Stop Gold Gradient Border (1px)
  Widget _buildTabSelector(Size size) {
    return Container(
      width: math.min(size.width - 32, 344),
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(19),
        image: const DecorationImage(
          image: AssetImage('assets/leaderboard_icons/back_design.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          colorFilter: ColorFilter.mode(
            Color(0xFF001834),
            BlendMode.modulate,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: CustomPaint(
          foregroundPainter: _FiveStopGoldBorderPainter(
            strokeWidth: 1.0,
            radius: 19.0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                // WEEKLY Tab
                Expanded(
                  child: _buildTabButton(
                    title: 'WEEKLY',
                    isSelected: _selectedTab == 0,
                    onTap: () {
                      AudioService.instance.playClickSound();
                      setState(() => _selectedTab = 0);
                    },
                  ),
                ),

                // GLOBAL Tab
                Expanded(
                  child: _buildTabButton(
                    title: 'GLOBAL',
                    isSelected: _selectedTab == 1,
                    onTap: () {
                      AudioService.instance.playClickSound();
                      setState(() => _selectedTab = 1);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds individual Tab pill button with exact Glossy Green (Group 286) when active
  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF82BD31),
                    Color(0xFF4F7A23),
                    Color(0xFF385A18),
                  ],
                  stops: [0.0, 0.60, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFB9F064),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66385A18),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              )
            : const BoxDecoration(
                color: Colors.transparent,
              ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds standard leaderboard rows (Ranks 1 to 10) - Height 38px
  Widget _buildLeaderboardRow(_LeaderboardEntry entry) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Column: Crown PNG icon for Top 3 or Number for Ranks 4-10
          SizedBox(
            width: 36,
            child: entry.crownAsset != null
                ? Center(
                    child: Image.asset(
                      entry.crownAsset!,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.workspace_premium_rounded,
                        color: entry.rank == 1
                            ? const Color(0xFFFFC800)
                            : (entry.rank == 2
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFFFFAB40)),
                        size: 20,
                      ),
                    ),
                  )
                : Text(
                    '${entry.rank}',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),

          const SizedBox(width: 8),

          // Player Name Column
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.chakraPetch(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score Column
          Text(
            _formatScore(entry.score),
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Highlighted Bottom "YOU" Row (Rectangle 60 specs from Figma)
  /// Specs: Height 38px, Radius 8px, Border 1px #001834
  /// 5-Stop Gold Fill: #FFC800, #814D00 (72%), #6B4000 (85%), #FFC800 (46%), #814D00
  Widget _buildHighlightUserRow({
    required int rank,
    required String name,
    required int score,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFC800),
            Color(0xFF814D00),
            Color(0xFF6B4000),
            Color(0xFFFFC800),
            Color(0xFF814D00),
          ],
          stops: [0.0, 0.46, 0.72, 0.85, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF001834),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFC800),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Rank
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              style: GoogleFonts.chakraPetch(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // User Name / YOU
          Expanded(
            child: Text(
              name.toUpperCase(),
              style: GoogleFonts.chakraPetch(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // User Score
          Text(
            _formatScore(score),
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    final str = score.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _LeaderboardEntry {
  final String name;
  final int score;
  final int rank;
  final String? crownAsset;

  const _LeaderboardEntry({
    required this.name,
    required this.score,
    required this.rank,
    this.crownAsset,
  });
}

/// Custom painter to paint the 5-stop Gold gradient border for Rectangle 29
/// Gradient stops: #FFC800, #814D00, #6B4000, #814D00, #FFC800
class _FiveStopGoldBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double radius;

  _FiveStopGoldBorderPainter({
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius - strokeWidth / 2),
    );

    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFC800),
        Color(0xFF814D00),
        Color(0xFF6B4000),
        Color(0xFF814D00),
        Color(0xFFFFC800),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _FiveStopGoldBorderPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
}
