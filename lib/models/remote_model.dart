class RemoteButton {
  final String label;
  final String code;
  final String type;

  RemoteButton({
    required this.label,
    required this.code,
    required this.type,
  });

  factory RemoteButton.fromXml(dynamic xmlElement) {
    final labelAttr = xmlElement.getAttribute('label') ?? 'Button';
    final altAttr = xmlElement.getAttribute('alt');

    String displayLabel = labelAttr.trim();

    // Helper to check if label contains unprintable icon font / private use area characters
    bool isSymbolChar(String text) {
      return text.runes.any((r) => (r >= 0xE000 && r <= 0xF8FF) || (r >= 0xF0000 && r <= 0xFFFFF) || r < 32);
    }

    if (isSymbolChar(displayLabel)) {
      if (altAttr != null && altAttr.trim().isNotEmpty) {
        displayLabel = altAttr.trim();
      } else {
        final runes = displayLabel.runes.toList();
        if (runes.contains(0xf011)) {
          displayLabel = 'Power';
        } else if (runes.contains(0xf0d8)) {
          displayLabel = 'Up';
        } else if (runes.contains(0xf0d7)) {
          displayLabel = 'Down';
        } else if (runes.contains(0xf0d9)) {
          displayLabel = 'Left';
        } else if (runes.contains(0xf0da)) {
          displayLabel = 'Right';
        } else if (runes.contains(0xf04b)) {
          displayLabel = 'Play';
        } else if (runes.contains(0xf04a)) {
          displayLabel = 'Rew';
        } else if (runes.contains(0xf04c)) {
          displayLabel = 'Pause';
        } else if (runes.contains(0xf04d)) {
          displayLabel = 'Stop';
        } else if (runes.contains(0xf04e)) {
          displayLabel = 'Fwd';
        } else if (runes.contains(0xf111)) {
          displayLabel = 'Rec';
        } else {
          final cleaned = displayLabel.replaceAll(RegExp(r'[\uE000-\uF8FF\uF0000-\uFFFFF]'), '').trim();
          displayLabel = cleaned.isNotEmpty ? cleaned : 'Button';
        }
      }
    }

    final codeText = xmlElement.text.trim();
    final codeAttr = xmlElement.getAttribute('code') ?? '';
    final code = codeText.isNotEmpty ? codeText : codeAttr;

    // Infer button type
    String type = xmlElement.getAttribute('type') ?? 'general';
    final lower = displayLabel.toLowerCase();
    
    if (lower.contains('power') || lower == 'p' || lower.contains('on/off')) {
      type = 'power';
    } else if (lower.contains('vol') || lower == 'v+' || lower == 'v-') {
      type = lower.contains('-') ? 'vol_down' : 'vol_up';
    } else if (lower.contains('ch') || lower == 'p+' || lower == 'p-' || lower.contains('chan')) {
      type = lower.contains('-') ? 'ch_down' : 'ch_up';
    } else if (lower.contains('mute')) {
      type = 'mute';
    } else if (RegExp(r'^[0-9]$').hasMatch(displayLabel)) {
      type = 'num';
    } else if (lower.contains('up') || displayLabel == '▲' || displayLabel.contains('\uf0d8')) {
      type = 'dpad_up';
    } else if (lower.contains('down') || displayLabel == '▼' || displayLabel.contains('\uf0d7')) {
      type = 'dpad_down';
    } else if (lower.contains('left') || displayLabel == '◄' || displayLabel.contains('\uf0d9')) {
      type = 'dpad_left';
    } else if (lower.contains('right') || displayLabel == '►' || displayLabel.contains('\uf0da')) {
      type = 'dpad_right';
    } else if (lower.contains('ok') || lower.contains('enter') || lower.contains('select')) {
      type = 'dpad_center';
    }

    return RemoteButton(
      label: displayLabel,
      code: code,
      type: type,
    );
  }
}

class RemoteConfig {
  final String manufacturer;
  final String name;
  final String filePath;
  final String protocol;
  final String deviceCode;
  final List<RemoteButton> buttons;

  RemoteConfig({
    required this.manufacturer,
    required this.name,
    required this.filePath,
    required this.protocol,
    required this.deviceCode,
    required this.buttons,
  });
}

class ManufacturerGroup {
  final String manufacturer;
  final List<RemoteConfig> models;

  ManufacturerGroup({
    required this.manufacturer,
    required this.models,
  });
}
