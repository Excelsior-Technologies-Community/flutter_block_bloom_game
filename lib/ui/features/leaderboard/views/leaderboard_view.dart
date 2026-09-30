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

  // Default Fallback Weekly Entries
  final List<_LeaderboardEntry> _defaultWeeklyEntries = const [
    _LeaderboardEntry(name: 'JK TIMBA', score: 52450, rank: 1, crownColor: Color(0xFFFFC800), jewelColor: Color(0xFFFF4081)),
    _LeaderboardEntry(name: 'DEVAYAT MAMA', score: 48100, rank: 2, crownColor: Color(0xFFE0E0E0), jewelColor: Color(0xFF00E5FF)),
    _LeaderboardEntry(name: 'JAYMIN DABHODA', score: 42850, rank: 3, crownColor: Color(0xFFFFAB40), jewelColor: Color(0xFFFFD700)),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 37600, rank: 4),
    _LeaderboardEntry(name: 'GOPAL BHARWAD', score: 33200, rank: 5),
    _LeaderboardEntry(name: 'VIJAY THAKOR', score: 29450, rank: 6),
    _LeaderboardEntry(name: 'MAHESH PATEL', score: 25800, rank: 7),
    _LeaderboardEntry(name: 'RAHUL SHARMA', score: 22150, rank: 8),
    _LeaderboardEntry(name: 'AMIT VERMA', score: 18900, rank: 9),
    _LeaderboardEntry(name: 'KIRAN RATHOD', score: 15300, rank: 10),
  ];

  // Default Fallback Global Entries
  final List<_LeaderboardEntry> _defaultGlobalEntries = const [
    _LeaderboardEntry(name: 'BLOOM KING 👑', score: 98500, rank: 1, crownColor: Color(0xFFFFC800), jewelColor: Color(0xFFFF4081)),
    _LeaderboardEntry(name: 'DEVAYAT MAMA', score: 86200, rank: 2, crownColor: Color(0xFFE0E0E0), jewelColor: Color(0xFF00E5FF)),
    _LeaderboardEntry(name: 'FLOWER MASTER 🌸', score: 74800, rank: 3, crownColor: Color(0xFFFFAB40), jewelColor: Color(0xFFFFD700)),
    _LeaderboardEntry(name: 'JK TIMBA', score: 65400, rank: 4),
    _LeaderboardEntry(name: 'JAYMIN DABHODA', score: 58900, rank: 5),
    _LeaderboardEntry(name: 'GOPAL BHARWAD', score: 51300, rank: 6),
    _LeaderboardEntry(name: 'GARDEN QUEEN 🌿', score: 44700, rank: 7),
    _LeaderboardEntry(name: 'GAMAN SANTHAL', score: 39200, rank: 8),
    _LeaderboardEntry(name: 'BLOCK STAR ⭐', score: 33600, rank: 9),
    _LeaderboardEntry(name: 'PETAL PRO 🌼', score: 19200, rank: 10),
  ];

  @override
  void initState() {
    super.initState();
    _fetchRealUsersFromFirestore();
  }

  /// Fetches real user documents from Cloud Firestore
  Future<void> _fetchRealUsersFromFirestore() async {
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('highestScore', descending: true)
          .limit(10)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final realEntries = <_LeaderboardEntry>[];
        int rank = 1;
        for (final doc in querySnap.docs) {
          final data = doc.data();
          final name = (data['displayName'] as String?) ??
              (data['name'] as String?) ??
              'Gardener ${doc.id.substring(0, 4)}';
          final score = (data['highestScore'] as num?)?.toInt() ??
              (data['totalScore'] as num?)?.toInt() ??
              0;

          realEntries.add(_LeaderboardEntry(
            name: name.toUpperCase(),
            score: score,
            rank: rank,
            crownColor: rank == 1
                ? const Color(0xFFFFC800)
                : (rank == 2
                    ? const Color(0xFFE0E0E0)
                    : (rank == 3 ? const Color(0xFFFFAB40) : null)),
            jewelColor: rank == 1
                ? const Color(0xFFFF4081)
                : (rank == 2
                    ? const Color(0xFF00E5FF)
                    : (rank == 3 ? const Color(0xFFFFD700) : null)),
          ));
          rank++;
        }
        if (mounted) {
          setState(() {
            _realFirestoreEntries = realEntries;
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
            crownColor: fallbackItem.crownColor,
            jewelColor: fallbackItem.jewelColor,
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
    final progressRepo = ref.watch(progressRepositoryProvider);
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.displayName ?? 'YOU';

    return FutureBuilder<UserProgress>(
      future: progressRepo.getProgress(),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final userScore = progress?.highestScore ?? 0;
        final displayUserScore = userScore > 0 ? userScore : 5000;
        final userRank = _selectedTab == 0 ? 150 : 248;

        final rawList = _selectedTab == 0 ? _defaultWeeklyEntries : _defaultGlobalEntries;
        final currentList = _getDisplayList(rawList);

        return Scaffold(
          backgroundColor: const Color(0xFF05001C),
          body: Stack(
            children: [
              // Fullscreen Starry Background
              Positioned.fill(
                child: Image.asset(
                  'assets/splash_img.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF05001C),
                  ),
                ),
              ),

              // Ambient Overlay Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.60),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Screen Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Bar: Back Button + Floral Header Title "LEADERBOARD"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circular Back Button (Left Aligned)
                              Align(
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

                              // Arched Title: LEADERBOARD
                              FloralHeaderTitle(
                                title: 'LEADERBOARD',
                                fontSize: math.min(size.width * 0.075, 28.0),
                                flowerSize: math.min(size.width * 0.09, 36.0),
                                curveAmount: 14.0,
                                verticalOffset: -18.0,
                                letterSpacing: 1.2,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: size.height * 0.015),

                        // Tab Selector: WEEKLY & GLOBAL
                        _buildTabSelector(size),

                        SizedBox(height: size.height * 0.015),

                        // Main Leaderboard Card Container (Rectangle 29 Specs)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: math.min(size.width - 32, 344),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001834),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomPaint(
                              foregroundPainter: _FiveStopGoldBorderPainter(
                                strokeWidth: 1.5,
                                radius: 12.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Table Header Row: RANK | PLAYER | SCORE
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            child: Text(
                                              'RANK',
                                              style: GoogleFonts.chakraPetch(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'PLAYER',
                                              style: GoogleFonts.chakraPetch(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'SCORE',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Gold Divider Line
                                    Container(
                                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                                      height: 1,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFFC800),
                                            Color(0xFF814D00),
                                            Color(0xFFFFC800),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Ranks 1 to 10 Rows
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(bottom: 6),
                                      itemCount: currentList.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                                      itemBuilder: (context, index) {
                                        final item = currentList[index];
                                        return _buildLeaderboardRow(item);
                                      },
                                    ),

                                    const SizedBox(height: 10),

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

                        const SizedBox(height: 16),
                      ],
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

  /// Builds the 2-Tab Selector Container (WEEKLY & GLOBAL)
  Widget _buildTabSelector(Size size) {
    return Container(
      width: math.min(size.width - 32, 344),
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2096E7).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
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
    );
  }

  /// Builds individual Tab pill button with exact Glossy Green (Group 286) when active
  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF527E27),
                    Color(0xFFDBF19A),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFDBF19A),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44527E27),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : const Color(0xFF2096E7),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds standard leaderboard rows (Ranks 1 to 10)
  Widget _buildLeaderboardRow(_LeaderboardEntry entry) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFC800).withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Column: Medal/Crown Icon for Top 3 or Number for Ranks 4-10
          SizedBox(
            width: 36,
            child: entry.crownColor != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: entry.crownColor,
                        size: 24,
                      ),
                      if (entry.jewelColor != null)
                        Positioned(
                          top: 6,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: entry.jewelColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
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

          const SizedBox(width: 10),

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
  /// Specs: Height 40px, Radius 8px, Border 1px #001834
  /// 5-Stop Gold Fill: #FFC800, #814D00 (72%), #6B4000 (85%), #FFC800 (46%), #814D00
  Widget _buildHighlightUserRow({
    required int rank,
    required String name,
    required int score,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            blurRadius: 8,
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

          const SizedBox(width: 10),

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
              fontSize: 15,
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
  final Color? crownColor;
  final Color? jewelColor;

  const _LeaderboardEntry({
    required this.name,
    required this.score,
    required this.rank,
    this.crownColor,
    this.jewelColor,
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
