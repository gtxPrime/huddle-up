// lib/ui/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/rules.dart';
import '../../gen/level_provider.dart';
import '../../gen/generator.dart';
import '../../core/level_data.dart';
import '../../services/game_storage.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../game_notifier.dart';
import '../widgets/arena_view.dart';
import '../widgets/card_row.dart';
import '../widgets/joystick_pad.dart';
import '../widgets/top_bar.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/penguin_info_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int levelNumber;
  const GameScreen({super.key, required this.levelNumber});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  LevelData? _levelData;
  GeneratedLevel? _gen;
  Timer? _countdownTimer;
  bool _adTriggeredThisWin = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAndStart() async {
    _countdownTimer?.cancel();
    _adTriggeredThisWin = false;
    _isPaused = false;
    final gen = await generateLevelAsync(widget.levelNumber);
    final data = generatedToLevelData(gen, widget.levelNumber);
    if (!mounted) return;
    setState(() {
      _gen = gen;
      _levelData = data;
    });
    ref.read(gameProvider.notifier).loadLevel(data);

    // Check if any penguin in this level is new and needs introduction
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final pg in data.initialState.penguins) {
        if (!GameStorage.hasSeenPenguin(pg.color.name)) {
          await GameStorage.markPenguinSeen(pg.color.name);
          if (mounted) {
            await showPenguinIntroDialog(context, pg.color, () {});
          }
          break; // Show one introduction per level
        }
      }
    });

    // Start 1-second timer tick (pauses when _isPaused is true)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final vm = ref.read(gameProvider);
      if (!_isPaused && vm != null && vm.phase == GamePhase.playing) {
        ref.read(gameProvider.notifier).tickTimer();
      }
    });
  }

  void _onLevelWon(int moves, int par) {
    if (_adTriggeredThisWin) return;
    _adTriggeredThisWin = true;

    // Save progress & stars
    GameStorage.saveLevelCompletion(
      level: widget.levelNumber,
      moves: moves,
      par: par,
    );

    // Smart AdMob Interstitial (e.g. every 2 levels)
    AdService.onLevelCompleted(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(gameProvider);

    if (_levelData == null || vm == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PenguinLoadingAnim(),
              const SizedBox(height: 20),
              Text(
                'Carving Level ${widget.levelNumber}...',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gs = vm.state;

    // Check for win event
    if (vm.phase == GamePhase.won && !_adTriggeredThisWin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onLevelWon(gs.movesMade, _gen?.par ?? 0);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                TopBar(
                  level: widget.levelNumber,
                  moves: gs.movesMade,
                  par: _gen?.par ?? 0,
                  rewinds: gs.rewindsLeft,
                  lives: vm.lives,
                  maxLives: vm.maxLives,
                  timeLeft: vm.timeLeft,
                  onPause: () {
                    AudioService.playTap();
                    setState(() => _isPaused = true);
                  },
                  onRewind: () {
                    if (GameStorage.isHapticsEnabled()) {
                      HapticFeedback.lightImpact();
                    }
                    AudioService.playTap();
                    ref.read(gameProvider.notifier).rewind();
                  },
                  onMenu: () {
                    AudioService.playTap();
                    Navigator.of(context).pop();
                  },
                  onAddLife: () {
                    AudioService.playTap();
                    AdService.showRewardedLifeAd(
                      context,
                      onRewardEarned: () {
                        ref.read(gameProvider.notifier).restoreLives();
                      },
                    );
                  },
                  onAddTime: () {
                    AudioService.playTap();
                    AdService.showRewardedTimeAd(
                      context,
                      onRewardEarned: () {
                        ref.read(gameProvider.notifier).addBonusTime(30);
                      },
                    );
                  },
                ),

                // ── Arena ──────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ArenaView(
                      gameState: gs,
                      onPenguinTap: (id) {
                        if (GameStorage.isHapticsEnabled()) {
                          HapticFeedback.selectionClick();
                        }
                        AudioService.playTap();
                        ref.read(gameProvider.notifier).selectPenguin(id);
                      },
                    ),
                  ),
                ),

                // ── Fail reason banner ─────────────────────────────────────
                if (vm.lastFail != null)
                  _FailBanner(reason: vm.lastFail!)
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.3, end: 0),

                // ── Bottom Control Deck (Left: 4 Cards in 2 rows | Right: D-Pad Controls) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side: 4 cards in 2 rows
                      Expanded(
                        child: CardRow(
                          gameState: gs,
                          onSelect: (id) {
                            if (GameStorage.isHapticsEnabled()) {
                              HapticFeedback.selectionClick();
                            }
                            AudioService.playTap();
                            ref.read(gameProvider.notifier).selectPenguin(id);
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Right side: D-Pad Controls
                      JoystickPad(
                        gameState: gs,
                        onDirection: (dir) {
                          if (GameStorage.isHapticsEnabled()) {
                            HapticFeedback.mediumImpact();
                          }
                          AudioService.playMove();
                          ref.read(gameProvider.notifier).move(dir);
                        },
                      ),
                    ],
                  ),
                ),

                // ── AdMob Banner ───────────────────────────────────────────
                const AdBannerWidget(),
              ],
            ),

            // ── Floating Dopamine Combo Toast ──────────────────────────
            if (vm.dopamineComboToast != null)
              Positioned(
                top: 75,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8F00), Color(0xFFFFD54F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      vm.dopamineComboToast!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B2631),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 350.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeOut(delay: 800.ms, duration: 400.ms),
                ),
              ),

            // ── Celebration Overlay (Confetti, Sequential Stars, Fanfare) ──
            if (vm.phase == GamePhase.won)
              CelebrationOverlay(
                levelNumber: widget.levelNumber,
                moves: gs.movesMade,
                par: _gen?.par ?? 0,
                onNext: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          GameScreen(levelNumber: widget.levelNumber + 1),
                    ),
                  );
                },
                onReplay: () {
                  _adTriggeredThisWin = false;
                  ref.read(gameProvider.notifier).restart(_levelData!);
                },
                onMenu: () => Navigator.of(context).pop(),
              ),

            // ── Pause Dialog Modal ─────────────────────────────────────
            if (_isPaused)
              _PauseDialog(
                levelNumber: widget.levelNumber,
                onResume: () {
                  AudioService.playTap();
                  setState(() => _isPaused = false);
                },
                onRestart: () {
                  AudioService.playTap();
                  setState(() => _isPaused = false);
                  ref.read(gameProvider.notifier).restart(_levelData!);
                },
                onExit: () {
                  AudioService.playTap();
                  Navigator.of(context).pop();
                },
              ),

            // ── Emergency Rescue Modal (5s Loss Aversion Countdown) ──────
            if (vm.phase == GamePhase.lost)
              _EmergencyRescueOverlay(
                livesLeft: vm.lives,
                timeLeft: vm.timeLeft,
                lastFail: vm.lastFail,
                onWatchLifeAd: () {
                  AdService.showRewardedRescueAd(
                    context,
                    onRewardEarned: () {
                      AudioService.playRescue();
                      if (GameStorage.isHapticsEnabled()) {
                        HapticFeedback.heavyImpact();
                      }
                      ref.read(gameProvider.notifier).restoreLives();
                    },
                  );
                },
                onWatchTimeAd: () {
                  AdService.showRewardedTimeAd(
                    context,
                    onRewardEarned: () {
                      AudioService.playRescue();
                      if (GameStorage.isHapticsEnabled()) {
                        HapticFeedback.heavyImpact();
                      }
                      ref.read(gameProvider.notifier).addBonusTime(30);
                    },
                  );
                },
                onRewind: vm.history.isNotEmpty
                    ? () {
                        AudioService.playTap();
                        ref.read(gameProvider.notifier).rewind();
                      }
                    : null,
                onRestart: () {
                  GameStorage.resetWinStreak();
                  ref.read(gameProvider.notifier).restart(_levelData!);
                },
                onMenu: () {
                  GameStorage.resetWinStreak();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Fail Banner ────────────────────────────────────

class _FailBanner extends StatelessWidget {
  final FailReason reason;
  const _FailBanner({required this.reason});

  (IconData, String) get _info => switch (reason) {
        FailReason.waterDeath => (
            Icons.water_rounded,
            'Penguin fell in freezing water! Lost 1 Life.'
          ),
        FailReason.holeDeath => (
            Icons.warning_rounded,
            'Penguin fell into a deep crevasse! Lost 1 Life.'
          ),
        FailReason.deadClump => (
            Icons.ac_unit_rounded,
            'This clump cannot move in that direction together.'
          ),
        FailReason.wallBlocked => (
            Icons.security_rounded,
            'Way is blocked by ice wall.'
          ),
        FailReason.noLegalMove => (
            Icons.block_rounded,
            'No legal move available in that direction.'
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _info;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFB71C1C).withValues(alpha: 0.9),
        border: Border.all(color: Colors.redAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Emergency Rescue Overlay ─────────────────────────

class _EmergencyRescueOverlay extends StatefulWidget {
  final int livesLeft;
  final int timeLeft;
  final FailReason? lastFail;
  final VoidCallback onWatchLifeAd;
  final VoidCallback onWatchTimeAd;
  final VoidCallback? onRewind;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const _EmergencyRescueOverlay({
    required this.livesLeft,
    required this.timeLeft,
    this.lastFail,
    required this.onWatchLifeAd,
    required this.onWatchTimeAd,
    this.onRewind,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  State<_EmergencyRescueOverlay> createState() =>
      _EmergencyRescueOverlayState();
}

class _EmergencyRescueOverlayState extends State<_EmergencyRescueOverlay> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AudioService.playHeartbeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
        AudioService.playHeartbeat();
      } else {
        t.cancel();
        setState(() => _countdown = 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfTime = widget.timeLeft <= 0;
    final isOutOfMoves = widget.lastFail == FailReason.noLegalMove && !isOutOfTime;
    final streak = GameStorage.getWinStreak();

    String title;
    String subtitle;
    IconData headerIcon;

    if (isOutOfTime) {
      title = 'TIME EXPIRED!';
      subtitle = 'Watch a quick video ad to get +30s and complete the puzzle!';
      headerIcon = Icons.timer_rounded;
    } else if (isOutOfMoves) {
      title = 'OUT OF MOVES!';
      subtitle = 'Shortest route budget exceeded! Tap Undo to rewind or watch an ad to revive!';
      headerIcon = Icons.alt_route_rounded;
    } else {
      title = 'HUDDLE LOST!';
      subtitle = 'Penguin hit a hazard! Watch a quick video ad to revive all 3 lives and keep your puzzle progress!';
      headerIcon = Icons.heart_broken_rounded;
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E111A), Color(0xFF0F1B2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: (_countdown > 0 ? const Color(0xFFFF5252) : Colors.white24)
                  .withValues(alpha: 0.85),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Urgent Icon / Countdown Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_countdown > 0)
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: _countdown / 5.0,
                        strokeWidth: 4,
                        color: const Color(0xFFFF5252),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _countdown > 0
                          ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: _countdown > 0
                          ? Text(
                              '$_countdown',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFF5252),
                              ),
                            )
                          : Icon(
                              headerIcon,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                _countdown > 0 ? 'CRACKED ICE! RESCUE HUDDLE!' : title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              if (streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Watch ad to protect your $streak Win Streak!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Glowing Urgent Rescue Rewarded Ad Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutOfTime
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF1B2631),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white70, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.healing_rounded, size: 18),
                  label: Text(
                    isOutOfTime
                        ? 'RESCUE (+30s TIME) [AD]'
                        : (isOutOfMoves
                            ? 'RESCUE (+3 LIVES & RETRY) [AD]'
                            : 'RESCUE FLOCK (+3 LIVES) [AD]'),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: isOutOfTime
                      ? widget.onWatchTimeAd
                      : widget.onWatchLifeAd,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.03, duration: 600.ms),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onRewind != null) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.replay_rounded,
                          size: 14, color: Color(0xFF4FC3F7)),
                      label: Text('Undo Move',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF4FC3F7),
                              fontWeight: FontWeight.bold)),
                      onPressed: widget.onRewind,
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded,
                        size: 14, color: Colors.white60),
                    label: Text('Restart Level',
                        style: GoogleFonts.outfit(color: Colors.white60)),
                    onPressed: widget.onRestart,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.home_rounded,
                        size: 14, color: Colors.white60),
                    label: Text('Levels',
                        style: GoogleFonts.outfit(color: Colors.white60)),
                    onPressed: widget.onMenu,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Pause Dialog ────────────────────────────────────

class _PauseDialog extends StatefulWidget {
  final int levelNumber;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _PauseDialog({
    required this.levelNumber,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  @override
  State<_PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<_PauseDialog> {
  late bool _sound;
  late bool _music;
  late bool _haptics;

  @override
  void initState() {
    super.initState();
    _sound = GameStorage.isSoundEnabled();
    _music = GameStorage.isMusicEnabled();
    _haptics = GameStorage.isHapticsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2A40), Color(0xFF0F1A28)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon & Title
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF00E5FF),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.pause_rounded,
                    color: Color(0xFF00E5FF),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'GAME PAUSED',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Level ${widget.levelNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 20),

              // Setting toggles (Sound, Music, Haptics)
              _buildToggle(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                value: _sound,
                onChanged: (v) async {
                  await GameStorage.setSoundEnabled(v);
                  setState(() => _sound = v);
                  if (v) AudioService.playTap();
                },
              ),
              const SizedBox(height: 10),
              _buildToggle(
                icon: Icons.music_note_rounded,
                title: 'Background Music',
                value: _music,
                onChanged: (v) async {
                  await GameStorage.setMusicEnabled(v);
                  await AudioService.onMusicSettingChanged(v);
                  setState(() => _music = v);
                },
              ),
              const SizedBox(height: 10),
              _buildToggle(
                icon: Icons.vibration_rounded,
                title: 'Vibration Haptics',
                value: _haptics,
                onChanged: (v) async {
                  await GameStorage.setHapticsEnabled(v);
                  setState(() => _haptics = v);
                  if (v) HapticFeedback.lightImpact();
                },
              ),
              const SizedBox(height: 24),

              // RESUME button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0A192F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    'RESUME',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  onPressed: widget.onResume,
                ),
              ),
              const SizedBox(height: 10),

              // RESTART & EXIT buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(
                        'Restart',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: widget.onRestart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                      label: Text(
                        'Exit',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: widget.onExit,
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

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────── Penguin Loading Animation ───────────────────────

class _PenguinLoadingAnim extends StatelessWidget {
  const _PenguinLoadingAnim();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A3D),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.ac_unit_rounded,
          color: Colors.lightBlueAccent,
          size: 36,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .rotate(duration: 2500.ms)
        .then()
        .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms);
  }
}
