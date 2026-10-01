// lib/ui/widgets/celebration_overlay.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/audio_service.dart';
import '../../services/game_storage.dart';
import '../../services/ad_service.dart';

class CelebrationOverlay extends StatefulWidget {
  final int levelNumber;
  final int moves;
  final int par;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onMenu;

  const CelebrationOverlay({
    super.key,
    required this.levelNumber,
    required this.moves,
    required this.par,
    required this.onNext,
    required this.onReplay,
    required this.onMenu,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  int _revealedStars = 0;
  bool _doubled = false;
  late final AnimationController _confettiController;
  late final List<_ConfettiParticle> _particles;

  int get _targetStars {
    if (widget.moves <= widget.par) return 3;
    if (widget.moves <= widget.par + 2) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _particles = List.generate(45, (i) => _ConfettiParticle(math.Random(i)));

    // Play victory fanfare sound & haptics
    AudioService.playWin();
    if (GameStorage.isHapticsEnabled()) {
      HapticFeedback.heavyImpact();
    }

    // Sequence star reveals with audio dings & haptics
    _animateStars();
  }

  Future<void> _animateStars() async {
    final target = _targetStars;
    await Future.delayed(const Duration(milliseconds: 350));
    for (int s = 1; s <= target; s++) {
      if (!mounted) return;
      setState(() => _revealedStars = s);
      AudioService.playStar();
      if (GameStorage.isHapticsEnabled()) {
        HapticFeedback.mediumImpact();
      }
      await Future.delayed(const Duration(milliseconds: 280));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stars = _targetStars;

    return Stack(
      children: [
        // Darkened frost backdrop
        Container(
          color: Colors.black.withValues(alpha: 0.85),
        ),

        // Animated Confetti shower
        AnimatedBuilder(
          animation: _confettiController,
          builder: (ctx, child) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
              ),
            );
          },
        ),

        // Celebration Card
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2D40), Color(0xFF0F1A26)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.75),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Trophy Badge with glowing aura
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
                      center: Alignment(-0.2, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(),

                const SizedBox(height: 14),

                // Praise Title
                Text(
                  stars == 3
                      ? 'FLAWLESS HUDDLE!'
                      : (stars == 2 ? 'BRILLIANT SOLVE!' : 'HUDDLE COMPLETE!'),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                Text(
                  'Level ${widget.levelNumber} Mastered',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.lightBlueAccent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                // Sequential Star Row with punchy animations
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < _revealedStars;

                    Widget star = Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEarned
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          boxShadow: isEarned
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isEarned
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isEarned
                              ? const Color(0xFFFFD54F)
                              : Colors.white24,
                          size: 34,
                        ),
                      ),
                    );

                    if (isEarned) {
                      star = star
                          .animate()
                          .scale(
                            begin: const Offset(0.2, 0.2),
                            duration: 350.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn();
                    }

                    return star;
                  }),
                ),

                const SizedBox(height: 20),

                // Score / Stats Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142435),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Moves Taken',
                        value: '${widget.moves}',
                        color: widget.moves <= widget.par
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white24,
                      ),
                      _StatColumn(
                        label: 'Par Target',
                        value: '${widget.par}',
                        color: Colors.lightBlueAccent,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white24,
                      ),
                      _StatColumn(
                        label: 'Rating',
                        value: '+$stars Stars',
                        color: const Color(0xFFFFD54F),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Win Streak Motivator Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${GameStorage.getWinStreak()} Win Streak! (+${(GameStorage.getWinStreak() * 10)}% XP)',
                        style: GoogleFonts.outfit(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Dopamine 2X Bonus Rewarded Ad Button ──────────────────
                if (!_doubled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: const Color(0xFF1B2631),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 10,
                        shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                              color: Color(0xFFFFF9C4), width: 1.8),
                        ),
                      ),
                      icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                      label: Text(
                        'CLAIM 2X BONUS (+${stars * 100} FISH) [AD]',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      onPressed: () {
                        AdService.showRewardedDoubleRewardAd(
                          context,
                          onRewardEarned: () async {
                            AudioService.playReward();
                            if (GameStorage.isHapticsEnabled()) {
                              HapticFeedback.heavyImpact();
                            }
                            await GameStorage.addFishCoins(stars * 100);
                            setState(() => _doubled = true);
                          },
                        );
                      },
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.03, duration: 750.ms)
                      .shimmer(duration: 1600.ms, color: Colors.white70),

                if (_doubled)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.greenAccent, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '2X REWARD CLAIMED! +${stars * 100} FISH',
                          style: GoogleFonts.outfit(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Next Level Large Dopamine CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                      shadowColor: const Color(0xFF2196F3).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      AudioService.playTap();
                      widget.onNext();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NEXT LEVEL',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.03, duration: 800.ms),

                const SizedBox(height: 12),

                // Secondary Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.replay_rounded,
                          size: 16, color: Colors.white70),
                      label: Text(
                        'Replay',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        AudioService.playTap();
                        widget.onReplay();
                      },
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.layers_rounded,
                          size: 16, color: Colors.white70),
                      label: Text(
                        'Levels',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        AudioService.playTap();
                        widget.onMenu();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Confetti Particle System ────────────────────────

class _ConfettiParticle {
  final double x;
  final double speed;
  final double size;
  final double swaySpeed;
  final Color color;

  _ConfettiParticle(math.Random rng)
      : x = rng.nextDouble(),
        speed = 0.4 + rng.nextDouble() * 0.6,
        size = 4.0 + rng.nextDouble() * 6.0,
        swaySpeed = 2.0 + rng.nextDouble() * 4.0,
        color = _colors[rng.nextInt(_colors.length)];

  static const List<Color> _colors = [
    Color(0xFFFFD54F), // Gold
    Color(0xFF29B6F6), // Ice Cyan
    Color(0xFFFF4081), // Neon Pink
    Color(0xFF69F0AE), // Emerald
    Color(0xFFE040FB), // Electric Purple
    Colors.white,
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final y = ((progress * p.speed + (i / particles.length)) % 1.0) *
          (size.height + 40);
      final sway = math.sin(progress * math.pi * p.swaySpeed + i) * 24.0;
      final x = (p.x * size.width + sway) % size.width;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      // Draw confetti diamond/rect
      canvas.save();
      canvas.translate(x, y - 20);
      canvas.rotate(progress * math.pi * 3 + i);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
