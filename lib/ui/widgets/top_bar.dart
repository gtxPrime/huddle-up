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

  @override
  Widget build(BuildContext context) {

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
          // Pause / Menu button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPause ?? onMenu,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                        color: Colors.white70, size: 14),
                    SizedBox(width: 3),
                    Text(
                      'Pause',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Level & Moves Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level $level',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 1,
                  height: 12,
                  color: Colors.white24,
                ),
                Text(
                  'Moves: $moves',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (par > 0)
                  Text(
                    ' (Par $par)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Undo Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: rewinds > 0 ? onRewind : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: rewinds > 0
                      ? const Color(0xFF0288D1)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: rewinds > 0
                        ? const Color(0xFF4FC3F7)
                        : Colors.white12,
                    width: 1,
                  ),
                  boxShadow: rewinds > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0288D1).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.replay_rounded,
                      color: rewinds > 0 ? Colors.white : Colors.white30,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Undo $rewinds',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: rewinds > 0 ? Colors.white : Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
