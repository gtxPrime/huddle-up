// lib/gen/level_provider.dart
//
// Bridges the generator with the rest of the app.
// Runs generation in a Dart Isolate so the UI never janks.
// Daily offset: changes once per day so the same level slot
//   looks different, but is identical for everyone on the same day.

import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/level_data.dart';
import 'generator.dart';

// ── Daily offset ─────────────────────────────────────────────────────────────

int get _dailyOffset {
  final now = DateTime.now();
  // Unique integer for today: days since epoch
  return now.year * 10000 + now.month * 100 + now.day;
}

// ── Isolate message ──────────────────────────────────────────────────────────

class _GenRequest {
  final int levelNumber;
  final int dailyOffset;
  final SendPort reply;
  const _GenRequest(this.levelNumber, this.dailyOffset, this.reply);
}

void _generatorIsolate(_GenRequest req) {
  final gen = generateLevel(req.levelNumber, dailyOffset: req.dailyOffset);
  req.reply.send(gen);
}

// ── Public async API ─────────────────────────────────────────────────────────

/// Returns a [LevelData]-compatible wrapper from the generator.
Future<GeneratedLevel> generateLevelAsync(int levelNumber) async {
  final recv = ReceivePort();
  await Isolate.spawn(
    _generatorIsolate,
    _GenRequest(levelNumber, _dailyOffset, recv.sendPort),
  );
  final result = await recv.first as GeneratedLevel;
  recv.close();
  return result;
}

/// Converts [GeneratedLevel] to [LevelData] for use by the game notifier.
LevelData generatedToLevelData(GeneratedLevel gen, int levelNumber) {
  return LevelData(
    id: 'gen_$levelNumber',
    world: _worldForLevel(levelNumber),
    levelInWorld: levelNumber,
    par: gen.par,
    initialState: gen.initialState,
    solution: gen.solution
        .map((s) => {
              'penguin': s.penguinId,
              'dir': s.dir.name,
            })
        .toList(),
    hint: null,
  );
}

int _worldForLevel(int level) {
  if (level <= 50) return 1;
  if (level <= 100) return 2;
  if (level <= 150) return 3;
  if (level <= 200) return 4;
  return 5;
}

// ── Riverpod provider ────────────────────────────────────────────────────────

final generatedLevelProvider =
    FutureProvider.family<GeneratedLevel, int>((ref, levelNumber) {
  return generateLevelAsync(levelNumber);
});
