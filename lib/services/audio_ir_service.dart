import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioIrService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Generate and play audio tone / pulse burst for IR transmission via headphone jack / aux
  static Future<void> playIrAudioTone(String hexCode) async {
    try {
      final wavBytes = _generateIrWavBytes(hexCode);
      Source bytesSource = BytesSource(wavBytes);
      await _audioPlayer.play(bytesSource);
    } catch (e) {
      print('Audio IR playback error: $e');
    }
  }

  static Uint8List _generateIrWavBytes(String hexCode) {
    const int sampleRate = 44100;
    const double durationSec = 0.12; // 120ms audio burst
    final int numSamples = (sampleRate * durationSec).toInt();

    final int dataSize = numSamples * 2; // 16-bit mono = 2 bytes per sample
    final int fileSize = 36 + dataSize;

    final BytesBuilder builder = BytesBuilder();

    // RIFF header
    builder.add('RIFF'.codeUnits);
    builder.add(_intToBytes(fileSize, 4));
    builder.add('WAVE'.codeUnits);

    // fmt chunk
    builder.add('fmt '.codeUnits);
    builder.add(_intToBytes(16, 4)); // Subchunk1Size
    builder.add(_intToBytes(1, 2));  // AudioFormat (PCM)
    builder.add(_intToBytes(1, 2));  // NumChannels (Mono)
    builder.add(_intToBytes(sampleRate, 4)); // SampleRate
    builder.add(_intToBytes(sampleRate * 2, 4)); // ByteRate
    builder.add(_intToBytes(2, 2));  // BlockAlign
    builder.add(_intToBytes(16, 2)); // BitsPerSample

    // data chunk
    builder.add('data'.codeUnits);
    builder.add(_intToBytes(dataSize, 4));

    // Generate modulated audio frequency representation (14kHz tone burst representing IR pulse)
    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double envelope = (i < numSamples * 0.85) ? 1.0 : (1.0 - ((i - numSamples * 0.85) / (numSamples * 0.15)));
      double sample = math.sin(2 * math.pi * 14000 * t) * envelope * 32767;
      int sampleInt = sample.clamp(-32768, 32767).toInt();
      builder.add(_intToBytes(sampleInt, 2));
    }

    return builder.toBytes();
  }

  static Uint8List _intToBytes(int value, int length) {
    var b = ByteData(length);
    if (length == 4) {
      b.setInt32(0, value, Endian.little);
    } else if (length == 2) {
      b.setInt16(0, value, Endian.little);
    }
    return b.buffer.asUint8List();
  }
}
