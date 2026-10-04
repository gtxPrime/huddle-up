// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/penguin_types.dart';
import '../../services/game_storage.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../widgets/kawaii_penguin.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'purchase_screen.dart';
import 'wardrobe_screen.dart';
import '../widgets/daily_reward_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentLevel = 1;
  int _totalStars = 0;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyRewardDialog.showIfEligible(context).then((_) => _refresh());
    });
  }

  void _refresh() {
    setState(() {
      _currentLevel = GameStorage.getMaxUnlockedLevel();
      _totalStars = GameStorage.getTotalStars();
      _isVip = GameStorage.isAdsRemoved();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // Ambient snow background
          const _SnowBackground(),

          SafeArea(
            child: Column(
              children: [
                // Top Utilities Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Total Stars Badge
                      _CurrencyPill(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        text: '$_totalStars',
                      ),
                      const SizedBox(width: 6),

                      // Fish Coins Badge
                      _CurrencyPill(
                        icon: Icons.set_meal_rounded,
                        iconColor: const Color(0xFF4DD0E1),
                        text: '${GameStorage.getFishCoins()}',
                      ),

                      const Spacer(),

                      // Action Buttons (Daily Calendar, Wardrobe, VIP, Settings)
                      _HeaderIconButton(
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF00E5FF),
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => const DailyRewardDialog(),
                          );
                          _refresh();
                        },
                      ),
                      const SizedBox(width: 5),
                      _HeaderIconButton(
                        icon: Icons.checkroom_rounded,
                        color: const Color(0xFFFFB300),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WardrobeScreen()),
                          );
                          _refresh();
                        },
                      ),
                      const SizedBox(width: 5),
                      _HeaderIconButton(
                        icon: Icons.military_tech_rounded,
                        color: _isVip
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFD54F),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PurchaseScreen()),
                          );
                          _refresh();
                        },
                      ),
                      const SizedBox(width: 5),
                      _HeaderIconButton(
                        icon: Icons.settings_rounded,
                        color: Colors.white70,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                          _refresh();
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Animated Mascot Hero Illustration (Two Penguins Huddling in an Aurora Globe)
                const _PenguinHeroIllustration(),

                const SizedBox(height: 18),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFE1F5FE),
                      Color(0xFF81D4FA),
                      Color(0xFF00E5FF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    'HUDDLE UP',
                    style: GoogleFonts.outfit(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.25, end: 0),

                const SizedBox(height: 6),

                Text(
                  '✦ THE COZY ARCTIC SLIDER ✦',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF80DEEA),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ).animate(delay: 350.ms).fadeIn(),

                const Spacer(flex: 2),

                // Play Button (Juicy 3D tactile game button)
                _HomeButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'PLAY LEVEL $_currentLevel',
                  accent: const Color(0xFF00B0FF),
                  baseColor: const Color(0xFF01579B),
                  onTap: () async {
                    AudioService.playTap();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(levelNumber: _currentLevel),
                      ),
                    );
                    _refresh();
                  },
                )
                    .animate(delay: 500.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 14),

                // All Levels Button
                _HomeButton(
                  icon: Icons.layers_rounded,
                  label: 'ALL LEVELS',
                  accent: const Color(0xFF37474F),
                  baseColor: const Color(0xFF212121),
                  onTap: () async {
                    AudioService.playTap();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LevelSelectScreen(),
                      ),
                    );
                    _refresh();
                  },
                )
                    .animate(delay: 650.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 14),

                // Daily Mystery Chest Rewarded Ad Button
                InkWell(
                  onTap: () {
                    AdService.showRewardedMysteryGiftAd(
                      context,
                      onRewardEarned: () async {
                        AudioService.playReward();
                        await GameStorage.addFishCoins(250);
                        _refresh();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF00B0FF),
                              content: Text(
                                'Mystery Chest Opened! +250 Fish Coins added!',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Mystery Chest (+250 🐟) [AD]',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 750.ms, onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.03, duration: 800.ms),

                const Spacer(),

                // Footer
                Text(
                  'Procedural Puzzles · 250+ Levels · Zero Dead Ends',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 800.ms).fadeIn(),

                const SizedBox(height: 12),

                // AdMob Banner
                const AdBannerWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── UI Helper Components ────────────────────────────

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _CurrencyPill({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF142435).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}

class _PenguinHeroIllustration extends StatelessWidget {
  const _PenguinHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF0288D1),
            Color(0xFF0D1B2A),
          ],
          center: Alignment(0, -0.2),
          radius: 0.95,
        ),
        border: Border.all(
          color: const Color(0xFF80D8FF).withValues(alpha: 0.8),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gentle aurora floor glow
          Positioned(
            bottom: 12,
            child: Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(50, 12)),
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Left Penguin (Navy Blue with Crown)
          Positioned(
            left: 18,
            bottom: 16,
            child: Transform.rotate(
              angle: 0.10,
              child: const KawaiiPenguin(
                color: PenguinColor.blue,
                size: 58,
                hat: 'crown',
                showBadge: false,
              ),
            ),
          ),

          // Right Penguin (Orange with Earmuffs)
          Positioned(
            right: 18,
            bottom: 16,
            child: Transform.rotate(
              angle: -0.10,
              child: const KawaiiPenguin(
                color: PenguinColor.orange,
                size: 58,
                hat: 'earmuffs',
                showBadge: false,
              ),
            ),
          ),

          // Floating Sparkle Star
          Positioned(
            top: 14,
            right: 28,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFD54F),
              size: 16,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.8, end: 1.2, duration: 900.ms),
          ),
        ],
      ),
    )
        .animate()
        .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color baseColor;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.baseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: baseColor,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withValues(alpha: 0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Aurora Sky Background ───────────────────────────

class _SnowBackground extends StatelessWidget {
  const _SnowBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Luminous Northern Lights (Aurora Borealis) curtains
          Positioned(
            top: 0,
            left: -40,
            right: -40,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.6),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.18),
                    const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    const Color(0xFF00E676).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.95, end: 1.08, duration: 3500.ms),
          ),

          // Gently falling snowflakes
          ...List.generate(12, (i) {
            final delay = (i * 350).ms;
            final left = (i * 31 % 100).toDouble();
            return Positioned(
              left: MediaQuery.of(context).size.width * left / 100,
              top: -20,
              child: Icon(
                Icons.ac_unit_rounded,
                size: 9.0 + (i % 3) * 5,
                color: Colors.white.withValues(alpha: 0.08 + (i % 4) * 0.03),
              )
                  .animate(delay: delay, onPlay: (c) => c.repeat())
                  .moveY(
                    begin: 0,
                    end: MediaQuery.of(context).size.height + 40,
                    duration: Duration(milliseconds: 6200 + i * 500),
                    curve: Curves.linear,
                  ),
            );
          }),
        ],
      ),
    );
  }
}
