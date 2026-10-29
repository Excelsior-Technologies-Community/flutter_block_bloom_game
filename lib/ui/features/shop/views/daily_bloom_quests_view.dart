import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/bloom_quest_model.dart';
import 'package:block_bloom/ui/features/shop/widgets/daily_booster_wheel_dialog.dart';
import 'package:block_bloom/ui/providers.dart';

/// Opens the authentic Block Bloom Daily Quests & Booster Wheel View
Future<void> showDailyBloomQuests(BuildContext context) {
  HapticFeedback.lightImpact();
  AudioService.instance.playClickSound();

  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const DailyBloomQuestsView(),
    ),
  );
}

class DailyBloomQuestsView extends ConsumerStatefulWidget {
  const DailyBloomQuestsView({super.key});

  @override
  ConsumerState<DailyBloomQuestsView> createState() => _DailyBloomQuestsViewState();
}

class _DailyBloomQuestsViewState extends ConsumerState<DailyBloomQuestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ConfettiController _confettiController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _formatCooldown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(homeViewModelProvider).progress;
    final repo = ref.watch(progressRepositoryProvider);

    final isFreeWheel = repo.isBoosterWheelFreeSpinAvailable();
    final wheelCooldown = repo.getBoosterWheelRemainingCooldown();
    final completedDailyCount = repo.getCompletedDailyQuestsCount();
    final isChestClaimed = repo.isDailyBloomChestClaimed();
    final canClaimChest = completedDailyCount >= 3 && !isChestClaimed;

    return Scaffold(
      backgroundColor: const Color(0xFF001124),
      body: Stack(
        children: [
          // 1. Deep Royal Night Garden Backdrop
          Positioned.fill(
            child: Image.asset(
              'assets/splash_img.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF001124).withValues(alpha: 0.88),
            ),
          ),

          // 2. Confetti Particle Explosion Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 45,
              colors: const [
                Color(0xFFFF4081),
                Color(0xFFFFD54F),
                Color(0xFF38BDF8),
                Color(0xFF10B981),
                Color(0xFFA855F7),
                Colors.white,
              ],
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Header Row with Back Button & Real Currency Badges
                _buildTopBar(progress?.flowers ?? 0, progress?.gems ?? 0),

                const SizedBox(height: 10),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Feature: Daily Booster Wheel Card
                        _buildDailyBoosterWheelHero(isFreeWheel, wheelCooldown),

                        const SizedBox(height: 14),

                        // Milestone Mystery Bloom Chest (Complete 3 Quests)
                        _buildDailyChestMilestone(
                          completedCount: completedDailyCount,
                          isClaimed: isChestClaimed,
                          canClaim: canClaimChest,
                          onClaim: () async {
                            await repo.claimDailyBloomChest();
                            _confettiController.play();
                            AudioService.instance.playClearSound();
                            HapticFeedback.heavyImpact();
                            _showToast('Unlocked Mystery Chest: +100 🌸, +25 💎, +1 🔨 Hammer!');
                          },
                        ),

                        const SizedBox(height: 18),

                        // Tab Selection (Daily Tasks vs Weekly Milestones)
                        _buildTabBar(),

                        const SizedBox(height: 14),

                        // Quest Cards List
                        _buildQuestsList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP BAR
  // =========================================================================

  Widget _buildTopBar(int flowers, int gems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              AudioService.instance.playClickSound();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF002244).withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),

          // Title
          Text(
            'BLOOM QUESTS',
            style: GoogleFonts.chakraPetch(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(color: Color(0xFFFFD54F), blurRadius: 10),
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),

          // Live Currency Indicators (Flowers & Gems)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flowers Pill
              _buildCurrencyPill('🌸', '$flowers', const Color(0xFFFF80AB)),
              const SizedBox(width: 8),
              // Gems Pill
              _buildCurrencyPill('💎', '$gems', const Color(0xFF38BDF8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill(String emoji, String amount, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            amount,
            style: GoogleFonts.sniglet(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HERO FEATURE: DAILY BOOSTER WHEEL CARD
  // =========================================================================

  Widget _buildDailyBoosterWheelHero(bool isFree, Duration cooldown) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00274D), Color(0xFF001830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isFree ? const Color(0xFFFFD54F) : const Color(0xFF0284C7),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (isFree)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        children: [
          // 3D Mini Wheel Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF80AB), Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🎡', style: TextStyle(fontSize: 32)),
            ),
          ),

          const SizedBox(width: 12),

          // Wheel Info & Countdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAILY BOOSTER WHEEL',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFree
                      ? 'Free Token Ready! Spin to win flowers & boosters!'
                      : 'Next free Token in ${_formatCooldown(cooldown)}',
                  style: GoogleFonts.sniglet(
                    fontSize: 12,
                    color: isFree ? const Color(0xFFFFD54F) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3D Emerald "SPIN" CTA Button
          GestureDetector(
            onTap: () async {
              await showDailyBoosterWheel(context);
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFree
                      ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                      : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isFree ? const Color(0xFF10B981) : const Color(0xFF0284C7))
                        .withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFree ? 'SPIN' : 'VIEW',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MILESTONE CHEST (Complete 3 Quests)
  // =========================================================================

  Widget _buildDailyChestMilestone({
    required int completedCount,
    required bool isClaimed,
    required bool canClaim,
    required VoidCallback onClaim,
  }) {
    const target = 3;
    final ratio = (completedCount / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF002244).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canClaim ? const Color(0xFFFFD54F) : const Color(0xFF1E3A8A),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY MYSTERY CHEST',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFD54F),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      isClaimed
                          ? 'Claimed today! Resets tomorrow.'
                          : 'Complete 3 daily quests to unlock (+100 🌸, +25 💎, +1 🔨)',
                      style: GoogleFonts.sniglet(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completedCount/$target',
                style: GoogleFonts.chakraPetch(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: canClaim ? const Color(0xFF10B981) : Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar & Claim Button
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: const Color(0xFF001530),
                    valueColor: AlwaysStoppedAnimation(
                      canClaim ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed
                      ? const Color(0xFF475569)
                      : (canClaim ? const Color(0xFF10B981) : const Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canClaim ? onClaim : null,
                child: Text(
                  isClaimed ? 'CLAIMED ✓' : (canClaim ? 'CLAIM CHEST' : 'LOCKED'),
                  style: GoogleFonts.chakraPetch(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB BAR
  // =========================================================================

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001A36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: GoogleFonts.chakraPetch(fontSize: 13, fontWeight: FontWeight.w900),
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(text: 'DAILY TASKS (24H)'),
          Tab(text: 'WEEKLY MILESTONES'),
        ],
      ),
    );
  }

  // =========================================================================
  // QUESTS LIST
  // =========================================================================

  Widget _buildQuestsList() {
    final repo = ref.watch(progressRepositoryProvider);
    final category = _tabController.index == 0
        ? BloomQuestCategory.daily
        : BloomQuestCategory.weekly;

    final quests = repo.getBloomQuests(category);

    return Column(
      children: quests.map((quest) {
        return _buildQuestCard(
          quest: quest,
          onClaim: () async {
            await repo.claimBloomQuest(quest);
            _confettiController.play();
            AudioService.instance.playClearSound();
            HapticFeedback.heavyImpact();
            _showToast('Claimed ${quest.rewardEmoji} +${quest.rewardAmount} for "${quest.title}"!');
            setState(() {});
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuestCard({
    required BloomQuest quest,
    required VoidCallback onClaim,
  }) {
    final bool isDone = quest.isCompleted;
    final bool isClaimed = quest.isClaimed;
    final bool canClaim = quest.canClaim;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF001E3D).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canClaim
              ? const Color(0xFF10B981)
              : (isDone ? const Color(0xFFFFD54F) : const Color(0xFF1E3A8A)),
          width: canClaim ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          if (canClaim)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quest Emoji Avatar Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF002F5E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canClaim ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                  ),
                ),
                child: Center(
                  child: Text(quest.iconEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),

              const SizedBox(width: 10),

              // Title, Description & Reward Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quest.title,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        // Reward Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002E5C),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                          ),
                          child: Text(
                            '${quest.rewardEmoji} +${quest.rewardAmount}',
                            style: GoogleFonts.sniglet(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.description,
                      style: GoogleFonts.sniglet(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar & Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: quest.progressRatio,
                        backgroundColor: const Color(0xFF001530),
                        valueColor: AlwaysStoppedAnimation(
                          canClaim ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quest.currentProgress} / ${quest.targetGoal}',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // CTA Button (CLAIM / CLAIMED / IN PROGRESS)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed
                      ? const Color(0xFF334155)
                      : (canClaim ? const Color(0xFF10B981) : const Color(0xFF1E293B)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: canClaim ? 4 : 0,
                ),
                onPressed: canClaim ? onClaim : null,
                child: Text(
                  isClaimed
                      ? 'CLAIMED ✓'
                      : (canClaim ? 'CLAIM' : '${(quest.progressRatio * 100).toInt()}%'),
                  style: GoogleFonts.chakraPetch(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: isClaimed ? const Color(0xFF94A3B8) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.sniglet(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

