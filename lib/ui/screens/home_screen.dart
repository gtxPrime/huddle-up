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

                      // Fish Coins Badge with + button
                      _CurrencyPill(
                        icon: Icons.set_meal_rounded,
                        iconColor: const Color(0xFF4DD0E1),
                        text: _formatNumber(GameStorage.getFishCoins()),
                        showPlus: true,
                        onPlusTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PurchaseScreen()),
                          );
                          _refresh();
                        },
                      ),

                      const Spacer(),

                      // Action Buttons (Daily Calendar, Wardrobe, VIP, Settings)
                      _HeaderIconButton(
                        icon: Icons.calendar_today_rounded,
                        color: Colors.white70,
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
                        icon: Icons.shopping_bag_rounded,
                        color: Colors.white70,
                        showDot: true,
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
                        icon: Icons.verified_user_rounded,
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

                // Animated Mascot Hero Illustration (Two Penguins on Snow Shelf with Igloo)
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
                          color: Colors.black.withValues(alpha: 0.55),
                          offset: const Offset(0, 3),
                          blurRadius: 10,
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
                  baseColor: const Color(0xFF0277BD),
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

                // All Levels & Map Button
                _HomeButton(
                  icon: Icons.layers_rounded,
                  label: 'ALL LEVELS & MAP',
                  accent: const Color(0xFF37474F),
                  baseColor: const Color(0xFF21272B),
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

                // Mystery Chest Rewarded Ad Button with FREE [AD] pill badge
                _HomeButton(
                  icon: Icons.inventory_2_rounded,
                  label: 'MYSTERY CHEST',
                  badge: 'FREE [AD]',
                  accent: const Color(0xFFFFB300),
                  baseColor: const Color(0xFFE65100),
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
                )
                    .animate(delay: 750.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),
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

String _formatNumber(int n) {
  return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool showPlus;
  final VoidCallback? onPlusTap;

  const _CurrencyPill({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.showPlus = false,
    this.onPlusTap,
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
          if (showPlus) ...[
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onPlusTap,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF00ACC1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showDot;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.showDot = false,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              if (showDot)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFD54F),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIglooWidget extends StatelessWidget {
  const _MiniIglooWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 36,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Igloo Dome
          Container(
            width: 50,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFB2EBF2), Color(0xFF80DEEA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // Ice Seam Arch Lines
          Positioned(
            top: 4,
            child: Container(
              width: 38,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border.all(
                  color: const Color(0xFF0097A7).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
          ),

          // Warm Glowing Entrance Arch
          Positioned(
            bottom: 0,
            child: Container(
              width: 22,
              height: 18,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFF6F00),
                    Color(0xFFBF360C),
                  ],
                  center: Alignment(0, 0.4),
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF8F00),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PenguinHeroIllustration extends StatelessWidget {
  const _PenguinHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0E2338),
            Color(0xFF0A192B),
          ],
          center: Alignment(0, -0.2),
          radius: 0.95,
        ),
        border: Border.all(
          color: const Color(0xFF80D8FF).withValues(alpha: 0.5),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft Night Sky Star Points
            Positioned(
              top: 28,
              left: 48,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 56,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 54,
              left: 104,
              child: Container(
                width: 2.5,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Curved Snowy Shelf & Ice Shelf Base
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 72,
              child: Stack(
                children: [
                  // Blue Ice Base Strip
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 24,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Snowy Curved Bank
                  Positioned(
                    bottom: 10,
                    left: -12,
                    right: -12,
                    height: 62,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.elliptical(120, 50),
                        ),
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0F7FA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF80DEEA).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Left Penguin: Blue Penguin with Golden Star Medal (slightly moving)
            Positioned(
              left: 24,
              bottom: 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const KawaiiPenguin(
                    color: PenguinColor.blue,
                    size: 64,
                    hat: 'none',
                    showBadge: false,
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD54F),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -3.5, duration: 1800.ms, curve: Curves.easeInOut)
                  .rotate(begin: -0.015, end: 0.015, duration: 2200.ms, curve: Curves.easeInOut),
            ),

            // Center/Right Penguin: Orange Penguin with Pink Earmuffs (slightly moving)
            Positioned(
              left: 68,
              bottom: 16,
              child: const KawaiiPenguin(
                color: PenguinColor.orange,
                size: 64,
                hat: 'earmuffs',
                showBadge: false,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -1, end: -4.5, duration: 2100.ms, curve: Curves.easeInOut)
                  .rotate(begin: 0.015, end: -0.015, duration: 2500.ms, curve: Curves.easeInOut),
            ),

            // Miniature Igloo with Glowing Doorway on the right
            Positioned(
              right: 14,
              bottom: 16,
              child: const _MiniIglooWidget()
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.98, end: 1.02, duration: 1900.ms),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scaleXY(begin: 0.85, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color accent;
  final Color baseColor;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.accent,
    required this.baseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
          minWidth: 260,
        ),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: baseColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD84315),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
