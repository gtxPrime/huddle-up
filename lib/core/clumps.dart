// lib/core/clumps.dart
import 'game_state.dart';
import 'penguin_types.dart';

/// Returns the set of penguin ids that are reachable from [startId]
/// via orthogonal adjacency (= the same clump).
Set<int> clumpMembers(List<Penguin> penguins, int startId) {
  final posMap = {for (final p in penguins) if (!p.inIgloo) p.pos: p.id};
  final result = <int>{};
  final queue = <int>[startId];
  while (queue.isNotEmpty) {
    final id = queue.removeLast();
    if (result.contains(id)) continue;
    result.add(id);
    final pMatch = penguins.where((p) => p.id == id).firstOrNull;
    if (pMatch == null || pMatch.inIgloo) continue;
    final pos = pMatch.pos;
    for (final d in const [
      (0, -1),
      (0, 1),
      (-1, 0),
      (1, 0),
    ]) {
      final np = pos.translate(d.$1, d.$2);
      final nid = posMap[np];
      if (nid != null && !result.contains(nid)) queue.add(nid);
    }
  }
  return result;
}

/// After any move, rebuild clump IDs using union-find.
List<Penguin> rebuildClumps(List<Penguin> penguins) {
  // Union-Find
  final parent = {for (final p in penguins) p.id: p.id};

  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]!]!;
      x = parent[x]!;
    }
    return x;
  }

  void union(int a, int b) {
    final ra = find(a), rb = find(b);
    if (ra != rb) parent[ra] = rb;
  }

  final posMap = {for (final p in penguins) if (!p.inIgloo) p.pos: p.id};
  for (final p in penguins) {
    if (p.inIgloo) continue;
    for (final d in const [
      (0, -1),
      (0, 1),
      (-1, 0),
      (1, 0),
    ]) {
      final np = p.pos.translate(d.$1, d.$2);
      final nid = posMap[np];
      if (nid != null) union(p.id, nid);
    }
  }

  // Clump ID = root of union-find tree (smallest id in group)
  return penguins.map((p) {
    if (p.inIgloo) return p.copyWith(clumpId: -1);
    final root = find(p.id);
    return p.copyWith(clumpId: root);
  }).toList();
}

/// Allowed directions for a selection (intersection of all members' dirs).
/// Returns empty set if dead clump.
Set<Direction> allowedDirections(List<Penguin> group) {
  if (group.isEmpty) return {};
  Set<Direction> result = Set.of(kPenguinDefs[group.first.color]!.allowedDirs);
  for (final p in group.skip(1)) {
    result = result.intersection(kPenguinDefs[p.color]!.allowedDirs);
  }
  return result;
}

bool isDeadClump(List<Penguin> group) => allowedDirections(group).isEmpty;

/// The clump move kind: if solo, use the penguin's move kind.
/// If in a clump, always walk (special moves don't apply to groups).
MoveKind clumpMoveKind(List<Penguin> group) {
  if (group.length == 1) return kPenguinDefs[group.first.color]!.moveKind;
  return MoveKind.walk;
}
