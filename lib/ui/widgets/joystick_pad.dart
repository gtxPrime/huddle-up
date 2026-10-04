// lib/ui/widgets/joystick_pad.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/penguin_types.dart';
import '../../core/game_state.dart';
import '../../core/clumps.dart';

class JoystickPad extends StatelessWidget {
  final GameState? gameState;
  final ValueChanged<Direction> onDirection;
  final VoidCallback? onUndo;
  final bool canUndo;

  const JoystickPad({
    super.key,
    required this.gameState,
    required this.onDirection,
    this.onUndo,
    this.canUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    final gs = gameState;
    Set<Direction> allowed = {};
    Set<Direction> legal = {}; // actually passable right now

    if (gs != null && gs.selectedId >= 0) {
      final sel = gs.selectedPenguin;
      if (sel != null && !sel.inIgloo) {
        allowed = allowedDirections([sel]);
        // Filter currently blocked directions (solid tiles or other penguins)
        for (final d in allowed) {
          final (dx, dy) = d.delta;
          final np = sel.pos.translate(dx, dy);
          if (!gs.isSolid(np) && gs.penguinAt(np) == null) {
            legal.add(d);
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DpadButton(
            dir: Direction.up,
            allowed: allowed,
            legal: legal,
            onTap: onDirection,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DpadButton(
                dir: Direction.left,
                allowed: allowed,
                legal: legal,
                onTap: onDirection,
              ),
              _DpadUndoButton(
                canUndo: canUndo,
                onTap: onUndo,
              ),
              _DpadButton(
                dir: Direction.right,
                allowed: allowed,
                legal: legal,
                onTap: onDirection,
              ),
            ],
          ),
          _DpadButton(
            dir: Direction.down,
            allowed: allowed,
            legal: legal,
            onTap: onDirection,
          ),
        ],
      ),
    );
  }
}

class _DpadUndoButton extends StatelessWidget {
  final bool canUndo;
  final VoidCallback? onTap;

  const _DpadUndoButton({
    required this.canUndo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canUndo ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: canUndo
                ? [
                    const Color(0xFF0288D1),
                    const Color(0xFF01579B),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: canUndo
                ? const Color(0xFF4FC3F7)
                : Colors.white.withValues(alpha: 0.1),
            width: canUndo ? 2 : 1,
          ),
          boxShadow: canUndo
              ? [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.replay_rounded,
              size: 20,
              color: canUndo ? Colors.white : Colors.white24,
            ),
            Text(
              'UNDO',
              style: GoogleFonts.outfit(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: canUndo ? const Color(0xFF80D8FF) : Colors.white24,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DpadButton extends StatelessWidget {
  final Direction dir;
  final Set<Direction> allowed;
  final Set<Direction> legal;
  final ValueChanged<Direction> onTap;

  const _DpadButton({
    required this.dir,
    required this.allowed,
    required this.legal,
    required this.onTap,
  });

  IconData get _icon => switch (dir) {
        Direction.up => Icons.keyboard_arrow_up_rounded,
        Direction.down => Icons.keyboard_arrow_down_rounded,
        Direction.left => Icons.keyboard_arrow_left_rounded,
        Direction.right => Icons.keyboard_arrow_right_rounded,
        _ => Icons.arrow_outward_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isAllowed = allowed.contains(dir);
    final isLegal = legal.contains(dir);
    final isEnabled = isAllowed && isLegal;

    return GestureDetector(
      onTap: isEnabled ? () => onTap(dir) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isEnabled
                ? [
                    const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    const Color(0xFF0277BD).withValues(alpha: 0.9),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF80D8FF)
                : Colors.white.withValues(alpha: 0.12),
            width: isEnabled ? 2 : 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            _icon,
            size: 28,
            color: isEnabled ? Colors.white : Colors.white24,
          ),
        ),
      ),
    );
  }
}
