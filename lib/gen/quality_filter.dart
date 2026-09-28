// lib/gen/quality_filter.dart
//
// Reject levels that are too trivial or structurally broken.
// All checks are pure-logic (no UI).

import '../core/game_state.dart';
import '../core/rules.dart';
import '../core/penguin_types.dart';
import '../core/clumps.dart';

class QualityFilter {
  /// Returns true if the level passes all quality checks.
  static bool passes(
    GameState initial,
    List<({int penguinId, Direction dir})> solution,
  ) {
    // 1. Solution must be replayable to a win
    if (!_verifySolution(initial, solution)) return false;

    // 2. Not solvable by moving only one penguin
    if (_solvedByOnePenguin(initial)) return false;

    // 3. First move must not be the only possible move
    if (_firstMoveForced(initial)) return false;

    // 4. No immediate dead clump at start
    if (_hasImmediateDeadClump(initial)) return false;

    return true;
  }

  // ── Replay the planted solution and assert a win ─────────────────────────

  static bool _verifySolution(
    GameState initial,
    List<({int penguinId, Direction dir})> solution,
  ) {
    var state = initial;
    for (final step in solution) {
      final sel = state.copyWith(selectedId: step.penguinId);
      final result = tryMove(sel, step.penguinId, step.dir);
      if (result is! MoveSuccess) return false;
      state = result.next;
    }
    return checkWin(state);
  }

  // ── Reject if a single penguin can solve the level ───────────────────────

  static bool _solvedByOnePenguin(GameState initial) {
    for (final pg in initial.penguins) {
      if (_bfsSinglePenguin(initial, pg.id)) return true;
    }
    return false;
  }

  static bool _bfsSinglePenguin(GameState initial, int pgId) {
    // BFS up to depth 12 using only this one penguin
    final queue = <GameState>[initial.copyWith(selectedId: pgId)];
    final visited = <String>{};
    int depth = 0;
    final depthBoundary = <int>[queue.length];

    while (queue.isNotEmpty && depth < 12) {
      final state = queue.removeAt(0);
      final key = _stateKey(state);
      if (visited.contains(key)) continue;
      visited.add(key);

      for (final dir in Direction.values) {
        final result = tryMove(state, pgId, dir);
        if (result is MoveSuccess) {
          if (checkWin(result.next)) return true;
          queue.add(result.next.copyWith(selectedId: pgId));
        }
      }

      depthBoundary[0]--;
      if (depthBoundary[0] <= 0) {
        depth++;
        depthBoundary[0] = queue.length;
      }
    }
    return false;
  }

  // ── First move forced check ───────────────────────────────────────────────

  static bool _firstMoveForced(GameState initial) {
    int totalLegal = 0;
    for (final pg in initial.penguins) {
      final sel = initial.copyWith(selectedId: pg.id);
      for (final dir in Direction.values) {
        final r = tryMove(sel, pg.id, dir);
        if (r is MoveSuccess) totalLegal++;
      }
    }
    return totalLegal <= 1;
  }

  // ── Dead clump at start ───────────────────────────────────────────────────

  static bool _hasImmediateDeadClump(GameState initial) {
    final clumpIds = initial.penguins.map((p) => p.clumpId).toSet();
    for (final cid in clumpIds) {
      final group =
          initial.penguins.where((p) => p.clumpId == cid).toList();
      if (group.length > 1 && isDeadClump(group)) return true;
    }
    return false;
  }

  // ── Tiny state key for BFS visited set ───────────────────────────────────

  static String _stateKey(GameState s) {
    final positions = s.penguins.map((p) => '${p.id}:${p.pos.x},${p.pos.y}');
    return positions.join('|');
  }
}
