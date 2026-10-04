// lib/ui/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopBar extends StatelessWidget {
  final int level;
  final int moves;
  final int par;
  final int rewinds;
  final int lives;
  final int maxLives;
  final int timeLeft;
  final VoidCallback onRewind;
  final VoidCallback onMenu;
  final VoidCallback? onPause;
  final VoidCallback? onAddLife;
  final VoidCallback? onAddTime;

  const TopBar({
    super.key,
    required this.level,
    required this.moves,
    required this.par,
    required this.rewinds,
    required this.lives,
    required this.maxLives,
    required this.timeLeft,
    required this.onRewind,
    required this.onMenu,
    this.onPause,
    this.onAddLife,
    this.onAddTime,
  });

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeLeft <= 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Pause / Menu button ──────────────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPause ?? onMenu,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_rounded,
                        color: Colors.white70, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Pause',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Level Badge ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Level $level',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF00E5FF),
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Spacer(),

          // ── Timer Badge (in place of moves and top undo) ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLowTime
                  ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLowTime
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF80D8FF).withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: isLowTime
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isLowTime ? const Color(0xFFFF5252) : const Color(0xFF80D8FF),
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(timeLeft),
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isLowTime ? const Color(0xFFFF5252) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
