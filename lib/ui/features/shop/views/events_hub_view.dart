import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:block_bloom/data/services/audio_service.dart';
import 'package:block_bloom/domain/models/arcade_event_model.dart';
import 'package:block_bloom/ui/features/shop/widgets/daily_booster_wheel_dialog.dart';
import 'package:block_bloom/ui/providers.dart';

/// Opens the Candy Crush-style Events & Quests Arcade Hub
Future<void> showEventsHub(BuildContext context) {
  HapticFeedback.mediumImpact();
  AudioService.instance.playClickSound();

  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const EventsHubView(),
    ),
  );
}

class EventsHubView extends ConsumerStatefulWidget {
  const EventsHubView({super.key});

  @override
  ConsumerState<EventsHubView> createState() => _EventsHubViewState();
}

class _EventsHubViewState extends ConsumerState<EventsHubView>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  Timer? _countdownTicker;
  Duration _wheelCooldown = Duration.zero;
  bool _isWheelFree = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _refreshTimers();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _refreshTimers();
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _refreshTimers() {
    final repo = ref.read(progressRepositoryProvider);
    setState(() {
      _isWheelFree = repo.isBoosterWheelFreeSpinAvailable();
      _wheelCooldown = repo.getBoosterWheelRemainingCooldown();
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(homeViewModelProvider).progress;
    final repo = ref.watch(progressRepositoryProvider);
    final festivalPetals = repo.getFestivalPetals();
    final isFloristBoxClaimed = repo.isFloristBoxClaimedToday();

    return Scaffold(
      backgroundColor: const Color(0xFF67CFE5),
      body: Stack(
        children: [
          // 1. Pastel Candy Cyan Vertical Striped Wallpaper
          Positioned.fill(
            child: CustomPaint(
              painter: CandyCyanStripesPainter(),
            ),
          ),

          // 2. Confetti Particle Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              colors: const [
                Color(0xFFFF4081),
                Color(0xFFFFD54F),
                Color(0xFF38BDF8),
                Color(0xFF10B981),
                Colors.white,
              ],
            ),
          ),

          // 3. Main Scrollable Arcade Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Arcade Status Bar (Hearts, Avatar, Gems, Settings)
                _buildTopArcadeBar(progress?.gems ?? 0),

                const SizedBox(height: 10),

                // Scrollable Events Feed
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Featured Hero Event Banner (Bloom Festival)
                        _buildHeroFestivalBanner(festivalPetals),

                        const SizedBox(height: 14),

                        // 2-Column Grid of Arcade Event Cards
                        _buildEventCardsGrid(isFloristBoxClaimed),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Folded Candy Ribbon Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomRibbonBar(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP ARCADE STATUS BAR
  // =========================================================================

  Widget _buildTopArcadeBar(int userGems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Mail Envelope Button
          _buildCircleIconButton(
            icon: Icons.mail_outline_rounded,
            badgeCount: 1,
            onTap: () {
              AudioService.instance.playClickSound();
              _showSimpleSnackbar('Mailbox: 1 New Gift from Daily Garden!');
            },
          ),

          // Energy / Hearts Pill (with countdown timer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF80AB), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFFE91E63)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  '5',
                  style: GoogleFonts.sniglet(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC2185B),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Full',
                  style: GoogleFonts.sniglet(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF880E4F),
                  ),
                ),
              ],
            ),
          ),

          // Center: Player Avatar Badge with Golden Crest
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/avatars/avatar_rose.jpg',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          // Gems / Gold Bar Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💎', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '$userGems',
                  style: GoogleFonts.sniglet(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),

          // Right: Glossy Close (X) / Settings Button
          _buildCircleIconButton(
            icon: Icons.close_rounded,
            onTap: () {
              AudioService.instance.playClickSound();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFFD81B60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF880E4F).withValues(alpha: 0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.sniglet(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // HERO FEATURED EVENT BANNER (Bloom Festival / Flower Harvest)
  // =========================================================================

  Widget _buildHeroFestivalBanner(int petals) {
    const maxPetals = 60;
    final ratio = (petals / maxPetals).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _showFestivalDetailsDialog,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Banner Top Artwork Container
            Container(
              height: 125,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF38BDF8),
                    Color(0xFFA855F7),
                    Color(0xFFFF4081),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Background God-Rays
                  CustomPaint(
                    size: const Size(360, 125),
                    painter: GodRaysPainter(
                      rayCount: 12,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),

                  // Carnival Mascot & Floral Art
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('🌸', style: TextStyle(fontSize: 48)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'BLOOM FESTIVAL',
                              style: GoogleFonts.cherryCreamSoda(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Harvest 60 Petals for Grand Chest!',
                            style: GoogleFonts.sniglet(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                      const Text('👑', style: TextStyle(fontSize: 46)),
                    ],
                  ),
                ],
              ),
            ),

            // Banner Bottom Sub-Pill with Milestone Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFDE8EF),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Petal Rush',
                        style: GoogleFonts.sniglet(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF880E4F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pink Bubble Counter matching Candy Crush (14/60)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4081), Color(0xFFD81B60)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD81B60).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$petals/$maxPetals 🌸',
                          style: GoogleFonts.sniglet(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Dual-tone glossy slider
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2-COLUMN ARCADE EVENT CARDS GRID
  // =========================================================================

  Widget _buildEventCardsGrid(bool isFloristBoxClaimed) {
    return Column(
      children: [
        // Row 1: Florist's Box (Left) & Season Pass (Right)
        Row(
          children: [
            Expanded(
              child: _buildFloristBoxCard(isFloristBoxClaimed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSeasonPassCard(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Row 2: Episode Race (Left) & Daily Treat Machine / Booster Wheel (Right)
        Row(
          children: [
            Expanded(
              child: _buildEpisodeRaceCard(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBoosterWheelCard(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Row 3: Daily Quests (Left) & Treasure Chest (Right)
        Row(
          children: [
            Expanded(
              child: _buildDailyQuestsCard(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTreasureChestCard(),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // CARD 1: FLORIST'S BOX (Baker's Box)
  // -------------------------------------------------------------------------
  Widget _buildFloristBoxCard(bool isClaimed) {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Treat Icon
          const SizedBox(height: 4),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A65).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🥐', style: TextStyle(fontSize: 32)),
            ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            "Baker's Box",
            style: GoogleFonts.sniglet(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 8),

          // Glossy Pink "Open" CTA Button matching Candy Crush
          GestureDetector(
            onTap: _showFloristBoxDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClaimed
                      ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                      : [const Color(0xFFFF4081), const Color(0xFFD81B60)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (isClaimed ? Colors.black26 : const Color(0xFF880E4F))
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isClaimed ? 'Opened' : 'Open',
                  style: GoogleFonts.cherryCreamSoda(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
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
  }

  // -------------------------------------------------------------------------
  // CARD 2: SEASON PASS
  // -------------------------------------------------------------------------
  Widget _buildSeasonPassCard() {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          // 3D Scalloped Pink Ticket
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🎟️', style: TextStyle(fontSize: 30)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Season Pass',
            style: GoogleFonts.sniglet(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 12),

          // Dual-Tone Blue Capsule Progress Slider
          GestureDetector(
            onTap: _showGardenPassDialog,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD6E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.65,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Tier 4/5',
                      style: GoogleFonts.sniglet(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD 3: EPISODE RACE
  // -------------------------------------------------------------------------
  Widget _buildEpisodeRaceCard() {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          // Checkered Flag & Gold Trophy #1
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 32)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Episode Race',
            style: GoogleFonts.sniglet(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 6),

          // Player Standing Badge with Avatar and '1'
          GestureDetector(
            onTap: _showEpisodeRaceDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF80AB), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 9,
                    backgroundImage: AssetImage('assets/avatars/avatar_rose.jpg'),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '1st Place',
                    style: GoogleFonts.cherryCreamSoda(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC2185B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD 4: DAILY TREAT MACHINE / BOOSTER WHEEL
  // -------------------------------------------------------------------------
  Widget _buildBoosterWheelCard() {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          // 3D Arcade Treat Machine / Wheel Icon
          GestureDetector(
            onTap: () async {
              await showDailyBoosterWheel(context);
              if (mounted) _refreshTimers();
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎡', style: TextStyle(fontSize: 32)),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Daily Booster Wheel',
            textAlign: TextAlign.center,
            style: GoogleFonts.sniglet(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 6),

          // Real-Time Countdown Timer with Stopwatch Icon
          GestureDetector(
            onTap: () async {
              await showDailyBoosterWheel(context);
              if (mounted) _refreshTimers();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isWheelFree ? const Color(0xFFD1FAE5) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isWheelFree ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isWheelFree ? Icons.check_circle_rounded : Icons.timer_outlined,
                    size: 14,
                    color: _isWheelFree ? const Color(0xFF059669) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isWheelFree ? 'SPIN FREE!' : _formatDuration(_wheelCooldown),
                    style: GoogleFonts.sniglet(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _isWheelFree ? const Color(0xFF059669) : const Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD 5: DAILY QUESTS (Chocolate Box)
  // -------------------------------------------------------------------------
  Widget _buildDailyQuestsCard() {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E22CE).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('📜', style: TextStyle(fontSize: 30)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Daily Quests',
            style: GoogleFonts.sniglet(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: _showDailyQuestsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA855F7), width: 1.2),
              ),
              child: Text(
                '3 Quests Ready',
                style: GoogleFonts.sniglet(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6B21A8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD 6: TREASURE CHEST
  // -------------------------------------------------------------------------
  Widget _buildTreasureChestCard() {
    return _buildFrostedBaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFEAB308)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 30)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Treasure Vault',
            style: GoogleFonts.sniglet(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A148C),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFB45309)),
                const SizedBox(width: 4),
                Text(
                  '19h 45m',
                  style: GoogleFonts.sniglet(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Base Frosted Cream Card Container
  Widget _buildFrostedBaseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFFB6C1).withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================================================================
  // BOTTOM FOLDED RIBBON NAVIGATION BAR (Exact Candy Crush Match)
  // =========================================================================

  Widget _buildBottomRibbonBar() {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF4081), Color(0xFFD81B60)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tab 1: Map / Levels
              _buildRibbonItem(
                emoji: '🗺️',
                label: 'Map',
                isSelected: false,
                onTap: () => Navigator.of(context).pop(),
              ),

              // Tab 2: Events (Elevated Active Plaque)
              const SizedBox(width: 72), // Spacer for center elevated plaque

              // Tab 3: Friends / Leaderboard
              _buildRibbonItem(
                emoji: '👥',
                label: 'Friends',
                isSelected: false,
                onTap: () => _showSimpleSnackbar('Friends leaderboard coming soon!'),
              ),

              // Tab 4: Timed Event
              _buildRibbonItem(
                emoji: '⭐',
                label: '5d 22h',
                isSelected: false,
                onTap: _showFestivalDetailsDialog,
              ),

              // Tab 5: Shop
              _buildRibbonItem(
                emoji: '🛒',
                label: 'Shop',
                isSelected: false,
                onTap: () async {
                  await showDailyBoosterWheel(context);
                  if (mounted) _refreshTimers();
                },
              ),
            ],
          ),

          // Central Folded Ribbon Active Tab: "Events"
          Positioned(
            top: -16,
            left: MediaQuery.of(context).size.width * 0.22,
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF4081), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Events',
                    style: GoogleFonts.sniglet(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFC2185B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonItem({
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playClickSound();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sniglet(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // INTERACTIVE EVENT POPUPS & CELEBRATION MODALS
  // =========================================================================

  /// Florist's Box Opening Dialog
  void _showFloristBoxDialog() {
    AudioService.instance.playClickSound();
    final repo = ref.read(progressRepositoryProvider);
    final isClaimed = repo.isFloristBoxClaimedToday();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFFF4081), width: 3),
        ),
        title: Center(
          child: Text(
            "Baker's Gift Box",
            style: GoogleFonts.cherryCreamSoda(
              fontSize: 22,
              color: const Color(0xFFC2185B),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 10),
            Text(
              isClaimed
                  ? "You've already claimed today's box!\nNext box available tomorrow."
                  : "Congratulations! You've unlocked today's mystery baker treat!",
              textAlign: TextAlign.center,
              style: GoogleFonts.sniglet(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRewardChip('🔨', '1 Hammer'),
                  _buildRewardChip('💎', '25 Gems'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed ? Colors.grey : const Color(0xFFFF4081),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              ),
              onPressed: isClaimed
                  ? () => Navigator.pop(ctx)
                  : () async {
                      Navigator.pop(ctx);
                      await repo.claimFloristBox();
                      if (!mounted) return;
                      _confettiController.play();
                      AudioService.instance.playClearSound();
                      setState(() {});
                      _showSimpleSnackbar('Claimed 1 Hammer & 25 Gems!');
                    },
              child: Text(
                isClaimed ? 'CLOSE' : 'CLAIM REWARD',
                style: GoogleFonts.sniglet(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Season Pass Tier Ladder Dialog
  void _showGardenPassDialog() {
    AudioService.instance.playClickSound();
    final repo = ref.read(progressRepositoryProvider);
    final claimed = repo.getClaimedGardenPassTiers();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFEC4899), width: 3),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎟️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Season Pass Tiers',
              style: GoogleFonts.cherryCreamSoda(
                fontSize: 20,
                color: const Color(0xFFC2185B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kDefaultGardenPassTiers.map((tier) {
              final isUnlocked = tier.tierNumber <= 4;
              final isClaimed = claimed.contains(tier.tierNumber);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFFFEBF0) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked ? const Color(0xFFFF80AB) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFEC4899),
                      child: Text(
                        '${tier.tierNumber}',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tier.freeRewardEmoji} ${tier.freeRewardTitle}',
                        style: GoogleFonts.sniglet(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A148C),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isClaimed
                            ? Colors.grey
                            : (isUnlocked ? const Color(0xFF10B981) : Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: (!isUnlocked || isClaimed)
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await repo.claimGardenPassTier(
                                tier.tierNumber,
                                tier.freeRewardAmount,
                                'flowers',
                              );
                              if (!mounted) return;
                              _confettiController.play();
                              AudioService.instance.playClearSound();
                              setState(() {});
                            },
                      child: Text(
                        isClaimed ? 'Claimed' : (isUnlocked ? 'Claim' : 'Locked'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Episode Race Leaderboard Dialog
  void _showEpisodeRaceDialog() {
    AudioService.instance.playClickSound();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFFFA000), width: 3),
        ),
        title: Center(
          child: Text(
            'Episode Race Track',
            style: GoogleFonts.cherryCreamSoda(
              fontSize: 22,
              color: const Color(0xFFB45309),
            ),
          ),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kDefaultRaceParticipants.map((p) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.isPlayer ? const Color(0xFFFEF3C7) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p.isPlayer ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                    width: p.isPlayer ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${p.rank}',
                      style: GoogleFonts.sniglet(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: p.rank == 1 ? const Color(0xFFD97706) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: AssetImage(p.avatarPath),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        style: GoogleFonts.sniglet(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      'Level ${p.currentLevel}/5',
                      style: GoogleFonts.sniglet(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('RACE ON!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Daily Quests Dialog
  void _showDailyQuestsDialog() {
    AudioService.instance.playClickSound();
    final repo = ref.read(progressRepositoryProvider);
    final claimed = repo.getClaimedDailyQuests();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFA855F7), width: 3),
        ),
        title: Center(
          child: Text(
            'Daily Bloom Quests',
            style: GoogleFonts.cherryCreamSoda(
              fontSize: 22,
              color: const Color(0xFF7E22CE),
            ),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kDefaultDailyQuests.map((quest) {
              final isClaimed = claimed.contains(quest.id);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quest.title,
                          style: GoogleFonts.sniglet(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4A148C),
                          ),
                        ),
                        Text(
                          '${quest.rewardEmoji} +${quest.rewardAmount}',
                          style: GoogleFonts.sniglet(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.description,
                      style: GoogleFonts.sniglet(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: quest.progressRatio,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFA855F7)),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isClaimed
                                ? Colors.grey
                                : (quest.isCompleted ? const Color(0xFF10B981) : Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          ),
                          onPressed: (!quest.isCompleted || isClaimed)
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await repo.claimDailyQuest(
                                    quest.id,
                                    quest.rewardAmount,
                                    quest.rewardType,
                                  );
                                  if (!mounted) return;
                                  _confettiController.play();
                                  AudioService.instance.playClearSound();
                                  setState(() {});
                                },
                          child: Text(
                            isClaimed ? 'Claimed' : (quest.isCompleted ? 'Claim' : '${quest.currentProgress}/${quest.maxGoal}'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Festival Details Dialog
  void _showFestivalDetailsDialog() {
    AudioService.instance.playClickSound();
    final repo = ref.read(progressRepositoryProvider);
    final petals = repo.getFestivalPetals();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFFF4081), width: 3),
        ),
        title: Center(
          child: Text(
            'Bloom Festival Event',
            style: GoogleFonts.cherryCreamSoda(
              fontSize: 22,
              color: const Color(0xFFC2185B),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑🌸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'Collect 60 Flower Petals in regular game levels before the festival timer runs out!',
              textAlign: TextAlign.center,
              style: GoogleFonts.sniglet(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Grand Festival Prize:',
                    style: GoogleFonts.sniglet(fontWeight: FontWeight.bold, color: const Color(0xFF880E4F)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🌸 500 Flowers + 💣 Bloom Bomb + 🔨 Bloom Hammer',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sniglet(fontSize: 12, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Progress: $petals/60 Petals',
              style: GoogleFonts.sniglet(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('COLLECT PETALS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.sniglet(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF880E4F),
          ),
        ),
      ],
    );
  }

  void _showSimpleSnackbar(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.sniglet(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC2185B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ============================================================================
// CUSTOM CANDY CYAN VERTICAL STRIPES BACKGROUND PAINTER
// ============================================================================

class CandyCyanStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 38.0;
    final numStripes = (size.width / stripeWidth).ceil() + 1;

    final paint1 = Paint()..color = const Color(0xFF67CFE5);
    final paint2 = Paint()..color = const Color(0xFF55C3DC);

    for (int i = 0; i < numStripes; i++) {
      final rect = Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height);
      canvas.drawRect(rect, i % 2 == 0 ? paint1 : paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
