import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_ir_service.dart';

enum TransmissionMode { hardware, audioAux }

class TransmissionSettings {
  static ValueNotifier<TransmissionMode> mode = ValueNotifier(TransmissionMode.hardware);
}

class IrBlasterService {
  static const MethodChannel _channel = MethodChannel('com.universalremote.ir/blaster');

  static Future<bool> hasIrEmitter() async {
    if (TransmissionSettings.mode.value == TransmissionMode.audioAux) {
      return true;
    }
    try {
      final bool result = await _channel.invokeMethod('hasIrEmitter');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> transmitHex(String hexCode, {int frequency = 38000}) async {
    if (TransmissionSettings.mode.value == TransmissionMode.audioAux) {
      await AudioIrService.playIrAudioTone(hexCode);
      return true;
    }

    try {
      final pattern = _hexToNecPattern(hexCode);
      final bool result = await _channel.invokeMethod('transmit', {
        'frequency': frequency,
        'pattern': pattern,
      });
      return result;
    } on PlatformException catch (e) {
      print('Hardware IR failed, falling back to audio aux: ${e.message}');
      await AudioIrService.playIrAudioTone(hexCode);
      return true;
    }
  }

  static List<int> _hexToNecPattern(String hexStr) {
    String cleanHex = hexStr.trim();
    if (cleanHex.toLowerCase().startsWith('0x')) {
      cleanHex = cleanHex.substring(2);
    }

    int? code = int.tryParse(cleanHex, radix: 16);
    if (code == null) {
      return [9000, 4500, 560, 560, 560, 1690, 560, 560];
    }

    List<int> pattern = [];
    pattern.add(9000);
    pattern.add(4500);

    for (int i = 31; i >= 0; i--) {
      bool bit = ((code >> i) & 1) == 1;
      pattern.add(560);
      if (bit) {
        pattern.add(1690);
      } else {
        pattern.add(560);
      }
    }

    pattern.add(560);
    return pattern;
  }
}
