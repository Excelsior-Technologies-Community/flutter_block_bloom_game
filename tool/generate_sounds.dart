import 'dart:io';
import 'dart:math';

void main() {
  final soundsDir = Directory('assets/sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  File('assets/sounds/click.wav').writeAsBytesSync(generateClickSound());
  File('assets/sounds/place.wav').writeAsBytesSync(generatePlaceSound());
  File('assets/sounds/clear.wav').writeAsBytesSync(generateClearSound());
  File('assets/sounds/game_over.wav').writeAsBytesSync(generateGameOverSound());
  File('assets/sounds/bgm.wav').writeAsBytesSync(generateBgmMusic());

  print('Sound files generated successfully in assets/sounds/');
}

// 1. CLICK SOUND (0.035s pleasant soft warm organic tap)
List<int> generateClickSound() {
  const sampleRate = 44100;
  const duration = 0.035;
  final numSamples = (sampleRate * duration).toInt();
  final left = <double>[];
  final right = <double>[];

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final attack = (t < 0.002) ? (t / 0.002) : 1.0;
    final env = attack * exp(-t * 140.0); // Fast dampening envelope for organic tap
    final freq = 420.0 - (t / duration) * 220.0; // Warm 420Hz -> 200Hz drop

    final s1 = sin(2 * pi * freq * t);
    final s2 = sin(2 * pi * (freq * 2.0) * t) * 0.15; // Gentle warm harmonic
    final sample = (s1 + s2) * env * 0.35; // Pleasant, non-jarring volume

    left.add(sample);
    right.add(sample);
  }
  return build16BitStereoWav(left, right, sampleRate: sampleRate);
}

// 2. PLACE BLOCK SOUND (0.10s woody placement drop)
List<int> generatePlaceSound() {
  const sampleRate = 44100;
  const duration = 0.10;
  final numSamples = (sampleRate * duration).toInt();
  final left = <double>[];
  final right = <double>[];

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 40.0);
    // 160Hz fundamental + 320Hz warm harmonic
    final s1 = sin(2 * pi * 160.0 * t);
    final s2 = sin(2 * pi * 320.0 * t) * 0.4;
    final s3 = sin(2 * pi * 520.0 * t) * 0.15;
    final sample = (s1 + s2 + s3) * env * 0.75;
    left.add(sample * 0.9);
    right.add(sample * 1.1);
  }
  return build16BitStereoWav(left, right, sampleRate: sampleRate);
}

// 3. LINE CLEAR SOUND (0.40s magical ascending chime)
List<int> generateClearSound() {
  const sampleRate = 44100;
  const duration = 0.40;
  final numSamples = (sampleRate * duration).toInt();
  final left = <double>[];
  final right = <double>[];

  final notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6 major chord

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 6.0);
    
    double sample = 0.0;
    for (int n = 0; n < notes.length; n++) {
      final noteStartTime = n * 0.07;
      if (t >= noteStartTime) {
        final dt = t - noteStartTime;
        final noteEnv = exp(-dt * 12.0);
        sample += sin(2 * pi * notes[n] * dt) * noteEnv * 0.3;
      }
    }
    sample *= env;
    left.add(sample);
    right.add(sample * 0.95);
  }
  return build16BitStereoWav(left, right, sampleRate: sampleRate);
}

// 4. GAME OVER SOUND (0.60s gentle descending chord)
List<int> generateGameOverSound() {
  const sampleRate = 44100;
  const duration = 0.60;
  final numSamples = (sampleRate * duration).toInt();
  final left = <double>[];
  final right = <double>[];

  final notes = [440.0, 349.23, 293.66]; // A4 -> F4 -> D4

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 4.0);

    double sample = 0.0;
    for (int n = 0; n < notes.length; n++) {
      final noteStartTime = n * 0.15;
      if (t >= noteStartTime) {
        final dt = t - noteStartTime;
        final noteEnv = exp(-dt * 5.0);
        sample += sin(2 * pi * notes[n] * dt) * noteEnv * 0.35;
      }
    }
    sample *= env;
    left.add(sample);
    right.add(sample);
  }
  return build16BitStereoWav(left, right, sampleRate: sampleRate);
}

// 5. RELAXING BACKGROUND MUSIC (BGM) LOOP (24.0s seamless ambient pentatonic garden symphony)
List<int> generateBgmMusic() {
  const sampleRate = 44100;
  const duration = 24.0; // 24-second lush background music
  final numSamples = (sampleRate * duration).toInt();
  final left = <double>[];
  final right = <double>[];

  // Peaceful 32-note 4-phrase melody sequence in C Major / A Minor Pentatonic:
  // Phrase 1 (0-6s): Gentle opening garden motif
  // Phrase 2 (6-12s): Warm rising floral melody
  // Phrase 3 (12-18s): Deep soothing ambient reflection
  // Phrase 4 (18-24s): Harmonic resolution back to home key
  final melodyNotes = [
    // Phrase 1 (0-6s)
    261.63, 329.63, 392.00, 523.25, 440.00, 392.00, 329.63, 261.63,
    // Phrase 2 (6-12s)
    349.23, 440.00, 523.25, 659.25, 587.33, 523.25, 440.00, 392.00,
    // Phrase 3 (12-18s)
    220.00, 329.63, 440.00, 523.25, 659.25, 783.99, 659.25, 523.25,
    // Phrase 4 (18-24s)
    196.00, 293.66, 392.00, 493.88, 523.25, 659.25, 523.25, 392.00,
  ];

  const noteDuration = duration / 32; // 0.75s per note phrase

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final noteIdx = (t / noteDuration).floor() % melodyNotes.length;
    final noteTime = t % noteDuration;

    final freq = melodyNotes[noteIdx];

    // Soft organic celesta/bell synth envelope (smooth attack + warm decay)
    final attack = (noteTime < 0.015) ? (noteTime / 0.015) : 1.0;
    final env = attack * exp(-noteTime * 2.0);

    // Warm multi-harmonic tone (Fundamental + 2nd harmonic + soft 3rd harmonic)
    final f1 = sin(2 * pi * freq * t);
    final f2 = sin(2 * pi * (freq * 2.0) * t) * 0.22;
    final f3 = sin(2 * pi * (freq * 0.5) * t) * 0.30; // Warm sub-octave depth

    final leadSample = (f1 + f2 + f3) * env * 0.20;

    // Ambient lush pad backdrop (Chords shifting slowly: Cmaj -> Fmaj -> Am -> Gmaj)
    final phraseIdx = (t / 6.0).floor() % 4;
    double padFreq1 = 130.81; // C3
    double padFreq2 = 196.00; // G3
    if (phraseIdx == 1) {
      padFreq1 = 174.61; // F3
      padFreq2 = 220.00; // A3
    } else if (phraseIdx == 2) {
      padFreq1 = 110.00; // A2
      padFreq2 = 164.81; // E3
    } else if (phraseIdx == 3) {
      padFreq1 = 146.83; // D3
      padFreq2 = 196.00; // G3
    }

    // Gentle 0.15Hz LFO ambient swell
    final lfo = 0.85 + 0.15 * sin(2 * pi * 0.15 * t);
    final padSample = (sin(2 * pi * padFreq1 * t) * 0.06 + sin(2 * pi * padFreq2 * t) * 0.04) * lfo;

    final totalSample = leadSample + padSample;

    // Gentle dynamic stereo panning (smooth movement across left/right speakers)
    final pan = 0.85 + 0.30 * sin(2 * pi * (t / 4.0));
    left.add((totalSample * pan * 0.65).clamp(-1.0, 1.0));
    right.add((totalSample * (2.0 - pan) * 0.65).clamp(-1.0, 1.0));
  }

  // Crossfade first and last 0.3s to guarantee 100% click-free seamless loop
  final fadeSamples = (sampleRate * 0.30).toInt();
  for (int i = 0; i < fadeSamples; i++) {
    final alpha = i / fadeSamples;
    left[i] = left[i] * alpha + left[numSamples - fadeSamples + i] * (1.0 - alpha);
    right[i] = right[i] * alpha + right[numSamples - fadeSamples + i] * (1.0 - alpha);
  }

  return build16BitStereoWav(left, right, sampleRate: sampleRate);
}

// WAV Header Builder
List<int> build16BitStereoWav(List<double> leftSamples, List<double> rightSamples, {int sampleRate = 44100}) {
  final numFrames = leftSamples.length;
  final numChannels = 2;
  final bytesPerSample = 2; // 16-bit
  final subChunk2Size = numFrames * numChannels * bytesPerSample;
  final fileSize = 36 + subChunk2Size;

  final List<int> bytes = [];

  // RIFF header
  bytes.addAll('RIFF'.codeUnits);
  bytes.addAll([
    fileSize & 0xFF,
    (fileSize >> 8) & 0xFF,
    (fileSize >> 16) & 0xFF,
    (fileSize >> 24) & 0xFF,
  ]);
  bytes.addAll('WAVE'.codeUnits);

  // fmt subchunk
  bytes.addAll('fmt '.codeUnits);
  bytes.addAll([16, 0, 0, 0]); // Subchunk1Size = 16
  bytes.addAll([1, 0]); // AudioFormat = 1 (PCM)
  bytes.addAll([numChannels, 0]); // NumChannels = 2
  
  // SampleRate = 44100
  bytes.addAll([
    sampleRate & 0xFF,
    (sampleRate >> 8) & 0xFF,
    (sampleRate >> 16) & 0xFF,
    (sampleRate >> 24) & 0xFF,
  ]);

  // ByteRate = SampleRate * NumChannels * BitsPerSample / 8 = 176400
  final byteRate = sampleRate * numChannels * bytesPerSample;
  bytes.addAll([
    byteRate & 0xFF,
    (byteRate >> 8) & 0xFF,
    (byteRate >> 16) & 0xFF,
    (byteRate >> 24) & 0xFF,
  ]);

  // BlockAlign = NumChannels * BitsPerSample / 8 = 4
  final blockAlign = numChannels * bytesPerSample;
  bytes.addAll([blockAlign, 0]);

  // BitsPerSample = 16
  bytes.addAll([16, 0]);

  // data subchunk
  bytes.addAll('data'.codeUnits);
  bytes.addAll([
    subChunk2Size & 0xFF,
    (subChunk2Size >> 8) & 0xFF,
    (subChunk2Size >> 16) & 0xFF,
    (subChunk2Size >> 24) & 0xFF,
  ]);

  // Sample data (16-bit signed Little Endian)
  for (int i = 0; i < numFrames; i++) {
    final lVal = (leftSamples[i].clamp(-1.0, 1.0) * 32767).toInt();
    final rVal = (rightSamples[i].clamp(-1.0, 1.0) * 32767).toInt();

    bytes.add(lVal & 0xFF);
    bytes.add((lVal >> 8) & 0xFF);
    bytes.add(rVal & 0xFF);
    bytes.add((rVal >> 8) & 0xFF);
  }

  return bytes;
}
