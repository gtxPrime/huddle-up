// lib/ui/widgets/card_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/game_state.dart';
import '../../core/penguin_types.dart';
import '../../core/clumps.dart';
import '../../services/audio_service.dart';
import 'kawaii_penguin.dart';
import 'penguin_info_dialog.dart';

class CardRow extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<int> onSelect;
  final VoidCallback? onInfo;

  const CardRow({
    super.key,
    required this.gameState,
    required this.onSelect,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final penguins = gameState.penguins;
    if (penguins.isEmpty) return const SizedBox.shrink();

    // 4 cards in 2 rows on the left side
    final row1 = penguins.take(2).toList();
    final row2 = penguins.skip(2).take(2).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final pg in row1)
              _buildCard(context, pg),
          ],
        ),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final pg in row2)
                _buildCard(context, pg),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, Penguin pg) {
    final isSelected = pg.id == gameState.selectedId;
    final group = gameState.penguins
        .where((p) => !p.inIgloo && p.clumpId == pg.clumpId)
        .toList();
    final isDead = isDeadClump(group);

    return _CircularPenguinToken(
      penguin: pg,
      isSelected: isSelected,
      isDead: isDead,
      onTap: () {
        AudioService.playTap();
        onSelect(pg.id);
      },
      onInfo: () {
        AudioService.playTap();
        showPenguinInfoDialog(context, pg.color);
      },
    );
  }
}

class _CircularPenguinToken extends StatelessWidget {
  final Penguin penguin;
  final bool isSelected;
  final bool isDead;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  const _CircularPenguinToken({
    required this.penguin,
    required this.isSelected,
    required this.isDead,
    required this.onTap,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final def = kPenguinDefs[penguin.color]!;
    final inIgloo = penguin.inIgloo;

    Widget token = GestureDetector(
      onTap: inIgloo ? null : onTap,
      child: Container(
        width: 62,
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // ── Circular Pedestal Base ──
            Positioned(
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.9,
                    colors: inIgloo
                        ? [
                            const Color(0xFF2E7D32),
                            const Color(0xFF0D1B2A),
                          ]
                        : isSelected
                            ? [
                                def.displayColor.withValues(alpha: 0.85),
                                const Color(0xFF071424),
                              ]
                            : [
                                const Color(0xFF1B2A40),
                                const Color(0xFF0B1626),
                              ],
                  ),
                  // NO border when selected - just radiant glowing aura!
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: def.displayColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),

            // ── 3D Penguin popping slightly out of the circle ──
            Positioned(
              bottom: 4,
              child: KawaiiPenguin(
                color: penguin.color,
                size: 46,
                isSelected: isSelected,
                isDead: isDead,
                showBadge: true,
                movesLeft: penguin.movesLeft,
              ),
            ),

            // ── Top-Right Info (i) Button ──
            Positioned(
              top: -2,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onInfo,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D1B2A).withValues(alpha: 0.95),
                    border: Border.all(
                      color: Colors.white38,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // ── Safe inside Igloo Badge ──
            if (inIgloo)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 10, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'SAFE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Dead Clump Warning ──
            if (isDead && !inIgloo)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0288D1),
                  ),
                  child: const Icon(
                    Icons.ac_unit_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Subtle breathing animation when selected
    if (isSelected && !inIgloo) {
      token = token
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.06, duration: 550.ms, curve: Curves.easeInOut);
    }

    return token;
  }
}
