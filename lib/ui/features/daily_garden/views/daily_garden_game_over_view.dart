import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:block_bloom/domain/models/user_progress.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/providers.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/board_template.dart';

/// Daily Garden Game Over Screen (Screen 3 from design)
/// Shows arched "GAME OVER" title, TODAY'S TOP 10 Leaderboard card with
/// live Firestore leaderboard scores & highlighted gold "You" row,
/// YOUR SCORE & 3-column stats card, and BACK TO HOME text link.
class DailyGardenGameOverView extends ConsumerStatefulWidget {
  const DailyGardenGameOverView({
    super.key,
    this.onHome,
    this.onDailyGarden,
  });

  final VoidCallback? onHome;
  final VoidCallback? onDailyGarden;

  @override
  ConsumerState<DailyGardenGameOverView> createState() => _DailyGardenGameOverViewState();
}

class _DailyGardenGameOverViewState extends ConsumerState<DailyGardenGameOverView> {
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _recordDailyProgressAndSync());
  }

  Future<void> _recordDailyProgressAndSync() async {
    if (_hasSaved) return;
    _hasSaved = true;

    try {
      final state = ref.read(gameViewModelProvider);
      final repo = ref.read(progressRepositoryProvider);
      final today = repo.getTodayDateString();
      if (state.isDailyMode && (state.score > 0 || state.sessionFlowersEarned > 0)) {
        await repo.saveDailyScore(
          state.score,
          today,
          flowers: state.sessionFlowersEarned,
          blooms: state.totalClears,
          maxCombo: state.maxComboCount,
          isFinal: true,
        );
      }
    } catch (e) {
      debugPrint('Error recording daily score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameViewModelProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final currentUser = ref.watch(authViewModelProvider).user;
    final currentUserId = currentUser?.uid ?? '';
    final currentUserName = (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty)
        ? currentUser.displayName!.trim()
        : (currentUser?.email != null && currentUser!.email!.contains('@')
            ? currentUser.email!.split('@').first
            : 'YOU');

    final isCurrentGameActiveDaily = state.isDailyMode && (state.score > 0 || state.sessionFlowersEarned > 0 || state.totalClears > 0 || state.maxComboCount > 0);

    final todayStr = progressRepo.getTodayDateString();

    return FutureBuilder<UserProgress>(
      future: progressRepo.getProgress(),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final isPlayedToday = progress != null && progress.lastDailyPlayedDate == todayStr;
        final savedDailyScore = isPlayedToday ? progress.dailyBestScore : 0;
        final savedDailyFlowers = isPlayedToday ? progress.dailyFlowers : 0;
        final savedDailyBlooms = isPlayedToday ? progress.dailyBlooms : 0;
        final savedDailyMaxCombo = isPlayedToday ? progress.dailyMaxCombo : 0;

        final displayScore = isCurrentGameActiveDaily ? state.score : savedDailyScore;
        final displayFlowers = isCurrentGameActiveDaily ? state.sessionFlowersEarned : savedDailyFlowers;
        final displayBlooms = isCurrentGameActiveDaily ? state.totalClears : savedDailyBlooms;
        final displayMaxCombo = isCurrentGameActiveDaily ? state.maxComboCount : savedDailyMaxCombo;

        return Scaffold(
          backgroundColor: const Color(0xFF05001C),
          body: Stack(
            children: [
              // Fullscreen Daily Garden Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/daily_garden_back.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF05001C),
                  ),
                ),
              ),

              // Gradient Overlay
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

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Arched Title: GAME OVER
                          const FloralHeaderTitle(
                            title: 'GAME OVER',
                            fontSize: 34.0,
                            flowerSize: 42.0,
                            curveAmount: 16.0,
                            verticalOffset: -22.0,
                            letterSpacing: 2.0,
                          ),

                          const SizedBox(height: 24),

                          // 2. TODAY'S TOP 10 Leaderboard Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF001834),
                              borderRadius: BorderRadius.circular(18),
                              image: const DecorationImage(
                                image: AssetImage('assets/leaderboard_icons/back_design.png'),
                                fit: BoxFit.none,
                                repeat: ImageRepeat.repeat,
                                alignment: Alignment.center,
                                scale: 2.8,
                                colorFilter: ColorFilter.mode(
                                  Color(0xFF001834),
                                  BlendMode.modulate,
                                ),
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFC800),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x88000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                child: Column(
                                  children: [
                                    // Header: TODAY'S TOP 10
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                      child: Text(
                                        "TODAY'S TOP 10",
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Dynamic Firestore Leaderboard Rows
                                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                                      builder: (context, firestoreSnapshot) {
                                        final entries = _buildLeaderboardEntries(
                                          firestoreSnapshot.data?.docs ?? [],
                                          currentUserId: currentUserId,
                                          currentUserName: currentUserName,
                                          userScore: displayScore,
                                          todayDateString: todayStr,
                                        );

                                        return Column(
                                          children: [
                                            for (int i = 0; i < entries.length; i++) ...[
                                              if (i > 0) const SizedBox(height: 8),
                                              _renderLeaderboardRowItem(
                                                rank: i + 1,
                                                entry: entries[i],
                                                displayScore: displayScore,
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 3. YOUR SCORE & Stats Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF001834),
                              borderRadius: BorderRadius.circular(18),
                              image: const DecorationImage(
                                image: AssetImage('assets/leaderboard_icons/back_design.png'),
                                fit: BoxFit.none,
                                repeat: ImageRepeat.repeat,
                                alignment: Alignment.center,
                                scale: 2.8,
                                colorFilter: ColorFilter.mode(
                                  Color(0xFF001834),
                                  BlendMode.modulate,
                                ),
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFC800),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x88000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                child: Column(
                                  children: [
                                    // Today's Arena Badge
                                    Builder(
                                      builder: (context) {
                                        final todayTemplate = BoardTemplate.getDailyTemplate(DateTime.now());
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00142A).withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0xFFFFC800).withValues(alpha: 0.6),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(todayTemplate.emoji, style: const TextStyle(fontSize: 12)),
                                              const SizedBox(width: 5),
                                              Text(
                                                todayTemplate.name.toUpperCase(),
                                                style: GoogleFonts.chakraPetch(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFFFD54F),
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    // YOUR SCORE Header
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                      child: Text(
                                        'YOUR SCORE',
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Score Display
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                      child: Text(
                                        _formatScore(displayScore),
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // 3 Columns: FLOWERS, BLOOM, MAX COMBO
                                    Row(
                                      children: [
                                        // Column 1: FLOWERS
                                        Expanded(
                                          child: _buildStatItem(
                                            icon: Image.asset(
                                              'assets/game_flower.png',
                                              width: 26,
                                              height: 26,
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, st) => Image.asset(
                                                'assets/flower.png',
                                                width: 26,
                                                height: 26,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c2, e2, s2) => const Text('🌸', style: TextStyle(fontSize: 20)),
                                              ),
                                            ),
                                            label: 'FLOWERS',
                                            value: '+$displayFlowers',
                                          ),
                                        ),

                                        // Vertical Divider
                                        Container(height: 46, width: 1, color: const Color(0xFF814D00)),

                                        // Column 2: BLOOM
                                        Expanded(
                                          child: _buildStatItem(
                                            icon: Image.asset(
                                              'assets/game_leaf.png',
                                              width: 26,
                                              height: 26,
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, st) => Image.asset(
                                                'assets/leaf.png',
                                                width: 26,
                                                height: 26,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c2, e2, s2) => const Text('🌱', style: TextStyle(fontSize: 20)),
                                              ),
                                            ),
                                            label: 'BLOOM',
                                            value: '$displayBlooms',
                                          ),
                                        ),

                                        // Vertical Divider
                                        Container(height: 46, width: 1, color: const Color(0xFF814D00)),

                                        // Column 3: MAX COMBO
                                        Expanded(
                                          child: _buildStatItem(
                                            icon: const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFC800),
                                              size: 28,
                                            ),
                                            label: 'MAX COMBO',
                                            value: 'X$displayMaxCombo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // 4. Navigation Links: DAILY GARDEN & BACK TO HOME
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AudioService.instance.playClickSound();
                                  if (widget.onDailyGarden != null) {
                                    widget.onDailyGarden!();
                                  } else {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  'DAILY GARDEN',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2096E7),
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF2096E7),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '•',
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2096E7),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  AudioService.instance.playClickSound();
                                  if (widget.onHome != null) {
                                    widget.onHome!();
                                  } else {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                },
                                child: Text(
                                  'BACK TO HOME',
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2096E7),
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF2096E7),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  /// Parses Firestore docs + current user score into sorted top entries
  List<_DailyLeaderboardItem> _buildLeaderboardEntries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String currentUserId,
    required String currentUserName,
    required int userScore,
    required String todayDateString,
  }) {
    final Map<String, _DailyLeaderboardItem> map = {};

    for (final doc in docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;
      final id = doc.id;
      final isUser = (currentUserId.isNotEmpty && (id == currentUserId || data['uid'] == currentUserId));

      String name = (data['displayName'] as String?) ?? (data['name'] as String?) ?? '';
      if (name.trim().isEmpty) {
        final email = (data['email'] as String?) ?? '';
        name = email.contains('@') ? email.split('@').first : 'Gardener';
      }

      Map<String, dynamic> stats = {};
      if (data['stats'] is Map) {
        stats = Map<String, dynamic>.from(data['stats']);
      }

      final lastDate = (data['lastDailyPlayedDate'] as String?) ??
          (stats['lastDailyPlayedDate'] as String?) ??
          '';

      final isToday = (lastDate == todayDateString && lastDate.isNotEmpty);

      final rawScore = (data['dailyBestScore'] as num?)?.toInt() ??
          (stats['dailyBestScore'] as num?)?.toInt() ??
          0;

      final score = isToday ? rawScore : 0;
      final finalScore = isUser ? math.max(score, userScore) : score;
      final finalName = isUser ? currentUserName : name;

      final key = isUser ? currentUserId : id;
      map[key] = _DailyLeaderboardItem(
        name: finalName,
        score: finalScore,
        isUser: isUser,
      );
    }

    // Ensure current user is present
    if (currentUserId.isNotEmpty && !map.containsKey(currentUserId)) {
      map[currentUserId] = _DailyLeaderboardItem(
        name: currentUserName,
        score: userScore,
        isUser: true,
      );
    }

    // Default fallback entries with realistic baseline scores if list has fewer than 5 entries
    final fallbackEntries = [
      _DailyLeaderboardItem(name: 'FLORA QUEEN', score: 15000, isUser: false),
      _DailyLeaderboardItem(name: 'BLOOM MASTER', score: 12000, isUser: false),
      _DailyLeaderboardItem(name: 'GARDEN ACE', score: 9500, isUser: false),
      _DailyLeaderboardItem(name: 'PETAL PRO', score: 7200, isUser: false),
    ];

    for (final fallback in fallbackEntries) {
      if (map.length >= 5) break;
      if (!map.containsKey(fallback.name)) {
        map[fallback.name] = fallback;
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => b.score.compareTo(a.score));

    return list.take(5).toList();
  }

  Widget _renderLeaderboardRowItem({
    required int rank,
    required _DailyLeaderboardItem entry,
    required int displayScore,
  }) {
    final crownAsset = rank == 1
        ? 'assets/leaderboard_icons/gold_crown.png'
        : (rank == 2
            ? 'assets/leaderboard_icons/silver_crown.png'
            : (rank == 3
                ? 'assets/leaderboard_icons/platinum_crown.png'
                : null));

    if (entry.isUser) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE9CC70), Color(0xFFFFC610)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
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
            SizedBox(
              width: 24,
              child: crownAsset != null
                  ? Center(
                      child: Image.asset(
                        crownAsset,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      '$rank.',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Text(
              'You',
              style: GoogleFonts.chakraPetch(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              _formatScore(entry.score > 0 ? entry.score : displayScore),
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

    return _buildLeaderboardRow(
      rank: rank,
      crownAsset: crownAsset,
      name: entry.name,
      score: _formatScore(entry.score),
    );
  }

  Widget _buildLeaderboardRow({
    required int rank,
    String? crownAsset,
    required String name,
    required String score,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001834),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2096E7).withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: crownAsset != null
                ? Center(
                    child: Image.asset(
                      crownAsset,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.workspace_premium_rounded,
                        color: rank == 1
                            ? const Color(0xFFFFC800)
                            : (rank == 2 ? const Color(0xFFE0E0E0) : const Color(0xFFFFAB40)),
                        size: 20,
                      ),
                    ),
                  )
                : Text(
                    '$rank.',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2096E7),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Text(
            name,
            style: GoogleFonts.chakraPetch(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB0C4DE),
            ),
          ),
          const Spacer(),
          Text(
            score,
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2096E7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28, child: Center(child: icon)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.chakraPetch(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFC800),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFC610)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            value,
            style: GoogleFonts.chakraPetch(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
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

class _DailyLeaderboardItem {
  final String name;
  final int score;
  final bool isUser;

  _DailyLeaderboardItem({
    required this.name,
    required this.score,
    required this.isUser,
  });
}
