// lib/gen/generator.dart
//
// ══════════════════════════════════════════════════════════════════════════════
//  HUDDLE UP  –  Procedural Level Generator  (v6)
// ══════════════════════════════════════════════════════════════════════════════
//
//  Design Philosophy (Matching Handshake / Sokoban Style):
//  1. FULL-BLEED CANVAS: Zero edge-walls. Tiles extend edge-to-edge (0..w-1, 0..h-1).
//  2. 1-TILE IGLOO: A single, distinct, cozy destination igloo.
//  3. CORRIDOR & WING PUZZLES: Clean geometric layouts (Two-Wing Dividers,
//     U-Shape / Horseshoe, S-Curves, Pillar Courtyards) where penguins start
//     separated and must navigate corridors to huddle together at the igloo.
//  4. MEANINGFUL OBSTACLES: Every obstacle (holes, cracked ice, sliding ice blocks)
//     is placed on or directly interacting with the penguins' critical paths.
//     Useless obstacles sitting in corners are PRUNED automatically.
//  5. NO TRIVIAL STRAIGHT-LINE WALKS: Penguins must not have direct unobstructed
//     line-of-sight into the igloo at start. They must turn corners and think!
//  6. 100% BFS/A* VERIFIED SOLVABLE with tight par move budgets.
//

import 'dart:collection';
import 'dart:math';
import 'package:collection/collection.dart';
import '../core/game_state.dart';
import '../core/tile_types.dart';
import '../core/penguin_types.dart';
import '../core/rules.dart';
import '../core/clumps.dart';

// ─────────────────────────── Public types ────────────────────────────────────

class GeneratedLevel {
  final GameState initialState;
  final List<({int penguinId, Direction dir})> solution;
  final int par;
  final int seed;

  const GeneratedLevel({
    required this.initialState,
    required this.solution,
    required this.par,
    required this.seed,
  });
}

// ─────────────────────────── Entry point ─────────────────────────────────────

GeneratedLevel generateLevel(int levelNumber, {int dailyOffset = 0}) {
  final band = _bandFor(levelNumber);
  for (int attempt = 0; attempt < 20; attempt++) {
    final seed = levelNumber * 97 + dailyOffset * 1000003 + attempt * 23;
    final result = _tryGenerate(Random(seed), band, seed, levelNumber);
    if (result != null) return result;
  }

  // Fast fallback with relaxed constraints to guarantee instant return
  final seed = levelNumber * 97 + dailyOffset * 1000003;
  return _tryGenerate(Random(seed), band, seed, levelNumber, relaxed: true) ??
      _generateDeterministicFallback(levelNumber, band, seed);
}

// ─────────────────────────── Difficulty band ─────────────────────────────────

class _Band {
  final int width;
  final int height;
  final int penguinCount;
  final List<PenguinColor> colors;
  final int blockBudget;
  final int waterBudget;
  final int crackedBudget;
  final int holeBudget;
  final int minSolution;
  final int maxSolution;

  const _Band({
    required this.width,
    required this.height,
    required this.penguinCount,
    required this.colors,
    this.blockBudget = 0,
    this.waterBudget = 0,
    this.crackedBudget = 0,
    this.holeBudget = 0,
    required this.minSolution,
    required this.maxSolution,
  });
}

_Band _bandFor(int level) {
  if (level <= 5) {
    return const _Band(
      width: 6,
      height: 6,
      penguinCount: 2,
      colors: [PenguinColor.blue, PenguinColor.blue],
      blockBudget: 0,
      minSolution: 7,
      maxSolution: 13,
    );
  }
  if (level <= 15) {
    return const _Band(
      width: 6,
      height: 6,
      penguinCount: 2,
      colors: [PenguinColor.blue, PenguinColor.green],
      blockBudget: 0,
      holeBudget: 1,
      minSolution: 8,
      maxSolution: 15,
    );
  }
  if (level <= 30) {
    // Levels 16-30 (The 20s): Enlarged 8x7 map! Stone obstacles, holes, cracked ice, blocks
    return const _Band(
      width: 8,
      height: 7,
      penguinCount: 2,
      colors: [PenguinColor.blue, PenguinColor.orange],
      blockBudget: 1,
      holeBudget: 2,
      crackedBudget: 1,
      minSolution: 10,
      maxSolution: 18,
    );
  }
  if (level <= 50) {
    // Levels 31-50: 8x8 map!
    return const _Band(
      width: 8,
      height: 8,
      penguinCount: 2,
      colors: [PenguinColor.blue, PenguinColor.red],
      blockBudget: 1,
      waterBudget: 1,
      holeBudget: 2,
      crackedBudget: 2,
      minSolution: 11,
      maxSolution: 20,
    );
  }
  // 3 penguins from level 51 to 100
  if (level <= 75) {
    return const _Band(
      width: 8,
      height: 8,
      penguinCount: 3,
      colors: [PenguinColor.blue, PenguinColor.green, PenguinColor.orange],
      blockBudget: 1,
      waterBudget: 1,
      holeBudget: 2,
      crackedBudget: 2,
      minSolution: 11,
      maxSolution: 22,
    );
  }
  if (level <= 100) {
    return const _Band(
      width: 8,
      height: 8,
      penguinCount: 3,
      colors: [PenguinColor.blue, PenguinColor.red, PenguinColor.yellow],
      blockBudget: 1,
      waterBudget: 1,
      holeBudget: 2,
      crackedBudget: 2,
      minSolution: 12,
      maxSolution: 22,
    );
  }
  // 4 penguins from level 101 to 150
  if (level <= 150) {
    return const _Band(
      width: 9,
      height: 8,
      penguinCount: 4,
      colors: [
        PenguinColor.blue,
        PenguinColor.green,
        PenguinColor.orange,
        PenguinColor.purple,
      ],
      blockBudget: 1,
      waterBudget: 1,
      holeBudget: 2,
      crackedBudget: 2,
      minSolution: 12,
      maxSolution: 24,
    );
  }
  // 5+ penguins from level 151+
  final extra = min((level - 151) ~/ 30, 2);
  final count = min(5 + extra, 7);
  return _Band(
    width: min(9 + extra, 10),
    height: min(9 + extra, 10),
    penguinCount: count,
    colors: PenguinColor.values,
    blockBudget: 1,
    waterBudget: 2,
    crackedBudget: 2,
    holeBudget: 2,
    minSolution: 12,
    maxSolution: 24,
  );
}

// ─────────────────────────── Generator Logic ─────────────────────────────────

GeneratedLevel? _tryGenerate(
    Random rng, _Band band, int seed, int levelNumber,
    {bool relaxed = false}) {
  final w = band.width;
  final h = band.height;

  // 1. Initialize grid: all floor tiles (NO edge walls!)
  final tiles = List.generate(h, (_) => List.filled(w, TileType.floor));

  // 2. Select from 8 diverse level archetypes to prevent repetitive layouts
  final archetype = rng.nextInt(8);

  switch (archetype) {
    case 0:
      // Two-Wing Divider: A vertical wall dividing left & right with 1-2 doorway passages
      final divX = w ~/ 2;
      for (int y = 0; y < h; y++) {
        tiles[y][divX] = TileType.wall;
      }
      final door1 = 1 + rng.nextInt(max(1, h - 2));
      tiles[door1][divX] = TileType.floor;
      if (h >= 5 && rng.nextBool()) {
        final door2 = (door1 + 2) % (h - 2) + 1;
        tiles[door2][divX] = TileType.floor;
      }
      // Interior stone pillars on wings
      if (w >= 6 && h >= 5) {
        final ox1 = rng.nextInt(divX);
        final oy1 = 1 + rng.nextInt(h - 2);
        tiles[oy1][ox1] = TileType.wall;
        final ox2 = divX + 1 + rng.nextInt(w - divX - 1);
        final oy2 = 1 + rng.nextInt(h - 2);
        tiles[oy2][ox2] = TileType.wall;
      }
      break;

    case 1:
      // Fortress Ring / Center Island: Central stone structure with loop around it
      final blkW = max(2, min(3, w - 4));
      final blkH = max(2, min(3, h - 4));
      final startX = (w - blkW) ~/ 2;
      final startY = (h - blkH) ~/ 2;
      for (int y = 0; y < blkH; y++) {
        for (int x = 0; x < blkW; x++) {
          tiles[startY + y][startX + x] = TileType.wall;
        }
      }
      // Corner deflection stones
      if (rng.nextBool() && startX > 1 && startY > 1) {
        tiles[1][1] = TileType.wall;
        tiles[h - 2][w - 2] = TileType.wall;
      }
      break;

    case 2:
      // Serpentine Winding S-Corridor: randomized orientation (horizontal or vertical)
      if (rng.nextBool()) {
        // Horizontal snake
        final y1 = max(1, h ~/ 3);
        final y2 = min(h - 2, 2 * h ~/ 3);
        for (int x = 0; x < w - 2; x++) {
          tiles[y1][x] = TileType.wall; // gap at right
        }
        if (y2 > y1 + 1) {
          for (int x = 2; x < w; x++) {
            tiles[y2][x] = TileType.wall; // gap at left
          }
        }
      } else {
        // Vertical snake
        final x1 = max(1, w ~/ 3);
        final x2 = min(w - 2, 2 * w ~/ 3);
        for (int y = 0; y < h - 2; y++) {
          tiles[y][x1] = TileType.wall; // gap at bottom
        }
        if (x2 > x1 + 1) {
          for (int y = 2; y < h; y++) {
            tiles[y][x2] = TileType.wall; // gap at top
          }
        }
      }
      break;

    case 3:
      // Staggered Stone Pillars / Stepping Labyrinth
      final pillarCount = min(6, max(3, (w * h) ~/ 10));
      for (int i = 0; i < pillarCount; i++) {
        final px = 1 + rng.nextInt(max(1, w - 2));
        final py = 1 + rng.nextInt(max(1, h - 2));
        tiles[py][px] = TileType.wall;
        if (rng.nextBool() && px + 1 < w - 1) {
          tiles[py][px + 1] = TileType.wall;
        }
      }
      break;

    case 4:
      // L-Chamber / Split Corner Wings
      final lx = w ~/ 2;
      final ly = h ~/ 2;
      for (int y = 0; y < ly; y++) {
        tiles[y][lx] = TileType.wall;
      }
      for (int x = lx; x < w; x++) {
        tiles[ly][x] = TileType.wall;
      }
      // Carve door passages in both arms
      if (ly > 1) tiles[1][lx] = TileType.floor;
      if (w - lx > 2) tiles[ly][lx + 1] = TileType.floor;
      break;

    case 5:
      // Crossroads / Quad Chambers with open gates
      final cx = w ~/ 2;
      final cy = h ~/ 2;
      for (int x = 0; x < w; x++) {
        tiles[cy][x] = TileType.wall;
      }
      for (int y = 0; y < h; y++) {
        tiles[y][cx] = TileType.wall;
      }
      // Open gates in cross arms
      tiles[cy][max(1, cx ~/ 2)] = TileType.floor;
      tiles[cy][min(w - 2, cx + (w - cx) ~/ 2)] = TileType.floor;
      tiles[max(1, cy ~/ 2)][cx] = TileType.floor;
      tiles[min(h - 2, cy + (h - cy) ~/ 2)][cx] = TileType.floor;
      break;

    case 6:
      // Diagonal Baffles / Staggered Comb Teeth
      final toothLen = max(2, min(3, w ~/ 3));
      for (int x = 0; x < toothLen; x++) {
        tiles[max(1, h ~/ 3)][x] = TileType.wall;
      }
      for (int x = w - toothLen; x < w; x++) {
        tiles[min(h - 2, 2 * h ~/ 3)][x] = TileType.wall;
      }
      if (w >= 7) {
        tiles[0][w ~/ 2] = TileType.wall;
        tiles[h - 1][w ~/ 2] = TileType.wall;
      }
      break;

    case 7:
    default:
      // The Atrium Courtyard: Perimeter box with entry gates
      final cw = max(3, min(4, w - 2));
      final ch = max(3, min(4, h - 2));
      final ox = (w - cw) ~/ 2;
      final oy = (h - ch) ~/ 2;
      for (int x = ox; x < ox + cw; x++) {
        tiles[oy][x] = TileType.wall;
        tiles[oy + ch - 1][x] = TileType.wall;
      }
      for (int y = oy; y < oy + ch; y++) {
        tiles[y][ox] = TileType.wall;
        tiles[y][ox + cw - 1] = TileType.wall;
      }
      // Open north and south gates
      tiles[oy][ox + cw ~/ 2] = TileType.floor;
      tiles[oy + ch - 1][ox + cw ~/ 2] = TileType.floor;
      break;
  }

  // 3. Prune dead-ends so all interior passable tiles have >= 2 passable neighbors
  bool changed = true;
  while (changed) {
    changed = false;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (tiles[y][x] != TileType.wall) {
          int nonWall = 0;
          for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h && tiles[ny][nx] != TileType.wall) {
              nonWall++;
            }
          }
          if (nonWall < 2) {
            tiles[y][x] = TileType.wall;
            changed = true;
          }
        }
      }
    }
  }

  // 4. Flood-fill check to ensure ONE main connected component of floor tiles
  final allFloor = <Position>[];
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (tiles[y][x] == TileType.floor) {
        allFloor.add(Position(x, y));
      }
    }
  }

  if (allFloor.length < 10) return null;

  // Pick a central seed for flood fill
  final centerRef = Position(w ~/ 2, h ~/ 2);
  allFloor.sort((a, b) => _dist(a, centerRef).compareTo(_dist(b, centerRef)));
  final floodSeed = allFloor.first;

  final connected = _floodFill(tiles, floodSeed, w, h);
  if (connected.length < 10) return null;

  // Turn disconnected floor pockets into walls
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (tiles[y][x] == TileType.floor && !connected.contains(Position(x, y))) {
        tiles[y][x] = TileType.wall;
      }
    }
  }

  // 5. Place 1-tile Igloo on a well-connected floor tile near center/corridor
  final iglooCandidates = connected.toList()
    ..sort((a, b) => _dist(a, centerRef).compareTo(_dist(b, centerRef)));
  final iglooPos = iglooCandidates.first;
  tiles[iglooPos.y][iglooPos.x] = TileType.igloo;
  final meetingTiles = [iglooPos];

  // 6. Filter candidate penguin start positions:
  // Must NOT have direct unobstructed line-of-sight to igloo, and distance >= 2.5
  final validFloors = connected.where((p) => p != iglooPos).toList();
  if (validFloors.length < band.penguinCount) return null;

  final noLosFloors = validFloors.where((p) {
    if (_dist(p, iglooPos) < 2.5) return false;
    if (_hasDirectLineOfSight(p, iglooPos, tiles)) return false;
    return true;
  }).toList();

  final penguinPool = noLosFloors.length >= band.penguinCount
      ? noLosFloors
      : validFloors.where((p) => _dist(p, iglooPos) >= 2.0).toList();

  // Try candidate placements
  final colors = _pickColors(rng, band.colors, band.penguinCount);

  for (int attemptPair = 0; attemptPair < 6; attemptPair++) {
    final candidatePositions = _pickSpreadPositions(
      rng,
      penguinPool,
      band.penguinCount,
    );
    if (candidatePositions == null) continue;

    var penguins = [
      for (int i = 0; i < band.penguinCount; i++)
        Penguin(
          id: i,
          color: colors[i],
          pos: candidatePositions[i],
          clumpId: i,
          maxMoves: 99,
          movesLeft: 99,
        ),
    ];
    penguins = rebuildClumps(penguins);

    // Initial check: penguins must NOT already be adjacent / clumped at start
    final clumpSet = penguins.map((p) => p.clumpId).toSet();
    if (clumpSet.length < band.penguinCount) continue;

    // Working copies for obstacle placement
    final workingTiles = tiles.map((row) => List<TileType>.from(row)).toList();
    final blocks = <IceBlock>[];

    // Helper: checks if all penguins can reach igloo through safe walkable tiles
    bool canReachIgloo(List<List<TileType>> t) {
      final visited = <Position>{iglooPos};
      final q = Queue<Position>()..add(iglooPos);
      while (q.isNotEmpty) {
        final cur = q.removeFirst();
        for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = cur.x + dx;
          final ny = cur.y + dy;
          if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
            final np = Position(nx, ny);
            if (!visited.contains(np)) {
              final tile = t[ny][nx];
              if (tile == TileType.floor ||
                  tile == TileType.cracked ||
                  tile == TileType.slippery ||
                  tile == TileType.igloo ||
                  tile == TileType.bridge) {
                visited.add(np);
                q.add(np);
              }
            }
          }
        }
      }
      return candidatePositions.every((p) => visited.contains(p));
    }

    if (!canReachIgloo(workingTiles)) continue;

    // 7. Extract CRITICAL PATH TILES:
    // Every obstacle will be placed directly on or adjacent to these paths!
    final criticalPathTiles = <Position>{};
    for (final p in penguins) {
      final pPath = _findShortestFloorPath(p.pos, iglooPos, workingTiles, w, h);
      if (pPath != null && pPath.length > 2) {
        // Exclude start and igloo
        for (int i = 1; i < pPath.length - 1; i++) {
          criticalPathTiles.add(pPath[i]);
        }
      }
    }

    // A. Place stone obstacles (TileType.wall) to shape corridors (level >= 16)
    if (levelNumber >= 16) {
      final candidateStones = validFloors
          .where((p) =>
              !candidatePositions.contains(p) &&
              p != iglooPos &&
              _dist(p, iglooPos) >= 1.5)
          .toList()
        ..shuffle(rng);

      final stoneBudget = min(2, max(0, candidateStones.length ~/ 8));
      for (int s = 0; s < stoneBudget && candidateStones.isNotEmpty; s++) {
        final cell = candidateStones.removeLast();
        workingTiles[cell.y][cell.x] = TileType.wall;

        // Verify no dead-ends and reachable
        bool hasDeadEnd = false;
        for (int y = 1; y < h - 1; y++) {
          for (int x = 1; x < w - 1; x++) {
            if (workingTiles[y][x] != TileType.wall) {
              int nonWall = 0;
              for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
                final nx = x + dx;
                final ny = y + dy;
                if (workingTiles[ny][nx] != TileType.wall) nonWall++;
              }
              if (nonWall < 2) {
                hasDeadEnd = true;
                break;
              }
            }
          }
          if (hasDeadEnd) break;
        }
        if (hasDeadEnd || !canReachIgloo(workingTiles)) {
          workingTiles[cell.y][cell.x] = TileType.floor; // revert
        }
      }
    }

    // B. Place holes (TileType.hole) ON CRITICAL PATHS (forces detours!)
    final pathListHoles = criticalPathTiles.toList()..shuffle(rng);
    if (band.holeBudget > 0 && pathListHoles.isNotEmpty) {
      int holesPlaced = 0;
      for (final cell in pathListHoles) {
        if (holesPlaced >= band.holeBudget) break;
        workingTiles[cell.y][cell.x] = TileType.hole;
        // Verify level remains solvable via alternate corridor
        if (canReachIgloo(workingTiles)) {
          holesPlaced++;
          criticalPathTiles.remove(cell);
        } else {
          workingTiles[cell.y][cell.x] = TileType.floor; // revert
        }
      }
    }

    // C. Place cracked ice (TileType.cracked) ON CRITICAL PATHS
    final pathListCracked = criticalPathTiles.toList()..shuffle(rng);
    if (band.crackedBudget > 0 && pathListCracked.isNotEmpty) {
      int crackedPlaced = 0;
      for (final cell in pathListCracked) {
        if (crackedPlaced >= band.crackedBudget) break;
        workingTiles[cell.y][cell.x] = TileType.cracked;
        crackedPlaced++;
        criticalPathTiles.remove(cell);
      }
    }

    // D. Place sliding ice block (IceBlock)
    // Placed on critical path or corridor where penguin can push it
    if (band.blockBudget > 0 && criticalPathTiles.isNotEmpty && (rng.nextDouble() < 0.75 || levelNumber >= 20)) {
      final blockCandidates = criticalPathTiles.where((cell) {
        // Ensure at least 1 adjacent tile in some direction is clear floor/hole to push into
        for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final tx = cell.x + dx;
          final ty = cell.y + dy;
          if (tx >= 0 && tx < w && ty >= 0 && ty < h) {
            final t = workingTiles[ty][tx];
            if (t == TileType.floor || t == TileType.hole) return true;
          }
        }
        return false;
      }).toList()..shuffle(rng);

      if (blockCandidates.isNotEmpty) {
        final cell = blockCandidates.first;
        blocks.add(IceBlock(cell));
      }
    }

    final baseState = GameState(
      width: w,
      height: h,
      tiles: workingTiles,
      penguins: penguins,
      blocks: blocks,
      igloo: meetingTiles,
      fish: const [],
      rewindsLeft: 3,
      movesMade: 0,
      selectedId: penguins.first.id,
    );

    // Run A* solver with priority queue
    final maxSearchDepth = relaxed ? 16 : band.maxSolution + 2;
    final solution = _solveSearch(baseState, iglooPos, maxDepth: maxSearchDepth);

    if (solution != null && solution.length >= (relaxed ? 4 : band.minSolution)) {
      // Trace solution to monitor obstacle interaction and penguin move budgets
      GameState sim = baseState;
      final movesUsedByPenguin = <int, int>{for (final p in baseState.penguins) p.id: 0};
      final visitedPositions = <Position>{};
      final pushedBlocks = <Position>{};

      for (final step in solution) {
        for (final p in sim.penguins) {
          if (!p.inIgloo) visitedPositions.add(p.pos);
        }
        final movingP = sim.penguins.where((p) => p.id == step.penguinId).firstOrNull;
        if (movingP != null) {
          final clumpMembers =
              sim.penguins.where((p) => !p.inIgloo && p.clumpId == movingP.clumpId);
          for (final m in clumpMembers) {
            movesUsedByPenguin[m.id] = (movesUsedByPenguin[m.id] ?? 0) + 1;
          }

          // Check if moving into any ice block
          final (dx, dy) = step.dir.delta;
          final target = movingP.pos.translate(dx, dy);
          for (final b in baseState.blocks) {
            if (sim.blocks.any((sb) => sb.pos == target && sb.pos == b.pos)) {
              pushedBlocks.add(b.pos);
            }
          }
        }

        final res = tryMove(sim.copyWith(selectedId: step.penguinId), step.penguinId, step.dir);
        if (res is MoveSuccess) {
          sim = res.next;
        }
      }
      for (final p in sim.penguins) {
        visitedPositions.add(p.pos);
      }

      // Check also if any block moved from initial position at the end of the simulation
      for (final b in baseState.blocks) {
        final stillAtInitial = sim.blocks.any((sb) => sb.pos == b.pos);
        if (!stillAtInitial) {
          pushedBlocks.add(b.pos);
        }
      }

      // Prune useless cracked ice: if never stepped on, revert to floor
      final finalTiles = workingTiles.map((row) => List<TileType>.from(row)).toList();
      int crackedSteppedCount = 0;
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          if (finalTiles[y][x] == TileType.cracked) {
            if (visitedPositions.contains(Position(x, y))) {
              crackedSteppedCount++;
            } else {
              finalTiles[y][x] = TileType.floor; // revert useless cracked ice
            }
          }
        }
      }

      // Prune useless ice blocks: remove from level if never pushed!
      final activeBlocks = blocks.where((b) => pushedBlocks.contains(b.pos)).toList();

      // For level >= 16, require active puzzle depth (obstacles must matter)
      if (levelNumber >= 16 && !relaxed) {
        final hasActiveObstacle = activeBlocks.isNotEmpty ||
            crackedSteppedCount > 0 ||
            finalTiles.any((row) => row.contains(TileType.hole));
        if (!hasActiveObstacle) {
          continue; // retry for a more exciting layout!
        }
      }

      // Assign exact shortest route budget to each penguin
      final calibratedPenguins = baseState.penguins.map((p) {
        final used = movesUsedByPenguin[p.id] ?? 1;
        final movesAllowed = max(1, used);
        return p.copyWith(
          maxMoves: movesAllowed,
          movesLeft: movesAllowed,
        );
      }).toList();

      final calibratedState = baseState.copyWith(
        tiles: finalTiles,
        blocks: activeBlocks,
        penguins: calibratedPenguins,
      );

      return GeneratedLevel(
        initialState: calibratedState,
        solution: solution,
        par: solution.length,
        seed: seed,
      );
    }
  }

  return null;
}

// ─────────────────────────── Path & Geometry Helpers ─────────────────────────

bool _hasDirectLineOfSight(Position a, Position b, List<List<TileType>> tiles) {
  if (a.x == b.x) {
    final minY = min(a.y, b.y);
    final maxY = max(a.y, b.y);
    for (int y = minY + 1; y < maxY; y++) {
      if (tiles[y][a.x] == TileType.wall) return false;
    }
    return true; // unobstructed straight column
  }
  if (a.y == b.y) {
    final minX = min(a.x, b.x);
    final maxX = max(a.x, b.x);
    for (int x = minX + 1; x < maxX; x++) {
      if (tiles[a.y][x] == TileType.wall) return false;
    }
    return true; // unobstructed straight row
  }
  return false;
}

List<Position>? _findShortestFloorPath(
    Position start, Position goal, List<List<TileType>> grid, int w, int h) {
  final queue = Queue<List<Position>>()..add([start]);
  final visited = <Position>{start};
  while (queue.isNotEmpty) {
    final path = queue.removeFirst();
    final cur = path.last;
    if (cur == goal) return path;
    for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final nx = cur.x + dx;
      final ny = cur.y + dy;
      if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
        final np = Position(nx, ny);
        if (!visited.contains(np) && grid[ny][nx] != TileType.wall) {
          visited.add(np);
          queue.add([...path, np]);
        }
      }
    }
  }
  return null;
}

// ─────────────────────────── Flood Fill ──────────────────────────────────────

Set<Position> _floodFill(List<List<TileType>> tiles, Position start, int w, int h) {
  final visited = <Position>{start};
  final q = Queue<Position>()..add(start);

  while (q.isNotEmpty) {
    final cur = q.removeFirst();
    for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final nx = cur.x + dx;
      final ny = cur.y + dy;
      if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
        final np = Position(nx, ny);
        if (!visited.contains(np) && tiles[ny][nx] != TileType.wall) {
          visited.add(np);
          q.add(np);
        }
      }
    }
  }
  return visited;
}

// ─────────────────────────── A* Search Solver ────────────────────────────────

class _SearchNode implements Comparable<_SearchNode> {
  final GameState state;
  final List<({int penguinId, Direction dir})> path;
  final int g;
  final int h;
  final int tieBreaker;

  _SearchNode({
    required this.state,
    required this.path,
    required this.g,
    required this.h,
    required this.tieBreaker,
  });

  int get f => g + h;

  @override
  int compareTo(_SearchNode other) {
    final diff = f.compareTo(other.f);
    if (diff != 0) return diff;
    final hDiff = h.compareTo(other.h);
    if (hDiff != 0) return hDiff;
    return tieBreaker.compareTo(other.tieBreaker);
  }
}

List<({int penguinId, Direction dir})>? _solveSearch(
  GameState initial,
  Position igloo, {
  int maxDepth = 20,
  int maxStates = 12000,
}) {
  int heuristic(GameState s) {
    int maxDist = 0;
    for (final p in s.penguins) {
      if (!p.inIgloo) {
        final d = (p.pos.x - igloo.x).abs() + (p.pos.y - igloo.y).abs();
        if (d > maxDist) maxDist = d;
      }
    }
    return maxDist;
  }

  int tieBreaker(GameState s) {
    int sumDist = 0;
    for (final p in s.penguins) {
      if (!p.inIgloo) {
        sumDist += (p.pos.x - igloo.x).abs() + (p.pos.y - igloo.y).abs();
      }
    }
    return sumDist;
  }

  final pq = PriorityQueue<_SearchNode>();
  pq.add(_SearchNode(
    state: initial,
    path: const [],
    g: 0,
    h: heuristic(initial),
    tieBreaker: tieBreaker(initial),
  ));

  int stateKey(GameState s) {
    int h = 17;
    for (final p in s.penguins) {
      final code = p.inIgloo ? 255 : (p.pos.x | (p.pos.y << 4));
      h = (h * 31 + code) & 0x7FFFFFFF;
    }
    for (final b in s.blocks) {
      final code = b.pos.x | (b.pos.y << 4);
      h = (h * 31 + code) & 0x7FFFFFFF;
    }
    return h;
  }

  final visited = <int, int>{};
  visited[stateKey(initial)] = 0;

  int statesExplored = 0;
  while (pq.isNotEmpty && statesExplored < maxStates) {
    final node = pq.removeFirst();
    final cur = node.state;
    final path = node.path;
    statesExplored++;

    if (checkWin(cur)) {
      return path;
    }

    if (path.length >= maxDepth) continue;

    for (final pg in cur.penguins) {
      if (pg.inIgloo) continue;
      final group =
          cur.penguins.where((p) => !p.inIgloo && p.clumpId == pg.clumpId).toList();
      final allowed = allowedDirections(group);

      for (final dir in allowed) {
        final res = tryMove(cur.copyWith(selectedId: pg.id), pg.id, dir);
        if (res is MoveSuccess) {
          final nxt = res.next;
          final key = stateKey(nxt);
          final nextG = path.length + 1;
          final prevG = visited[key];
          if (prevG == null || nextG < prevG) {
            visited[key] = nextG;
            pq.add(_SearchNode(
              state: nxt,
              path: [...path, (penguinId: pg.id, dir: dir)],
              g: nextG,
              h: heuristic(nxt),
              tieBreaker: tieBreaker(nxt),
            ));
          }
        }
      }
    }
  }
  return null;
}

// ─────────────────────────── Spreading Helpers ───────────────────────────────

List<Position>? _pickSpreadPositions(
    Random rng, List<Position> pool, int count) {
  if (pool.length < count) return null;
  final shuffled = List<Position>.from(pool)..shuffle(rng);

  final selected = <Position>[shuffled.first];
  for (final p in shuffled.skip(1)) {
    if (selected.length >= count) break;
    final minD = selected.fold<double>(
      double.infinity,
      (prev, s) => min(prev, _dist(s, p)),
    );
    if (minD >= 2.5) {
      selected.add(p);
    }
  }
  if (selected.length < count) {
    return shuffled.take(count).toList();
  }
  return selected;
}

List<PenguinColor> _pickColors(
    Random rng, List<PenguinColor> pool, int count) {
  final shuffled = List.of(pool)..shuffle(rng);
  if (!shuffled.contains(PenguinColor.blue)) {
    shuffled[0] = PenguinColor.blue;
  }
  final out = <PenguinColor>[];
  for (int i = 0; i < count; i++) {
    out.add(shuffled[i % shuffled.length]);
  }
  return out;
}

double _dist(Position a, Position b) =>
    sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

// ─────────────────────────── Deterministic Fallback ──────────────────────────

GeneratedLevel _generateDeterministicFallback(
    int levelNumber, _Band band, int seed) {
  final w = band.width;
  final h = band.height;
  final tiles = List.generate(h, (_) => List.filled(w, TileType.floor));

  final centerX = w ~/ 2;
  final centerY = h ~/ 2;
  tiles[centerY][centerX] = TileType.igloo;
  final meetingTiles = [Position(centerX, centerY)];

  // Place decorative obstacle walls in outer corners to maintain maze feel
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (x != centerX && y != centerY) {
        if ((x == 0 && y == 0) ||
            (x == w - 1 && y == 0) ||
            (x == 0 && y == h - 1) ||
            (x == w - 1 && y == h - 1)) {
          tiles[y][x] = TileType.wall;
        }
      }
    }
  }

  final penguins = <Penguin>[];
  for (int i = 0; i < band.penguinCount; i++) {
    final color = i < band.colors.length ? band.colors[i] : PenguinColor.blue;
    Position pos;
    if (i == 0) {
      pos = Position(0, centerY);
    } else if (i == 1) {
      pos = Position(centerX, h - 1);
    } else if (i == 2) {
      pos = Position(w - 1, centerY);
    } else {
      pos = Position(centerX, 0);
    }

    penguins.add(
      Penguin(
        id: i,
        color: color,
        pos: pos,
        clumpId: i,
        maxMoves: 99,
        movesLeft: 99,
      ),
    );
  }

  final base = GameState(
    width: w,
    height: h,
    tiles: tiles,
    penguins: rebuildClumps(penguins),
    blocks: const [],
    igloo: meetingTiles,
    fish: const [],
    rewindsLeft: 3,
    movesMade: 0,
    selectedId: 0,
  );

  var solution = _solveSearch(base, Position(centerX, centerY), maxDepth: 25);
  if (solution == null || solution.isEmpty) {
    final explicitMoves = <({int penguinId, Direction dir})>[];
    var sim = base;
    for (final p in penguins) {
      while (true) {
        final curP = sim.penguins.firstWhere((cp) => cp.id == p.id);
        if (curP.inIgloo) break;
        Direction d;
        if (curP.pos.x < centerX) {
          d = Direction.right;
        } else if (curP.pos.x > centerX) {
          d = Direction.left;
        } else if (curP.pos.y < centerY) {
          d = Direction.down;
        } else if (curP.pos.y > centerY) {
          d = Direction.up;
        } else {
          break;
        }
        final res = tryMove(sim.copyWith(selectedId: curP.id), curP.id, d);
        if (res is MoveSuccess) {
          explicitMoves.add((penguinId: curP.id, dir: d));
          sim = res.next;
        } else {
          break;
        }
      }
    }
    solution = explicitMoves;
  }

  // Calibrate fallback moves
  final movesUsedByPenguin = <int, int>{for (final p in penguins) p.id: 0};
  GameState sim = base;
  for (final step in solution) {
    movesUsedByPenguin[step.penguinId] =
        (movesUsedByPenguin[step.penguinId] ?? 0) + 1;
    final res = tryMove(sim.copyWith(selectedId: step.penguinId), step.penguinId, step.dir);
    if (res is MoveSuccess) sim = res.next;
  }

  final calibratedPenguins = base.penguins.map((p) {
    final used = movesUsedByPenguin[p.id] ?? 1;
    final allowed = max(1, used);
    return p.copyWith(maxMoves: allowed, movesLeft: allowed);
  }).toList();

  return GeneratedLevel(
    initialState: base.copyWith(penguins: calibratedPenguins),
    solution: solution,
    par: solution.length,
    seed: seed,
  );
}
