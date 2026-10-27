import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/ui/features/leaderboard/views/leaderboard_view.dart';

/// Top 3 Leader entry data holder for the compact podium card
class _Top3LeaderItem {
  final int rank;
  final String name;
  final int score;
  final String? photoUrl;

  const _Top3LeaderItem({
    required this.rank,
    required this.name,
    required this.score,
    this.photoUrl,
  });
}

/// Compact Top 3 Leaderboard Podium Card
///
/// Designed to fit smoothly on the Home View directly down from the Daily Garden button:
/// - Olympic / Game Podium structure: Rank 2 (Left), Rank 1 (Center, tallest), Rank 3 (Right)
/// - Exact aesthetic from the reference image: royal purple center pillar (1), warm coral side pillars (2 & 3)
/// - Gold crown on Rank 1, circular avatars, compact score pills, and player names
/// - Glassmorphism navy background with subtle gold border and back_design texture
/// - Compact height (~126px) so it leaves ample breathing room for other home screen actions
/// - Tapping anywhere opens the full [LeaderboardView]
class CompactTop3LeaderboardCard extends StatelessWidget {
  const CompactTop3LeaderboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final leaders = _extractTop3(snapshot.data?.docs);
        return _buildCard(context, leaders);
      },
    );
  }

  /// Extracts top 3 users from Firestore docs, with charming fallbacks if offline/empty
  List<_Top3LeaderItem> _extractTop3(List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs) {
    if (docs == null || docs.isEmpty) {
      return const [
        _Top3LeaderItem(rank: 1, name: 'FLOYD', score: 2845),
        _Top3LeaderItem(rank: 2, name: 'SARIKA', score: 2420),
        _Top3LeaderItem(rank: 3, name: 'LARA', score: 1950),
      ];
    }

    final parsed = <_Top3LeaderItem>[];

    for (final doc in docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;

      Map<String, dynamic> stats = {};
      if (data['stats'] is Map) {
        stats = Map<String, dynamic>.from(data['stats']);
      }

      String name = (data['displayName'] as String?) ??
          (data['name'] as String?) ??
          (stats['displayName'] as String?) ??
          'GARDENER';
      if (name.trim().isEmpty) name = 'GARDENER';
      name = name.trim().toUpperCase().split(' ').first;

      final highestScore = (data['highestScore'] as num?)?.toInt() ??
          (stats['highestScore'] as num?)?.toInt() ??
          (data['totalScore'] as num?)?.toInt() ??
          (stats['totalScore'] as num?)?.toInt() ??
          (data['score'] as num?)?.toInt() ??
          0;

      final photoUrl = (data['photoUrl'] as String?) ?? (data['avatarUrl'] as String?);

      parsed.add(_Top3LeaderItem(
        rank: 0,
        name: name,
        score: highestScore,
        photoUrl: photoUrl,
      ));
    }

    parsed.sort((a, b) => b.score.compareTo(a.score));

    // Pad with fallbacks if fewer than 3 records exist
    final fallbacks = const [
      _Top3LeaderItem(rank: 1, name: 'FLOYD', score: 2845),
      _Top3LeaderItem(rank: 2, name: 'SARIKA', score: 2420),
      _Top3LeaderItem(rank: 3, name: 'LARA', score: 1950),
    ];

    final result = <_Top3LeaderItem>[];
    for (int i = 0; i < 3; i++) {
      if (i < parsed.length && parsed[i].score > 0) {
        result.add(_Top3LeaderItem(
          rank: i + 1,
          name: parsed[i].name,
          score: parsed[i].score,
          photoUrl: parsed[i].photoUrl,
        ));
      } else {
        result.add(fallbacks[i]);
      }
    }

    return result;
  }

  Widget _buildCard(BuildContext context, List<_Top3LeaderItem> leaders) {
    final leader1 = leaders.firstWhere((e) => e.rank == 1, orElse: () => leaders[0]);
    final leader2 = leaders.firstWhere((e) => e.rank == 2, orElse: () => leaders.length > 1 ? leaders[1] : leaders[0]);
    final leader3 = leaders.firstWhere((e) => e.rank == 3, orElse: () => leaders.length > 2 ? leaders[2] : leaders[0]);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          AudioService.instance.playClickSound();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaderboardView(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF001530).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFC800).withValues(alpha: 0.65),
              width: 1.2,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/leaderboard_icons/back_design.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              opacity: 0.08,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFFFC800).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini Header: Trophy / Star + Title + "ALL ›"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 13,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TOP GARDENERS',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SEE ALL',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.80),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // The 3-Pillar Olympic Podium Row: [2 (Left)] [1 (Center, Tallest)] [3 (Right)]
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Rank 2: Left Pillar
                  Expanded(
                    child: _buildPodiumSlot(
                      item: leader2,
                      pillarHeight: 30.0,
                      pillarGradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEA8665), Color(0xFFC75535)],
                      ),
                      borderColor: const Color(0xFFE0E0E0),
                      avatarBg: const Color(0xFF6C3B2D),
                      crownAsset: 'assets/leaderboard_icons/silver_crown.png',
                      isFirstPlace: false,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Rank 1: Center Pillar (Tallest)
                  Expanded(
                    child: _buildPodiumSlot(
                      item: leader1,
                      pillarHeight: 44.0,
                      pillarGradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF7A5AF8), Color(0xFF4930BD)],
                      ),
                      borderColor: const Color(0xFFFFD54F),
                      avatarBg: const Color(0xFF3B2879),
                      crownAsset: 'assets/leaderboard_icons/gold_crown.png',
                      isFirstPlace: true,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Rank 3: Right Pillar
                  Expanded(
                    child: _buildPodiumSlot(
                      item: leader3,
                      pillarHeight: 22.0,
                      pillarGradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEA8665), Color(0xFFC75535)],
                      ),
                      borderColor: const Color(0xFFCD7F32),
                      avatarBg: const Color(0xFF6C3B2D),
                      crownAsset: 'assets/leaderboard_icons/platinum_crown.png',
                      isFirstPlace: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single podium column with Avatar, Name, Score Pill, and Numbered Pillar
  Widget _buildPodiumSlot({
    required _Top3LeaderItem item,
    required double pillarHeight,
    required Gradient pillarGradient,
    required Color borderColor,
    required Color avatarBg,
    required String crownAsset,
    required bool isFirstPlace,
  }) {
    final double avatarSize = isFirstPlace ? 28.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Stack with Crown badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Circular Avatar Frame
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarBg,
                border: Border.all(
                  color: borderColor,
                  width: isFirstPlace ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: item.photoUrl != null && item.photoUrl!.isNotEmpty
                    ? Image.network(
                        item.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildInitials(item.name, isFirstPlace),
                      )
                    : _buildInitials(item.name, isFirstPlace),
              ),
            ),

            // Top Crown Badge
            Positioned(
              top: isFirstPlace ? -9 : -7,
              child: Image.asset(
                crownAsset,
                width: isFirstPlace ? 15 : 12,
                height: isFirstPlace ? 15 : 12,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Player Name (Gracefully truncated)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.chakraPetch(
              fontSize: isFirstPlace ? 9.5 : 8.5,
              fontWeight: isFirstPlace ? FontWeight.w800 : FontWeight.w600,
              color: isFirstPlace ? const Color(0xFFFFEC99) : Colors.white.withValues(alpha: 0.95),
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Podium Pillar with Rank Number
        Container(
          width: double.infinity,
          height: pillarHeight,
          decoration: BoxDecoration(
            gradient: pillarGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${item.rank}',
            style: GoogleFonts.chakraPetch(
              fontSize: isFirstPlace ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Initial letter fallback when no user photo exists
  Widget _buildInitials(String name, bool isFirstPlace) {
    final letter = name.isNotEmpty ? name[0] : 'G';
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.chakraPetch(
          fontSize: isFirstPlace ? 13 : 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
