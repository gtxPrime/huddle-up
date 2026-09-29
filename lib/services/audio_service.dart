// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'game_storage.dart';

class AudioService {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  
  // Dedicated low-latency pools for rapid-fire sound effects
  static final List<AudioPlayer> _tapPlayers = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  static int _tapIdx = 0;

  static final List<AudioPlayer> _movePlayers = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  static int _moveIdx = 0;

  static final List<AudioPlayer> _sfxPool = [
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  static int _sfxIdx = 0;
  static bool _musicStarted = false;

  static Future<void> init() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.35);

      // Pre-load tap players
      for (final p in _tapPlayers) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setVolume(0.65);
        await p.setSource(AssetSource('audio/tap.wav'));
      }

      // Pre-load move players
      for (final p in _movePlayers) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setVolume(0.75);
        await p.setSource(AssetSource('audio/move.wav'));
      }

      // General SFX pool
      for (final p in _sfxPool) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setVolume(0.85);
      }
    } catch (e) {
      debugPrint('Audio initialization note: $e');
    }
  }

  // ── Background Music ───────────────────────────────────────────────────────

  static Future<void> startMusic() async {
    if (!GameStorage.isMusicEnabled()) return;
    if (_musicStarted) return;
    try {
      await _musicPlayer.play(AssetSource('audio/music_bg.wav'));
      _musicStarted = true;
    } catch (e) {
      debugPrint('Music play note: $e');
    }
  }

  static Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _musicStarted = false;
    } catch (e) {
      debugPrint('Music stop note: $e');
    }
  }

  static Future<void> onMusicSettingChanged(bool enabled) async {
    if (enabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  // ── Sound Effects ──────────────────────────────────────────────────────────

  static void playTap() {
    if (!GameStorage.isSoundEnabled()) return;
    try {
      final p = _tapPlayers[_tapIdx];
      _tapIdx = (_tapIdx + 1) % _tapPlayers.length;
      p.stop();
      p.resume();
    } catch (_) {
      // Fallback
      _playSfx('audio/tap.wav', volume: 0.65);
    }
  }

  static void playMove() {
    if (!GameStorage.isSoundEnabled()) return;
    try {
      final p = _movePlayers[_moveIdx];
      _moveIdx = (_moveIdx + 1) % _movePlayers.length;
      p.stop();
      p.resume();
    } catch (_) {
      // Fallback
      _playSfx('audio/move.wav', volume: 0.75);
    }
  }

  static void playClump() {
    _playSfx('audio/clump.wav', volume: 0.85);
  }

  static void playStar() {
    _playSfx('audio/star.wav', volume: 0.9);
  }

  static void playWin() {
    _playSfx('audio/win.wav', volume: 1.0);
  }

  static void playFail() {
    _playSfx('audio/fail.wav', volume: 0.8);
  }

  static void playRescue() {
    _playSfx('audio/rescue.wav', volume: 0.95);
  }

  static void playReward() {
    _playSfx('audio/reward.wav', volume: 0.95);
  }

  static void playCombo() {
    _playSfx('audio/combo.wav', volume: 0.85);
  }

  static void playHeartbeat() {
    _playSfx('audio/heartbeat.wav', volume: 0.7);
  }

  static void _playSfx(String path, {double volume = 0.8}) {
    if (!GameStorage.isSoundEnabled()) return;
    try {
      final player = _sfxPool[_sfxIdx];
      _sfxIdx = (_sfxIdx + 1) % _sfxPool.length;
      player.setVolume(volume);
      player.play(AssetSource(path), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('SFX play note ($path): $e');
    }
  }
}
