// ignore_for_file: avoid_print
// tool/generate_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  print('Generating audio assets...');

  // 1. UI Tap (25ms crisp pop)
  _writeWav('assets/audio/tap.wav', _generateTap());

  // 2. Penguin Move (50ms snow step)
  _writeWav('assets/audio/move.wav', _generateMove());

  // 3. Clump Merge (180ms warm chime pop)
  _writeWav('assets/audio/clump.wav', _generateClump());

  // 4. Star Ding (350ms crystal bell)
  _writeWav('assets/audio/star.wav', _generateStar());

  // 5. Level Complete Dopamine Fanfare (1.8s triumphant fanfare)
  _writeWav('assets/audio/win.wav', _generateWinFanfare());

  // 6. Hazard Fail (300ms splash/descend)
  _writeWav('assets/audio/fail.wav', _generateFail());

  // 7. Rewarded Rescue Magic Sparkle (750ms ascending angelical chime)
  _writeWav('assets/audio/rescue.wav', _generateRescue());

  // 8. Rewarded Jackpot Coin Cascade (800ms dopamine coin shower)
  _writeWav('assets/audio/reward.wav', _generateReward());

  // 9. Combo / Huddle Merge Punch (300ms punchy synth fanfare)
  _writeWav('assets/audio/combo.wav', _generateCombo());

  // 10. Low Time Heartbeat Tension (600ms double pulse)
  _writeWav('assets/audio/heartbeat.wav', _generateHeartbeat());

  // 11. Ambient Antarctic Chill Music Loop (12s seamless ambient synth pad)
  _writeWav('assets/audio/music_bg.wav', _generateAmbientMusic());

  print('All audio assets generated successfully!');
}

List<int> _generateTap() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.03).round();
  final data = Int16List(samples);
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 150);
    final freq = 900.0 - (t * 10000).clamp(0, 700);
    final wave = sin(2 * pi * freq * t);
    data[i] = (wave * env * 24000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateMove() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.06).round();
  final data = Int16List(samples);
  final rng = Random(42);
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = sin(pi * (i / samples));
    final noise = (rng.nextDouble() * 2 - 1) * 0.4;
    final thud = sin(2 * pi * 140 * t) * 0.6;
    data[i] = ((noise + thud) * env * 22000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateClump() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.22).round();
  final data = Int16List(samples);
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 14);
    final f1 = 440.0 + sin(t * 30) * 80 + t * 400;
    final f2 = 880.0 + t * 200;
    final wave = sin(2 * pi * f1 * t) * 0.7 + sin(2 * pi * f2 * t) * 0.3;
    data[i] = (wave * env * 26000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateStar() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.45).round();
  final data = Int16List(samples);
  const fundamental = 1318.51; // E6
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 9);
    final wave = sin(2 * pi * fundamental * t) * 0.6 +
        sin(2 * pi * fundamental * 2 * t) * 0.25 +
        sin(2 * pi * fundamental * 3 * t) * 0.15;
    data[i] = (wave * env * 28000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateWinFanfare() {
  const sampleRate = 22050;
  final samples = (sampleRate * 2.0).round();
  final data = Int16List(samples);

  // Arpeggio: C5 (523.25), E5 (659.25), G5 (783.99), C6 (1046.50)
  final notes = [
    (0.00, 0.25, 523.25),
    (0.18, 0.40, 659.25),
    (0.36, 0.60, 783.99),
    (0.55, 1.40, 1046.50),
    (0.55, 1.40, 1318.51), // Harmony high E
    (0.55, 1.40, 1567.98), // Harmony high G
  ];

  for (final (start, dur, freq) in notes) {
    final startIdx = (start * sampleRate).round();
    final noteLen = (dur * sampleRate).round();
    for (int i = 0; i < noteLen && (startIdx + i) < samples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * (dur > 0.8 ? 2.5 : 8.0));
      final wave = sin(2 * pi * freq * t) * 0.6 +
          sin(2 * pi * (freq * 2) * t) * 0.25 +
          sin(2 * pi * (freq * 3) * t) * 0.1;
      final idx = startIdx + i;
      final cur = data[idx];
      data[idx] = (cur + wave * env * 11000).clamp(-32767, 32767).toInt();
    }
  }
  return _createWav(data, sampleRate);
}

List<int> _generateFail() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.35).round();
  final data = Int16List(samples);
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 8);
    final freq = 360.0 - t * 450.0;
    final wave = sin(2 * pi * max(50.0, freq) * t);
    data[i] = (wave * env * 22000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateRescue() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.85).round();
  final data = Int16List(samples);
  // Ascending magical arpeggio: E5, G#5, B5, E6
  final notes = [
    (0.00, 0.22, 659.25),
    (0.12, 0.25, 830.61),
    (0.24, 0.30, 987.77),
    (0.36, 0.48, 1318.51),
    (0.36, 0.48, 1661.22), // high sparkle
  ];
  for (final (start, dur, freq) in notes) {
    final startIdx = (start * sampleRate).round();
    final noteLen = (dur * sampleRate).round();
    for (int i = 0; i < noteLen && (startIdx + i) < samples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 6.5);
      final shimmer = sin(2 * pi * 8 * t) * 0.15;
      final wave = sin(2 * pi * (freq + shimmer * freq) * t) * 0.7 +
          sin(2 * pi * (freq * 2) * t) * 0.3;
      final idx = startIdx + i;
      data[idx] = (data[idx] + wave * env * 14000).clamp(-32767, 32767).toInt();
    }
  }
  return _createWav(data, sampleRate);
}

List<int> _generateReward() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.80).round();
  final data = Int16List(samples);
  // Rapid cascading coin burst: 6 crystal dings
  final freqs = [987.77, 1174.66, 1318.51, 1567.98, 1760.00, 2093.00];
  for (int step = 0; step < freqs.length; step++) {
    final start = step * 0.08;
    const dur = 0.28;
    final freq = freqs[step];
    final startIdx = (start * sampleRate).round();
    final noteLen = (dur * sampleRate).round();
    for (int i = 0; i < noteLen && (startIdx + i) < samples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 12.0);
      final wave = sin(2 * pi * freq * t) * 0.75 + sin(2 * pi * freq * 2 * t) * 0.25;
      final idx = startIdx + i;
      data[idx] = (data[idx] + wave * env * 12000).clamp(-32767, 32767).toInt();
    }
  }
  return _createWav(data, sampleRate);
}

List<int> _generateCombo() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.38).round();
  final data = Int16List(samples);
  // Punchy synth fanfare: F4, A4, C5 + bright octave
  final freqs = [349.23, 440.00, 523.25, 698.46];
  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 7.0);
    double sum = 0.0;
    for (final f in freqs) {
      sum += sin(2 * pi * f * t) * 0.25;
    }
    // Punch transient
    final kick = sin(2 * pi * (180.0 - t * 300).clamp(40.0, 180.0) * t) * exp(-t * 25);
    data[i] = ((sum + kick * 0.4) * env * 24000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

List<int> _generateHeartbeat() {
  const sampleRate = 22050;
  final samples = (sampleRate * 0.60).round();
  final data = Int16List(samples);
  // Lub-dub: pulse 1 at t=0.0s, pulse 2 at t=0.18s
  final pulses = [(0.00, 65.0), (0.18, 75.0)];
  for (final (start, freq) in pulses) {
    final startIdx = (start * sampleRate).round();
    final len = (sampleRate * 0.15).round();
    for (int i = 0; i < len && (startIdx + i) < samples; i++) {
      final t = i / sampleRate;
      final env = sin(pi * (i / len));
      final wave = sin(2 * pi * freq * t) * 0.85 + sin(2 * pi * (freq * 0.5) * t) * 0.15;
      final idx = startIdx + i;
      data[idx] = (data[idx] + wave * env * 22000).clamp(-32767, 32767).toInt();
    }
  }
  return _createWav(data, sampleRate);
}


List<int> _generateAmbientMusic() {
  const sampleRate = 22050;
  const duration = 12.0; // 12-second loop
  final samples = (sampleRate * duration).round();
  final data = Int16List(samples);

  // 4 Chords over 12 seconds: 3 seconds per chord
  // 1. Cmaj7: C4(261.63), E4(329.63), G4(392.00), B4(493.88)
  // 2. Am7:   A3(220.00), C4(261.63), E4(329.63), G4(392.00)
  // 3. Fmaj7: F3(174.61), A3(220.00), C4(261.63), E4(329.63)
  // 4. Gsus4: G3(196.00), C4(261.63), D4(293.66), G4(392.00)
  final chords = [
    [261.63, 329.63, 392.00, 493.88],
    [220.00, 261.63, 329.63, 392.00],
    [174.61, 220.00, 261.63, 329.63],
    [196.00, 261.63, 293.66, 392.00],
  ];

  for (int i = 0; i < samples; i++) {
    final t = i / sampleRate;
    final chordIdx = (t / 3.0).floor() % 4;
    final chordT = t % 3.0;
    // Crossfade envelope for smooth breathing pad
    final env = sin(pi * (chordT / 3.0)).clamp(0.0, 1.0);

    double sum = 0.0;
    final chordFreqs = chords[chordIdx];
    for (int k = 0; k < chordFreqs.length; k++) {
      final f = chordFreqs[k];
      // Warm detuned sine pad with soft vibrato
      final vibrato = sin(2 * pi * 1.5 * t + k) * 1.2;
      sum += sin(2 * pi * (f + vibrato) * t) * 0.22;
      // High subtle sparkle overtone
      if (k == 3) {
        sum += sin(2 * pi * (f * 2.0) * t) * 0.08 * sin(t * 3.0);
      }
    }

    data[i] = (sum * env * 14000).clamp(-32767, 32767).toInt();
  }
  return _createWav(data, sampleRate);
}

void _writeWav(String path, List<int> bytes) {
  File(path).writeAsBytesSync(bytes);
}

List<int> _createWav(Int16List pcmData, int sampleRate) {
  final numSamples = pcmData.length;
  final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
  final subChunk2Size = numSamples * 2;
  final chunkSize = 36 + subChunk2Size;

  final b = BytesBuilder();
  // RIFF header
  b.add([0x52, 0x49, 0x46, 0x46]); // "RIFF"
  b.add(_int32(chunkSize));
  b.add([0x57, 0x41, 0x56, 0x45]); // "WAVE"

  // fmt subchunk
  b.add([0x66, 0x6D, 0x74, 0x20]); // "fmt "
  b.add(_int32(16)); // Subchunk1Size = 16
  b.add(_int16(1)); // AudioFormat = 1 (PCM)
  b.add(_int16(1)); // NumChannels = 1 (Mono)
  b.add(_int32(sampleRate)); // SampleRate
  b.add(_int32(byteRate)); // ByteRate
  b.add(_int16(2)); // BlockAlign = 2
  b.add(_int16(16)); // BitsPerSample = 16

  // data subchunk
  b.add([0x64, 0x61, 0x74, 0x61]); // "data"
  b.add(_int32(subChunk2Size));

  // Samples (Little Endian)
  final byteData = ByteData(subChunk2Size);
  for (int i = 0; i < numSamples; i++) {
    byteData.setInt16(i * 2, pcmData[i], Endian.little);
  }
  b.add(byteData.buffer.asUint8List());

  return b.toBytes();
}

List<int> _int16(int val) {
  return [val & 0xFF, (val >> 8) & 0xFF];
}

List<int> _int32(int val) {
  return [
    val & 0xFF,
    (val >> 8) & 0xFF,
    (val >> 16) & 0xFF,
    (val >> 24) & 0xFF,
  ];
}
