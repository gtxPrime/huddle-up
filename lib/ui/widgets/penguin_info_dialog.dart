// lib/ui/widgets/penguin_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/penguin_types.dart';
import 'kawaii_penguin.dart';

class PenguinInfo {
  final String title;
  final String role;
  final String description;
  final List<IconData> directionIcons;
  final String limitText;

  const PenguinInfo({
    required this.title,
    required this.role,
    required this.description,
    required this.directionIcons,
    required this.limitText,
  });
}

PenguinInfo getPenguinInfo(PenguinColor color) {
  switch (color) {
    case PenguinColor.blue:
      return const PenguinInfo(
        title: 'Blue Penguin',
        role: 'Standard Navigator',
        description: 'Moves freely in all 4 cardinal directions one step at a time.',
        directionIcons: [
          Icons.arrow_upward_rounded,
          Icons.arrow_downward_rounded,
          Icons.arrow_back_rounded,
          Icons.arrow_forward_rounded,
        ],
        limitText: 'Full 4-Way freedom. Great for pathfinding & guiding teammates.',
      );
    case PenguinColor.green:
      return const PenguinInfo(
        title: 'Green Penguin',
        role: 'Vertical Specialist',
        description: 'Can ONLY move UP and DOWN! Strictly locked to vertical lanes.',
        directionIcons: [
          Icons.arrow_upward_rounded,
          Icons.arrow_downward_rounded,
        ],
        limitText: 'CANNOT move Left or Right on its own! Must huddle with teammates to move sideways.',
      );
    case PenguinColor.orange:
      return const PenguinInfo(
        title: 'Orange Penguin',
        role: 'Horizontal Specialist',
        description: 'Can ONLY move LEFT and RIGHT! Strictly locked to horizontal rows.',
        directionIcons: [
          Icons.arrow_back_rounded,
          Icons.arrow_forward_rounded,
        ],
        limitText: 'CANNOT move Up or Down on its own! Must huddle with teammates to travel vertically.',
      );
    case PenguinColor.red:
      return const PenguinInfo(
        title: 'Red Penguin',
        role: 'Ice Dasher',
        description: 'Slides continuously until crashing into a wall or obstacle.',
        directionIcons: [
          Icons.fast_forward_rounded,
        ],
        limitText: 'Cannot stop mid-path. Uses obstacles to brake and position itself.',
      );
    case PenguinColor.purple:
      return const PenguinInfo(
        title: 'Purple Penguin',
        role: 'Swap Master',
        description: 'Can swap places with an adjacent penguin or ice block!',
        directionIcons: [
          Icons.swap_horiz_rounded,
        ],
        limitText: 'Excellent for squeezing past tight single-lane bottlenecks.',
      );
    case PenguinColor.yellow:
    default:
      return const PenguinInfo(
        title: 'Yellow Penguin',
        role: 'Hop Leaper',
        description: 'Hops 2 tiles in a straight line, leaping over hazards!',
        directionIcons: [
          Icons.arrow_outward_rounded,
        ],
        limitText: 'Laps over 1 tile obstacles if the landing tile is clear.',
      );
  }
}

Future<void> showPenguinInfoDialog(BuildContext context, PenguinColor color) {
  final info = getPenguinInfo(color);
  final def = kPenguinDefs[color]!;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: def.displayColor.withValues(alpha: 0.8),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: def.displayColor.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cute Penguin Avatar Preview
              KawaiiPenguin(
                color: color,
                size: 76,
                isSelected: false,
                showBadge: false,
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                info.title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),

              // Role chip
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: def.displayColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: def.displayColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  info.role,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: def.displayColor,
                  ),
                ),
              ),

              // Description
              Text(
                info.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Direction icons pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final icon in info.directionIcons)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(icon, color: def.displayColor, size: 22),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Limits Text Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFFD54F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.limitText,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: def.displayColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'GOT IT!',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showPenguinIntroDialog(
    BuildContext context, PenguinColor color, VoidCallback onDismiss) {
  final info = getPenguinInfo(color);
  final def = kPenguinDefs[color]!;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00E5FF),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✨ NEW PENGUIN DISCOVERED!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cute Avatar
              KawaiiPenguin(
                color: color,
                size: 88,
                isSelected: false,
                showBadge: false,
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                info.title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Description & limit
              Text(
                info.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),

              // Rule highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: def.displayColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: def.displayColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '⚠️ ${info.limitText}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Let's Play Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onDismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "LET'S PLAY!",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
