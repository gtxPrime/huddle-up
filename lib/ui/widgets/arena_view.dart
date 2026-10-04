// lib/ui/widgets/arena_view.dart
//
// Renders the game grid using CustomPainter.
// Small grids (≤8×8): auto-fit the screen, no scroll needed.
// Large grids (>8×8): wrapped in InteractiveViewer — pinch to zoom,
//   drag to pan. A mini "zoom hint" badge appears the first time.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/game_state.dart';
import '../../core/tile_types.dart';
import '../../core/clumps.dart';
import 'kawaii_penguin.dart';

// Grids wider than this get InteractiveViewer treatment
const int _kPanThreshold = 8;
// Tile size (logical pixels) for the interactive layer
const double _kBaseTileSize = 56.0;
// Maximum zoom-in factor
const double _kMaxScale = 3.0;
// Minimum zoom-out factor (show the whole grid + some margin)
const double _kMinScale = 0.35;

class ArenaView extends StatefulWidget {
  final GameState gameState;
  final ValueChanged<int> onPenguinTap;

  const ArenaView({
    super.key,
    required this.gameState,
    required this.onPenguinTap,
  });

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  final _transformController = TransformationController();
  bool _hintShown = false;

  bool get _needsInteractiveViewer =>
      widget.gameState.width > _kPanThreshold ||
      widget.gameState.height > _kPanThreshold;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;

    if (_needsInteractiveViewer) {
      return _buildInteractive(gs);
    } else {
      return _buildAutoFit(gs);
    }
  }

  // ── Auto-fit (small grids ≤8×8) ────────────────────────────────────────────

  Widget _buildAutoFit(GameState gs) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final ts = math.min(
        constraints.maxWidth / gs.width,
        constraints.maxHeight / gs.height,
      );
      return Center(
        child: _buildGrid(gs, ts),
      );
    });
  }

  // ── Interactive (large grids >8×8) ─────────────────────────────────────────

  Widget _buildInteractive(GameState gs) {
    const ts = _kBaseTileSize;
    final gridW = ts * gs.width;
    final gridH = ts * gs.height;

    return LayoutBuilder(builder: (ctx, constraints) {
      // Initial scale so the grid fits the available space
      final fitScale = math.min(
        constraints.maxWidth / gridW,
        constraints.maxHeight / gridH,
      ).clamp(_kMinScale, 1.0);

      // Set initial transform only once
      if (!_hintShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _transformController.value =
              Matrix4.diagonal3Values(fitScale, fitScale, 1.0);
        });
      }

      return Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1A2D42), Color(0xFF0D1B2A)],
                radius: 1.4,
              ),
            ),
          ),
          // Interactive grid
          InteractiveViewer(
            transformationController: _transformController,
            minScale: _kMinScale,
            maxScale: _kMaxScale,
            boundaryMargin: const EdgeInsets.all(80),
            constrained: false,
            child: _buildGrid(gs, ts),
          ),
          // Zoom hint badge (appears once on large grids)
          if (!_hintShown)
            Positioned(
              top: 8,
              right: 8,
              child: _ZoomHintBadge(onDismiss: () {
                setState(() => _hintShown = true);
              }),
            ),
          // Zoom controls (buttons for tap-to-zoom on mobile)
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoomButton(
                  icon: Icons.zoom_out,
                  onTap: () {
                    final cur = _transformController.value.getMaxScaleOnAxis();
                    final target = (cur * 0.8).clamp(_kMinScale, _kMaxScale);
                    _transformController.value =
                        Matrix4.diagonal3Values(target, target, 1.0);
                  },
                ),
                const SizedBox(width: 6),
                _ZoomButton(
                  icon: Icons.zoom_in,
                  onTap: () {
                    final cur = _transformController.value.getMaxScaleOnAxis();
                    final target = (cur * 1.25).clamp(_kMinScale, _kMaxScale);
                    _transformController.value =
                        Matrix4.diagonal3Values(target, target, 1.0);
                  },
                ),
                const SizedBox(width: 6),
                _ZoomButton(
                  icon: Icons.fit_screen,
                  onTap: () {
                    _transformController.value =
                        Matrix4.diagonal3Values(fitScale, fitScale, 1.0);
                  },
                ),
              ],
            ),
          ),
          // Scale indicator
          Positioned(
            bottom: 8,
            right: 8,
            child: _ScaleIndicator(controller: _transformController),
          ),
        ],
      );
    });
  }

  // ── Grid builder (shared) ───────────────────────────────────────────────────

  Widget _buildGrid(GameState gs, double ts) {
    final gridW = ts * gs.width;
    final gridH = ts * gs.height;

    return Container(
      width: gridW,
      height: gridH,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // ── Real Graphic Board Tiles (Floor, Wall, Hole, Cracked Ice) ──
            for (int y = 0; y < gs.height; y++)
              for (int x = 0; x < gs.width; x++)
                Positioned(
                  left: x * ts,
                  top: y * ts,
                  width: ts,
                  height: ts,
                  child: _BoardTileWidget(
                    type: gs.tiles[y][x],
                    tileSize: ts,
                  ),
                ),

            // ── 3D Sliding Ice Blocks ─────────────────────────────────────
            for (final blk in gs.blocks)
              _IceBlockWidget(pos: blk.pos, tileSize: ts),

            // ── Sparkling Golden Fish Treat Coins ────────────────────────
            for (final f in gs.fish)
              _FishWidget(pos: f, tileSize: ts),

            // ── Penguins (Disappear when entered in igloo) ───────────────
            for (final pg in gs.penguins)
              if (!pg.inIgloo)
                _PenguinWidget(
                  penguin: pg,
                  tileSize: ts,
                  isSelected: pg.id == gs.selectedId,
                  onTap: () => widget.onPenguinTap(pg.id),
                  isDeadClump: isDeadClump(
                    gs.penguins
                        .where((p) => !p.inIgloo && p.clumpId == pg.clumpId)
                        .toList(),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Zoom hint badge ─────────────────────────────────

class _ZoomHintBadge extends StatelessWidget {
  final VoidCallback onDismiss;
  const _ZoomHintBadge({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black54,
          border: Border.all(
              color: Colors.lightBlueAccent.withValues(alpha: 0.6), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                color: Colors.white70, size: 14),
            SizedBox(width: 6),
            Text(
              'Pinch to zoom · Drag to pan',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 400.ms)
          .then(delay: 3000.ms)
          .fadeOut(duration: 600.ms),
    );
  }
}

// ─────────────────────────── Scale indicator ─────────────────────────────────

class _ScaleIndicator extends StatefulWidget {
  final TransformationController controller;
  const _ScaleIndicator({required this.controller});

  @override
  State<_ScaleIndicator> createState() => _ScaleIndicatorState();
}

class _ScaleIndicatorState extends State<_ScaleIndicator> {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTransform);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTransform);
    super.dispose();
  }

  void _onTransform() {
    final m = widget.controller.value;
    setState(() => _scale = m.getMaxScaleOnAxis());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black45,
      ),
      child: Text(
        '${(_scale * 100).round()}%',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}



// ─────────────────────────── Penguin Widget ──────────────────────────────────

class _PenguinWidget extends StatelessWidget {
  final Penguin penguin;
  final double tileSize;
  final bool isSelected;
  final bool isDeadClump;
  final VoidCallback onTap;

  const _PenguinWidget({
    required this.penguin,
    required this.tileSize,
    required this.isSelected,
    required this.isDeadClump,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pad = tileSize * 0.05;
    final size = tileSize - pad * 2;
    final left = penguin.pos.x * tileSize + pad;
    final top = penguin.pos.y * tileSize + pad;

    Widget body = GestureDetector(
      onTap: onTap,
      child: KawaiiPenguin(
        color: penguin.color,
        size: size,
        isSelected: isSelected,
        isDead: isDeadClump,
        showBadge: true,
        movesLeft: penguin.movesLeft,
      ),
    );

    // Keep board penguins static and clean
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      left: left,
      top: top,
      child: body,
    );
  }
}

// ── Board Tile Widget (Floor, Wall, Hole, Cracked Ice, Igloo) ─────────────

class _BoardTileWidget extends StatelessWidget {
  final TileType type;
  final double tileSize;

  const _BoardTileWidget({required this.type, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case TileType.wall:
        return Image.asset(
          'assets/images/tiles/stone_wall.jpg',
          fit: BoxFit.cover,
        );
      case TileType.hole:
      case TileType.water:
        return Image.asset(
          'assets/images/tiles/ice_hole.jpg',
          fit: BoxFit.cover,
        );
      case TileType.cracked:
        return Image.asset(
          'assets/images/tiles/cracked_ice.jpg',
          fit: BoxFit.cover,
        );
      case TileType.slippery:
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/tiles/ice_floor.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.lightBlueAccent.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        );
      case TileType.igloo:
        return Image.asset(
          'assets/images/tiles/igloo_camp.jpg',
          fit: BoxFit.cover,
        );
      default:
        return Image.asset(
          'assets/images/tiles/ice_floor.jpg',
          fit: BoxFit.cover,
        );
    }
  }
}

// ─────────────────────────── Ice Block ───────────────────────────────────────

class _IceBlockWidget extends StatelessWidget {
  final Position pos;
  final double tileSize;
  const _IceBlockWidget({required this.pos, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: pos.x * tileSize,
      top: pos.y * tileSize,
      width: tileSize,
      height: tileSize,
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          'assets/images/tiles/ice_block.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─────────────────────────── Fish ────────────────────────────────────────────

class _FishWidget extends StatelessWidget {
  final Position pos;
  final double tileSize;
  const _FishWidget({required this.pos, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    final cx = pos.x * tileSize + tileSize / 2;
    final cy = pos.y * tileSize + tileSize / 2;
    final sz = (tileSize * 0.55).clamp(16.0, 36.0);
    return Positioned(
      left: cx - sz / 2,
      top: cy - sz / 2,
      width: sz,
      height: sz,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/ui/fish_coin.jpg',
            fit: BoxFit.cover,
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.88, end: 1.12, duration: 900.ms),
    );
  }
}



// ─────────────────────────── Zoom Button ────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.lightBlueAccent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
