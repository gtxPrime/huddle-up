// lib/core/level_data.dart
import 'game_state.dart';

class LevelData {
  final String id;
  final int world;
  final int levelInWorld;
  final int par;
  final GameState initialState;
  final List<Map<String, dynamic>> solution; // [{penguin:id, dir:'up'}, ...]
  final String? hint;

  const LevelData({
    required this.id,
    required this.world,
    required this.levelInWorld,
    required this.par,
    required this.initialState,
    required this.solution,
    this.hint,
  });

  factory LevelData.fromJson(Map<String, dynamic> j) {
    return LevelData(
      id: j['id'] as String,
      world: j['world'] as int,
      levelInWorld: j['level'] as int,
      par: j['par'] as int,
      initialState: GameState.fromJson(j),
      solution: (j['solution'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      hint: j['hint'] as String?,
    );
  }
}
