// lib/core/clumps.dart
import 'game_state.dart';
import 'penguin_types.dart';

/// Returns the set containing only [startId] since penguins move individually.
Set<int> clumpMembers(List<Penguin> penguins, int startId) {
  return {startId};
}

/// Each penguin moves individually and maintains its own clumpId = p.id (or -1 in igloo).
/// Penguins never merge into joint clumps or move together when adjacent.
List<Penguin> rebuildClumps(List<Penguin> penguins) {
  return penguins.map((p) {
    if (p.inIgloo) return p.copyWith(clumpId: -1);
    return p.copyWith(clumpId: p.id);
  }).toList();
}

/// Allowed directions for a penguin (individual movement).
Set<Direction> allowedDirections(List<Penguin> group) {
  if (group.isEmpty) return {};
  return Set.of(kPenguinDefs[group.first.color]!.allowedDirs);
}

bool isDeadClump(List<Penguin> group) => false;

/// The penguin's individual move kind.
MoveKind clumpMoveKind(List<Penguin> group) {
  if (group.isEmpty) return MoveKind.walk;
  return kPenguinDefs[group.first.color]!.moveKind;
}
