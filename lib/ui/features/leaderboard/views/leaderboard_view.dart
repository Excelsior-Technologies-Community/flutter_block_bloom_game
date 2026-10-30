import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:block_bloom/ui/core/widgets/floral_header_title.dart';
import 'package:block_bloom/ui/core/widgets/game_avatar_widget.dart';
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
class _RawUserRecord {
  final String id;
  final String name;
  final int highestScore;
  final int totalScore;
  final bool isUser;
  final String? photoUrl;

  const _RawUserRecord({
    required this.id,
    required this.name,
    required this.highestScore,
    required this.totalScore,
    required this.isUser,
    this.photoUrl,
  });
}

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  int _selectedTab = 0; // 0 = WEEKLY, 1 = GLOBAL

  late Future<UserProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = ref.read(progressRepositoryProvider).getProgress();
    _syncCurrentUserToFirestore();
  }

  /// Syncs current user's latest progress & display name to Cloud Firestore doc
  Future<void> _syncCurrentUserToFirestore() async {
    try {
      final currentUser = ref.read(authViewModelProvider).user;
      final currentUserId = currentUser?.uid;
      final currentUserName = (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty)
          ? currentUser.displayName!.trim()
          : (currentUser?.email != null && currentUser!.email!.contains('@')
              ? currentUser.email!.split('@').first
              : '');
      final currentUserPhoto = currentUser?.photoUrl;

      if (currentUserId != null && currentUserId.isNotEmpty) {
        final progress = await ref.read(progressRepositoryProvider).getProgress();
        await ref.read(progressRepositoryProvider).saveProgress(
          progress,
          displayName: currentUserName,
          photoUrl: currentUserPhoto,
        );
      }
    } catch (e) {
      debugPrint('Leaderboard current user sync note: $e');
    }
  }

  /// Extracts clean display name matching exact Settings readableName logic
  String _extractDisplayName(Map<String, dynamic> data, Map<String, dynamic> stats, String docId, bool isUser, String currentUserName) {
    String? rawName = (data['displayName'] as String?) ??
        (data['name'] as String?) ??
        (data['userName'] as String?) ??
        (data['username'] as String?) ??
        (stats['displayName'] as String?) ??
        (stats['name'] as String?) ??
        (stats['userName'] as String?) ??
        (stats['username'] as String?);

    if (rawName != null && rawName.trim().isNotEmpty) {
      return rawName.trim().toUpperCase();
    }

    String? rawEmail = (data['email'] as String?) ?? (stats['email'] as String?);
    if (rawEmail != null && rawEmail.contains('@')) {
      return rawEmail.split('@').first.trim().toUpperCase();
    }

    final isGuest = (data['isGuest'] as bool?) ?? (stats['isGuest'] as bool?) ?? false;
    if (isGuest) {
      return 'GUEST PLAYER';
    }

    if (isUser && currentUserName.trim().isNotEmpty) {
      return currentUserName.trim().toUpperCase();
    }

    return 'GARDENER';
  }

  /// Processes raw Firestore docs into display data for active tab (0 = WEEKLY, 1 = GLOBAL)
  _LeaderboardDisplayData _processSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    UserProgress? progress,
    String currentUserName,
    String? currentUserId,
    String? currentUserPhoto,
  ) {
    final localHighest = progress?.highestScore ?? 0;
    final localTotal = progress?.totalScore ?? 0;
    final userCleanName = (currentUserName.isNotEmpty ? currentUserName : 'YOU').toUpperCase();

    final recordsMap = <String, _RawUserRecord>{};

    for (final doc in docs) {
      final data = doc.data();
      if (data['isDeleted'] == true) continue;
      final id = doc.id;
      final isUser = currentUserId != null && currentUserId.isNotEmpty && (id == currentUserId || data['uid'] == currentUserId);

      Map<String, dynamic> stats = {};
      if (data['stats'] is Map) {
        stats = Map<String, dynamic>.from(data['stats']);
      }

      final displayName = _extractDisplayName(data, stats, id, isUser, userCleanName);

      final highestScore = (data['highestScore'] as num?)?.toInt() ??
          (stats['highestScore'] as num?)?.toInt() ??
          (data['totalScore'] as num?)?.toInt() ??
          (stats['totalScore'] as num?)?.toInt() ??
          (data['score'] as num?)?.toInt() ??
          (stats['score'] as num?)?.toInt() ??
          0;

      final totalScore = (data['totalScore'] as num?)?.toInt() ??
          (stats['totalScore'] as num?)?.toInt() ??
          highestScore;

      final docPhoto = (data['photoUrl'] as String?) ??
          (data['photoURL'] as String?) ??
          (data['avatarUrl'] as String?) ??
          (stats['photoUrl'] as String?) ??
          (stats['photoURL'] as String?) ??
          (stats['avatarUrl'] as String?);

      final resolvedPhoto = (isUser && currentUserPhoto != null && currentUserPhoto.isNotEmpty)
          ? currentUserPhoto
          : docPhoto;

      final userDocId = isUser ? currentUserId : id;

      if (recordsMap.containsKey(userDocId)) {
        final existing = recordsMap[userDocId]!;
        recordsMap[userDocId] = _RawUserRecord(
          id: existing.id,
          name: isUser ? userCleanName : (displayName.isNotEmpty ? displayName : existing.name),
          highestScore: math.max(existing.highestScore, highestScore),
          totalScore: math.max(existing.totalScore, totalScore),
          isUser: isUser || existing.isUser,
          photoUrl: resolvedPhoto ?? existing.photoUrl,
        );
      } else {
        recordsMap[userDocId] = _RawUserRecord(
          id: userDocId,
          name: isUser ? userCleanName : displayName,
          highestScore: highestScore,
          totalScore: totalScore,
          isUser: isUser,
          photoUrl: resolvedPhoto,
        );
      }
    }

    // Always ensure current logged-in user exists in records
    if (currentUserId != null && currentUserId.isNotEmpty) {
      if (recordsMap.containsKey(currentUserId)) {
        final existing = recordsMap[currentUserId]!;
        recordsMap[currentUserId] = _RawUserRecord(
          id: currentUserId,
          name: userCleanName,
          highestScore: math.max(existing.highestScore, localHighest),
          totalScore: math.max(existing.totalScore, localTotal),
          isUser: true,
          photoUrl: currentUserPhoto ?? existing.photoUrl,
        );
      } else {
        recordsMap[currentUserId] = _RawUserRecord(
          id: currentUserId,
          name: userCleanName,
          highestScore: localHighest,
          totalScore: localTotal,
          isUser: true,
          photoUrl: currentUserPhoto,
        );
      }
    }

    final rawList = recordsMap.values.toList();

    // Evaluate entries based on active tab (0 = WEEKLY highestScore, 1 = GLOBAL totalScore)
    final evaluatedList = rawList.map((rec) {
      final score = _selectedTab == 0 ? rec.highestScore : rec.totalScore;
      return _LeaderboardEntry(
        name: rec.name,
        score: score,
        rank: 0,
        photoUrl: rec.photoUrl,
        id: rec.id,
        isUser: rec.isUser,
      );
    }).toList();

    // Sort descending by score
    evaluatedList.sort((a, b) => b.score.compareTo(a.score));

    final processedList = <_LeaderboardEntry>[];
    int userRank = evaluatedList.length;
    int userScore = _selectedTab == 0 ? localHighest : localTotal;

    for (int i = 0; i < evaluatedList.length; i++) {
      final rankNum = i + 1;
      final crown = rankNum == 1
          ? 'assets/leaderboard_icons/gold_crown.png'
          : (rankNum == 2
              ? 'assets/leaderboard_icons/silver_crown.png'
              : (rankNum == 3
                  ? 'assets/leaderboard_icons/platinum_crown.png'
                  : null));

      final item = _LeaderboardEntry(
        name: evaluatedList[i].name,
        score: evaluatedList[i].score,
        rank: rankNum,
        crownAsset: crown,
        photoUrl: evaluatedList[i].photoUrl,
        id: evaluatedList[i].id,
        isUser: evaluatedList[i].isUser,
      );

      processedList.add(item);
      if (item.isUser) {
        userRank = rankNum;
        userScore = item.score;
      }
    }

    final top10List = processedList.take(10).toList();
    final isUserInTopList = top10List.any((e) => e.isUser);

    String? userPhotoUrl = currentUserPhoto;
    if (userPhotoUrl == null || userPhotoUrl.isEmpty) {
      final userEntry = processedList.where((e) => e.isUser).firstOrNull;
      userPhotoUrl = userEntry?.photoUrl;
    }

    return _LeaderboardDisplayData(
      top10List: top10List,
      userRank: userRank,
      userScore: userScore,
      userName: userCleanName,
      userPhotoUrl: userPhotoUrl,
      isUserInTopList: isUserInTopList,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final userName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : '');
    final userPhoto = user?.photoUrl;

    return FutureBuilder<UserProgress>(
      future: _progressFuture,
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data;
        final currentUserId = authState.user?.uid;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, firestoreSnapshot) {
            final docs = firestoreSnapshot.data?.docs ?? [];
            final displayData = _processSnapshot(docs, progress, userName, currentUserId, userPhoto);

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
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 36,
                                                    child: Center(
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
                                              itemCount: displayData.top10List.length,
                                              separatorBuilder: (context, index) => const SizedBox(height: 5),
                                              itemBuilder: (context, index) {
                                                final item = displayData.top10List[index];
                                                return _buildLeaderboardRow(item);
                                              },
                                            ),

                                            // Highlighted Bottom "YOU" Row (Rectangle 60 Specs) - Only if user is outside top displayed list
                                            if (!displayData.isUserInTopList) ...[
                                              const SizedBox(height: 8),
                                              _buildHighlightUserRow(
                                                rank: displayData.userRank,
                                                name: displayData.userName,
                                                score: displayData.userScore,
                                                photoUrl: displayData.userPhotoUrl,
                                              ),
                                            ],
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
    final isUser = entry.isUser;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF002855) : const Color(0xFF001834),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUser ? const Color(0xFFFFC800) : const Color(0xFFFFC800).withValues(alpha: 0.8),
          width: isUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // 1. Rank Column: Crown PNG icon for Top 3 (as previous) OR properly centered Number for Ranks 4-10
          SizedBox(
            width: 36,
            child: Center(
              child: entry.crownAsset != null
                  ? Image.asset(
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
                    )
                  : Text(
                      '${entry.rank}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isUser ? const Color(0xFFFFC800) : Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. Circular Actual User Profile Avatar (right of the rank / crown / number)
          _buildUserAvatar(
            photoUrl: entry.photoUrl,
            name: entry.name,
            isUser: isUser,
          ),

          const SizedBox(width: 8),

          // 3. Player Name Column
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.chakraPetch(
                fontSize: 13,
                fontWeight: isUser ? FontWeight.w900 : FontWeight.w700,
                color: isUser ? const Color(0xFFFFC800) : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 4. Score Column
          Text(
            _formatScore(entry.score),
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: isUser ? FontWeight.w900 : FontWeight.w800,
              color: isUser ? const Color(0xFFFFC800) : Colors.white,
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
    String? photoUrl,
  }) {
    final crownAsset = rank == 1
        ? 'assets/leaderboard_icons/gold_crown.png'
        : (rank == 2
            ? 'assets/leaderboard_icons/silver_crown.png'
            : (rank == 3
                ? 'assets/leaderboard_icons/platinum_crown.png'
                : null));

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
          // User Rank: Crown if top 3, otherwise properly centered number
          SizedBox(
            width: 36,
            child: Center(
              child: crownAsset != null
                  ? Image.asset(
                      crownAsset,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.workspace_premium_rounded,
                        color: rank == 1
                            ? const Color(0xFFFFC800)
                            : (rank == 2
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFFFFAB40)),
                        size: 20,
                      ),
                    )
                  : Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chakraPetch(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // User Profile Avatar (right of the number / rank)
          _buildUserAvatar(
            photoUrl: photoUrl,
            name: name,
            isUser: true,
            isHighlightRow: true,
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

  /// Circular actual user profile avatar supporting Google profile picture, catalog avatars, local files, and initial fallback
  Widget _buildUserAvatar({
    required String? photoUrl,
    required String name,
    required bool isUser,
    bool isHighlightRow = false,
  }) {
    final borderColor = isHighlightRow
        ? const Color(0xFF001834)
        : (isUser ? const Color(0xFFFFC800) : const Color(0xFFFFC800).withValues(alpha: 0.7));

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00152F),
        border: Border.all(
          color: borderColor,
          width: isUser ? 1.3 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: GameAvatarWidget(
          avatarIdOrUrl: photoUrl,
          fallbackLetter: name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '🌸',
          size: 24,
          showBorder: false,
        ),
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
  final String? photoUrl;
  final String id;
  final bool isUser;

  const _LeaderboardEntry({
    required this.name,
    required this.score,
    required this.rank,
    this.crownAsset,
    this.photoUrl,
    this.id = '',
    this.isUser = false,
  });
}

class _LeaderboardDisplayData {
  final List<_LeaderboardEntry> top10List;
  final int userRank;
  final int userScore;
  final String userName;
  final String? userPhotoUrl;
  final bool isUserInTopList;

  const _LeaderboardDisplayData({
    required this.top10List,
    required this.userRank,
    required this.userScore,
    required this.userName,
    this.userPhotoUrl,
    required this.isUserInTopList,
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
