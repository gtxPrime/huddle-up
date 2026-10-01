// lib/ui/game_notifier.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_state.dart';
import '../core/rules.dart';
import '../core/penguin_types.dart';
import '../core/level_data.dart';
import '../services/game_storage.dart';

enum GamePhase { playing, won, lost }

class GameViewModel {
  final GameState state;
  final GamePhase phase;
  final FailReason? lastFail;
  final int par;
  final List<GameState> history;
  final int lives;
  final int maxLives;
  final int timeLeft;
  final int initialTime;
  final String? dopamineComboToast;

  const GameViewModel({
    required this.state,
    required this.phase,
    this.lastFail,
    required this.par,
    required this.history,
    this.lives = 3,
    this.maxLives = 3,
    required this.timeLeft,
    required this.initialTime,
    this.dopamineComboToast,
  });

  GameViewModel copyWith({
    GameState? state,
    GamePhase? phase,
    FailReason? lastFail,
    int? par,
    List<GameState>? history,
    int? lives,
    int? timeLeft,
    String? dopamineComboToast,
    bool clearComboToast = false,
  }) =>
      GameViewModel(
        state: state ?? this.state,
        phase: phase ?? this.phase,
        lastFail: lastFail,
        par: par ?? this.par,
        history: history ?? this.history,
        lives: lives ?? this.lives,
        maxLives: maxLives,
        timeLeft: timeLeft ?? this.timeLeft,
        initialTime: initialTime,
        dopamineComboToast: clearComboToast
            ? null
            : (dopamineComboToast ?? this.dopamineComboToast),
      );
}

class GameNotifier extends StateNotifier<GameViewModel?> {
  GameNotifier() : super(null);

  void loadLevel(LevelData level) {
    // Generous but challenging timer: ~par * 8 + 40 seconds (min 60s)
    final timeAllocated = max(60, level.par * 8 + 40);

    final firstId = level.initialState.penguins.isNotEmpty
        ? level.initialState.penguins.first.id
        : -1;

    final userLives = GameStorage.isAdsRemoved() ? 3 : 1;

    state = GameViewModel(
      state: level.initialState.copyWith(selectedId: firstId),
      phase: GamePhase.playing,
      par: level.par,
      history: [],
      lives: userLives,
      maxLives: userLives,
      timeLeft: timeAllocated,
      initialTime: timeAllocated,
    );
  }

  void selectPenguin(int id) {
    if (state == null || state!.phase != GamePhase.playing) return;
    final target = state!.state.penguins.where((p) => p.id == id).firstOrNull;
    if (target == null || target.inIgloo) return;
    state = state!.copyWith(
      state: state!.state.copyWith(selectedId: id),
      clearComboToast: true,
    );
  }

  void move(Direction dir) {
    final vm = state;
    if (vm == null || vm.phase != GamePhase.playing) return;
    final gs = vm.state;
    final selId = gs.selectedId;
    if (selId < 0) return;

    final result = tryMove(gs, selId, dir);
    if (result is MoveSuccess) {
      final next = result.next;
      final history = [...vm.history, gs];
      final isWin = checkWin(next);

      String? comboToast;
      final prevInIgloo = gs.penguins.where((p) => p.inIgloo).length;
      final nextInIgloo = next.penguins.where((p) => p.inIgloo).length;
      if (nextInIgloo > prevInIgloo) {
        comboToast = 'SAFE IN IGLOO! 🏕️';
      } else {
        final prevClumpCount = gs.penguins.where((p) => !p.inIgloo).map((p) => p.clumpId).toSet().length;
        final nextClumpCount = next.penguins.where((p) => !p.inIgloo).map((p) => p.clumpId).toSet().length;
        if (nextClumpCount < prevClumpCount) {
          comboToast = 'HUDDLE MERGE!';
        } else if (next.fish.length < gs.fish.length) {
          comboToast = 'FISH SNACK! +50 FISH';
        }
      }

      state = vm.copyWith(
        state: next,
        phase: GamePhase.playing,
        lastFail: null,
        history: history,
        dopamineComboToast: comboToast,
        clearComboToast: comboToast == null,
      );

      if (isWin) {
        // Wait 600ms so the glide/enter-igloo animation finishes before showing victory popup
        Future.delayed(const Duration(milliseconds: 600), () {
          if (state != null && checkWin(state!.state)) {
            state = state!.copyWith(phase: GamePhase.won);
          }
        });
      } else {
        // Check if all remaining penguins ran out of moves (shortest route constraint)
        final remaining = next.penguins.where((p) => !p.inIgloo);
        if (remaining.isNotEmpty && remaining.every((p) => p.movesLeft <= 0)) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (state != null && state!.phase == GamePhase.playing && !checkWin(state!.state)) {
              final newLives = max(0, state!.lives - 1);
              state = state!.copyWith(
                lastFail: FailReason.noLegalMove,
                lives: newLives,
                phase: newLives <= 0 ? GamePhase.lost : GamePhase.playing,
              );
            }
          });
        }
      }
    } else if (result is MoveFail) {
      final isFatal = result.reason == FailReason.waterDeath ||
          result.reason == FailReason.holeDeath;

      if (isFatal) {
        final newLives = max(0, vm.lives - 1);
        final newPhase = newLives <= 0 ? GamePhase.lost : GamePhase.playing;
        state = vm.copyWith(
          lastFail: result.reason,
          lives: newLives,
          phase: newPhase,
          clearComboToast: true,
        );
      } else {
        state = vm.copyWith(
          lastFail: result.reason,
          clearComboToast: true,
        );
      }
    }
  }

  void tickTimer() {
    final vm = state;
    if (vm == null || vm.phase != GamePhase.playing) return;
    if (vm.timeLeft <= 1) {
      state = vm.copyWith(
        timeLeft: 0,
        phase: GamePhase.lost,
        lastFail: FailReason.noLegalMove,
      );
    } else {
      state = vm.copyWith(timeLeft: vm.timeLeft - 1);
    }
  }

  void restoreLives() {
    final vm = state;
    if (vm == null) return;
    final userLives = GameStorage.isAdsRemoved() ? 3 : 1;
    state = vm.copyWith(
      lives: userLives,
      phase: GamePhase.playing,
      lastFail: null,
    );
  }

  void addBonusTime(int seconds) {
    final vm = state;
    if (vm == null) return;
    state = vm.copyWith(
      timeLeft: vm.timeLeft + seconds,
      phase: GamePhase.playing,
      lastFail: null,
    );
  }

  void rewind() {
    final vm = state;
    if (vm == null || vm.phase != GamePhase.playing) return;
    if (vm.history.isEmpty) return;
    if (vm.state.rewindsLeft <= 0) return;

    final prev = vm.history.last;
    final history = vm.history.sublist(0, vm.history.length - 1);
    final rewound = prev.copyWith(
      rewindsLeft: vm.state.rewindsLeft - 1,
      selectedId: vm.state.selectedId,
    );
    state = vm.copyWith(
      state: rewound,
      history: history,
      lastFail: null,
    );
  }

  void restart(LevelData level) => loadLevel(level);
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameViewModel?>((ref) => GameNotifier());
