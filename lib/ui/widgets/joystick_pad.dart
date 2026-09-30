// lib/ui/widgets/joystick_pad.dart
import 'package:flutter/material.dart';
import '../../core/penguin_types.dart';
import '../../core/game_state.dart';
import '../../core/clumps.dart';

class JoystickPad extends StatelessWidget {
  final GameState? gameState;
  final ValueChanged<Direction> onDirection;

  const JoystickPad({
    super.key,
    required this.gameState,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final gs = gameState;
    Set<Direction> allowed = {};
    Set<Direction> legal = {}; // actually passable right now

    if (gs != null && gs.selectedId >= 0) {
      final sel = gs.selectedPenguin;
      if (sel != null) {
        final group = gs.penguins
            .where((p) => p.clumpId == sel.clumpId)
            .toList();
        allowed = allowedDirections(group);
        // Filter currently blocked directions
        for (final d in allowed) {
          final (dx, dy) = d.delta;
          final np = sel.pos.translate(dx, dy);
          if (!gs.isSolid(np)) legal.add(d);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
              const SizedBox(width: 40),
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
