import 'dart:math';
import 'game_state.dart';
import 'tile_types.dart';
import 'penguin_types.dart';
import 'clumps.dart';

// ─────────────────────────── Result type ────────────────────────────────────

enum FailReason {
  wallBlocked,
  waterDeath,
  holeDeath,
  noLegalMove,
  deadClump,
}

sealed class MoveResult {}

class MoveSuccess extends MoveResult {
  final GameState next;
  MoveSuccess(this.next);
}

class MoveFail extends MoveResult {
  final FailReason reason;
  MoveFail(this.reason);
}

// ─────────────────────────── Win check ──────────────────────────────────────

bool checkWin(GameState s) {
  if (s.penguins.isEmpty) return false;
  // All penguins have entered the igloo!
  return s.penguins.every((p) => p.inIgloo);
}

// ─────────────────────────── tryMove ────────────────────────────────────────

MoveResult tryMove(GameState state, int penguinId, Direction dir) {
  final selected = state.penguins.firstWhere((p) => p.id == penguinId,
      orElse: () => throw StateError('No penguin $penguinId'));

  // Individual movement (each penguin moves on its own)
  final group = [selected];

  // Check if moving penguin has remaining moves
  if (selected.movesLeft <= 0) return MoveFail(FailReason.noLegalMove);

  // Check allowed directions
  final allowed = allowedDirections(group);
  if (allowed.isEmpty) return MoveFail(FailReason.deadClump);
  if (!allowed.contains(dir)) return MoveFail(FailReason.wallBlocked);

  final moveKind = clumpMoveKind(group);

  return switch (moveKind) {
    MoveKind.walk => _doWalk(state, group, dir, steps: 1),
    MoveKind.slideUntilBlocked => _doSlide(state, group, dir),
    MoveKind.hop2 => _doHop(state, group, dir),
    MoveKind.swap => _doSwap(state, group, dir),
    MoveKind.diagonalOnly => _doWalk(state, group, dir, steps: 1),
    MoveKind.chainPush => _doChainPush(state, group, dir),
  };
}

// ─────────────────────────── Walk (1 tile) ──────────────────────────────────

MoveResult _doWalk(
    GameState state, List<Penguin> group, Direction dir, {required int steps}) {
  final (dx, dy) = dir.delta;
  final newPositions = <int, Position>{};

  for (final pg in group) {
    final np = pg.pos.translate(dx * steps, dy * steps);
    // Wall / out of bounds
    if (state.isSolid(np)) return MoveFail(FailReason.wallBlocked);
    // Blocked by another penguin
    final occupant = state.penguinAt(np);
    if (occupant != null && occupant.id != pg.id) {
      return MoveFail(FailReason.wallBlocked);
    }
    // Ice block in the way?
    final block = state.blockAt(np);
    if (block != null) {
      final maxChain = group.any((g) => g.color == PenguinColor.grey) ? 3 : 1;
      final pushOk = _pushBlockChain(state, np, dir, maxChain);
      if (pushOk == null) return MoveFail(FailReason.wallBlocked);
      // Apply block chain push first
      return _applyWalkWithBlocks(state, group, dx * steps, dy * steps, pushOk);
    }
    newPositions[pg.id] = np;
  }
  return _applyWalk(state, group, newPositions);
}

// ─────────────────────────── Slide (Red) ────────────────────────────────────

MoveResult _doSlide(GameState state, List<Penguin> group, Direction dir) {
  // Solo Red slides until blocked
  final pg = group.first;
  final (dx, dy) = dir.delta;
  Position cur = pg.pos;
  while (true) {
    final np = cur.translate(dx, dy);
    if (state.isSolid(np)) break;
    if (state.penguinAt(np) != null) break;
    final block = state.blockAt(np);
    if (block != null) {
      // Push block forward one tile
      final pushed = _pushBlockChain(state, np, dir, 1);
      if (pushed == null) break;
      cur = np;
      // Apply slide up to here with the pushed block
      final newPenguins =
          _applyPositions(state.penguins, {pg.id: cur});
      return _applyTileEffects(
          state.copyWith(penguins: newPenguins, blocks: pushed));
    }
    cur = np;
  }
  if (cur == pg.pos) return MoveFail(FailReason.wallBlocked);
  final newPenguins = _applyPositions(state.penguins, {pg.id: cur});
  return _applyTileEffects(state.copyWith(penguins: newPenguins));
}

// ─────────────────────────── Hop 2 (Yellow) ─────────────────────────────────

MoveResult _doHop(GameState state, List<Penguin> group, Direction dir) {
  final pg = group.first;
  final (dx, dy) = dir.delta;
  final landing = pg.pos.translate(dx * 2, dy * 2);
  if (state.isSolid(landing)) return MoveFail(FailReason.wallBlocked);
  if (state.penguinAt(landing) != null) return MoveFail(FailReason.wallBlocked);
  if (state.blockAt(landing) != null) return MoveFail(FailReason.wallBlocked);
  final newPenguins = _applyPositions(state.penguins, {pg.id: landing});
  return _applyTileEffects(state.copyWith(penguins: newPenguins));
}

// ─────────────────────────── Swap (Purple) ──────────────────────────────────

MoveResult _doSwap(GameState state, List<Penguin> group, Direction dir) {
  final pg = group.first;
  final (dx, dy) = dir.delta;
  final target = pg.pos.translate(dx, dy);

  // Swap with penguin
  final occ = state.penguinAt(target);
  if (occ != null) {
    final newPenguins = state.penguins.map((p) {
      if (p.id == pg.id) return p.copyWith(pos: target);
      if (p.id == occ.id) return p.copyWith(pos: pg.pos);
      return p;
    }).toList();
    return _applyTileEffects(state.copyWith(penguins: newPenguins));
  }
  // Swap with block
  final blk = state.blockAt(target);
  if (blk != null) {
    final newBlocks = state.blocks
        .map((b) => b.pos == target ? IceBlock(pg.pos) : b)
        .toList();
    final newPenguins =
        _applyPositions(state.penguins, {pg.id: target});
    return _applyTileEffects(
        state.copyWith(penguins: newPenguins, blocks: newBlocks));
  }
  // No one there — do a normal walk
  return _doWalk(state, group, dir, steps: 1);
}

// ─────────────────────────── Chain push (Grey) ──────────────────────────────

MoveResult _doChainPush(GameState state, List<Penguin> group, Direction dir) {
  // Grey cannot step on cracked ice
  final pg = group.first;
  final (dx, dy) = dir.delta;
  final np = pg.pos.translate(dx, dy);
  if (state.tileAt(np) == TileType.cracked) return MoveFail(FailReason.wallBlocked);
  return _doWalk(state, group, dir, steps: 1);
}

// ─────────────────────────── Helpers ────────────────────────────────────────

/// Try to push a chain of ice blocks starting at [start] in [dir].
/// Returns updated block list, or null if blocked.
List<IceBlock>? _pushBlockChain(
    GameState state, Position start, Direction dir, int maxChain) {
  final (dx, dy) = dir.delta;
  final chain = <Position>[];
  Position cur = start;
  while (state.blockAt(cur) != null) {
    chain.add(cur);
    if (chain.length > maxChain) return null;
    cur = cur.translate(dx, dy);
  }
  // Destination of last block
  final dest = cur;
  if (state.isSolid(dest)) return null;
  if (state.penguinAt(dest) != null) return null;

  // Check if last block goes into water → bridge
  final newBlocks = List<IceBlock>.from(state.blocks);
  for (int i = 0; i < chain.length; i++) {
    final from = chain[i];
    final to = from.translate(dx, dy);
    final idx = newBlocks.indexWhere((b) => b.pos == from);
    if (idx < 0) continue;
    if (state.tileAt(to) == TileType.water || state.tileAt(to) == TileType.hole) {
      // Block sinks → becomes bridge, remove block
      newBlocks.removeAt(idx);
      // Note: tile update is handled in _applyTileEffects
    } else {
      newBlocks[idx] = IceBlock(to);
    }
  }
  return newBlocks;
}

/// Apply position delta to group with block chain result.
MoveResult _applyWalkWithBlocks(GameState state, List<Penguin> group,
    int dx, int dy, List<IceBlock> newBlocks) {
  final newPositions = {for (final pg in group) pg.id: pg.pos.translate(dx, dy)};
  // Check targets
  for (final entry in newPositions.entries) {
    final np = entry.value;
    if (state.isSolid(np)) return MoveFail(FailReason.wallBlocked);
    final occ = state.penguinAt(np);
    if (occ != null && !group.any((g) => g.id == occ.id)) {
      return MoveFail(FailReason.wallBlocked);
    }
  }
  final newPenguins = _applyPositions(state.penguins, newPositions);
  return _applyTileEffects(state.copyWith(penguins: newPenguins, blocks: newBlocks));
}

MoveResult _applyWalk(GameState state, List<Penguin> group,
    Map<int, Position> newPositions,
    {Penguin? additionalPenguinUpdate}) {
  // Validate no solid targets
  for (final np in newPositions.values) {
    if (state.isSolid(np)) return MoveFail(FailReason.wallBlocked);
  }
  var penguins = _applyPositions(state.penguins, newPositions);
  if (additionalPenguinUpdate != null) {
    penguins = penguins
        .map((p) =>
            p.id == additionalPenguinUpdate.id ? additionalPenguinUpdate : p)
        .toList();
  }
  return _applyTileEffects(state.copyWith(penguins: penguins));
}


List<Penguin> _applyPositions(
    List<Penguin> penguins, Map<int, Position> updates) {
  return penguins
      .map((p) => updates.containsKey(p.id)
          ? p.copyWith(
              pos: updates[p.id],
              movesLeft: max(0, p.movesLeft - 1),
            )
          : p)
      .toList();
}

/// Apply tile effects (water death, hole, cracked ice → hole, fish, slippery)
/// and rebuild clumps.
MoveResult _applyTileEffects(GameState state) {
  var penguins = List<Penguin>.from(state.penguins);
  var tiles = state.tiles.map((row) => List<TileType>.from(row)).toList();
  var blocks = List<IceBlock>.from(state.blocks);
  var fish = List<Position>.from(state.fish);

  for (final pg in penguins) {
    final t = state.tileAt(pg.pos);
    if (t == TileType.water) return MoveFail(FailReason.waterDeath);
    if (t == TileType.hole) return MoveFail(FailReason.holeDeath);
  }

  // Cracked ice → hole after crossing
  for (final pg in penguins) {
    final t = tiles[pg.pos.y][pg.pos.x];
    if (t == TileType.cracked) {
      tiles[pg.pos.y][pg.pos.x] = TileType.hole;
    }
  }

  // Block-into-water or hole → bridge tile
  for (final blk in List.from(blocks)) {
    final t = state.tileAt(blk.pos);
    if (t == TileType.water || t == TileType.hole) {
      tiles[blk.pos.y][blk.pos.x] = TileType.bridge;
      blocks.remove(blk);
    }
  }

  // Fish pickup
  for (final pg in penguins) {
    if (!pg.inIgloo && fish.contains(pg.pos)) {
      fish.remove(pg.pos);
    }
  }

  // Igloo entry: any penguin that reached the igloo enters and disappears inside
  final iglooSet = state.igloo.toSet();
  penguins = penguins.map((pg) {
    if (!pg.inIgloo &&
        (iglooSet.contains(pg.pos) || tiles[pg.pos.y][pg.pos.x] == TileType.igloo)) {
      return pg.copyWith(inIgloo: true);
    }
    return pg;
  }).toList();

  // Rebuild clumps
  penguins = rebuildClumps(penguins);

  // If the currently selected penguin entered the igloo, select a remaining penguin
  var nextSelectedId = state.selectedId;
  final currentSel = penguins.where((p) => p.id == nextSelectedId).firstOrNull;
  if (currentSel == null || currentSel.inIgloo) {
    final remaining = penguins.where((p) => !p.inIgloo).firstOrNull;
    nextSelectedId = remaining?.id ?? -1;
  }

  final fishPickedUp = state.fish.length - fish.length;
  final newState = state.copyWith(
    penguins: penguins,
    tiles: tiles,
    blocks: blocks,
    fish: fish,
    selectedId: nextSelectedId,
    rewindsLeft: state.rewindsLeft + fishPickedUp,
    movesMade: state.movesMade + 1,
  );

  return MoveSuccess(newState);
}
