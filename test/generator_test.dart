// test/generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle_up/core/rules.dart';
import 'package:huddle_up/core/tile_types.dart';
import 'package:huddle_up/gen/generator.dart';

void main() {
  test('Levels 1 to 50 generate 2 penguins, 100% solvable, meeting spot, and NO dead ends', () {
    for (final lvl in [1, 2, 5, 10, 20, 35, 50]) {
      final level = generateLevel(lvl);
      expect(level.solution.isNotEmpty, isTrue, reason: 'Level $lvl has empty solution');

      // 1. Check penguin count
      expect(level.initialState.penguins.length, equals(2),
          reason: 'Levels <= 50 must have exactly 2 penguins, got ${level.initialState.penguins.length} for lvl $lvl');

      // 2. Verify replay reaches WIN
      var s = level.initialState;
      for (final step in level.solution) {
        final res = tryMove(s.copyWith(selectedId: step.penguinId), step.penguinId, step.dir);
        expect(res is MoveSuccess, isTrue,
            reason: 'Lvl $lvl step failed: pg ${step.penguinId} dir ${step.dir}');
        s = (res as MoveSuccess).next;
      }
      expect(checkWin(s), isTrue, reason: 'Lvl $lvl solution did not reach win condition');

      // 3. Check meeting spot (igloo) exists
      expect(level.initialState.igloo.isNotEmpty, isTrue,
          reason: 'Meeting spot (igloo) should exist in level $lvl');

      // 4. Check dead ends (every floor/igloo tile has at least 2 passable neighbors)
      final tiles = level.initialState.tiles;
      final w = level.initialState.width;
      final h = level.initialState.height;
      for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
          if (tiles[y][x] != TileType.wall) {
            int floorNeighbors = 0;
            for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
              final nx = x + dx;
              final ny = y + dy;
              if (tiles[ny][nx] != TileType.wall) floorNeighbors++;
            }
            expect(floorNeighbors >= 2, isTrue,
                reason: 'Tile at ($x, $y) has only $floorNeighbors passable neighbors in level $lvl (dead end!)');
          }
        }
      }
    }
  });

  test('Levels 51+ have 3+ penguins and are solvable with no dead ends', () {
    for (final lvl in [51, 75, 100]) {
      final level = generateLevel(lvl);
      expect(level.initialState.penguins.length >= 3, isTrue);

      var s = level.initialState;
      for (final step in level.solution) {
        final res = tryMove(s.copyWith(selectedId: step.penguinId), step.penguinId, step.dir);
        expect(res is MoveSuccess, isTrue);
        s = (res as MoveSuccess).next;
      }
      expect(checkWin(s), isTrue, reason: 'Lvl $lvl solution did not reach win condition');
    }
  });

  test('Level 27 (The 20s) has 8x7 map, challenging moves, active obstacles, and no direct line of sight', () {
    final level = generateLevel(27);
    expect(level.initialState.width, equals(8));
    expect(level.initialState.height, equals(7));
    expect(level.solution.length >= 10, isTrue,
        reason: 'Level 27 solution length should be challenging (>= 10), got ${level.solution.length}');

    // Verify win condition
    var s = level.initialState;
    for (final step in level.solution) {
      final res = tryMove(s.copyWith(selectedId: step.penguinId), step.penguinId, step.dir);
      expect(res is MoveSuccess, isTrue);
      s = (res as MoveSuccess).next;
    }
    expect(checkWin(s), isTrue);

    // Verify penguins do not start on unobstructed line of sight to igloo
    final igloo = level.initialState.igloo.first;
    for (final p in level.initialState.penguins) {
      if (p.pos.x == igloo.x) {
        // Must have at least one wall or obstacle between them
        final minY = p.pos.y < igloo.y ? p.pos.y : igloo.y;
        final maxY = p.pos.y > igloo.y ? p.pos.y : igloo.y;
        bool blocked = false;
        for (int y = minY + 1; y < maxY; y++) {
          if (level.initialState.tiles[y][p.pos.x] == TileType.wall ||
              level.initialState.tiles[y][p.pos.x] == TileType.hole) {
            blocked = true;
            break;
          }
        }
        expect(blocked, isTrue, reason: 'Penguin at ${p.pos} has unobstructed line of sight to igloo $igloo');
      }
      if (p.pos.y == igloo.y) {
        final minX = p.pos.x < igloo.x ? p.pos.x : igloo.x;
        final maxX = p.pos.x > igloo.x ? p.pos.x : igloo.x;
        bool blocked = false;
        for (int x = minX + 1; x < maxX; x++) {
          if (level.initialState.tiles[p.pos.y][x] == TileType.wall ||
              level.initialState.tiles[p.pos.y][x] == TileType.hole) {
            blocked = true;
            break;
          }
        }
        expect(blocked, isTrue, reason: 'Penguin at ${p.pos} has unobstructed line of sight to igloo $igloo');
      }
    }
  });
}
