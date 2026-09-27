// lib/data/level_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/level_data.dart';

class LevelLoader {
  static final Map<int, List<LevelData>> _cache = {};

  static Future<List<LevelData>> loadWorld(int world) async {
    if (_cache.containsKey(world)) return _cache[world]!;
    final raw = await rootBundle.loadString('assets/levels/world$world.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final levels = (json['levels'] as List<dynamic>)
        .map((e) => LevelData.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache[world] = levels;
    return levels;
  }

  static Future<LevelData?> loadLevel(int world, int levelIndex) async {
    final levels = await loadWorld(world);
    if (levelIndex < 0 || levelIndex >= levels.length) return null;
    return levels[levelIndex];
  }

  /// Total worlds available as asset files
  static const int totalWorlds = 1;
}
