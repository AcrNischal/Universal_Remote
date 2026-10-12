import 'package:flutter/services.dart';

class IrBlasterService {
  static const MethodChannel _channel = MethodChannel('com.universalremote.ir/blaster');

  static Future<bool> hasIrEmitter() async {
    try {
      final bool result = await _channel.invokeMethod('hasIrEmitter');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> transmitHex(String hexCode, {int frequency = 38000}) async {
    try {
      final pattern = _hexToNecPattern(hexCode);
      final bool result = await _channel.invokeMethod('transmit', {
        'frequency': frequency,
        'pattern': pattern,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to transmit IR: ${e.message}');
      throw Exception(e.message ?? 'Device has no IR emitter or permission missing');
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
    // NEC Header
    pattern.add(9000);
    pattern.add(4500);

    // 32 bits
    for (int i = 31; i >= 0; i--) {
      bool bit = ((valAt(code, i)) & 1) == 1;
      pattern.add(560);
      if (bit) {
        pattern.add(1690);
      } else {
        pattern.add(560);
      }
    }

    // Stop bit
    pattern.add(560);
    return pattern;
  }

  static int valAt(int code, int i) {
    return (code >> i) & 1;
  }
}
