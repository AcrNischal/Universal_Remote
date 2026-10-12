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
    final labelAttr = xmlElement.getAttribute('label') ?? xmlElement.getAttribute('alt') ?? 'Button';
    final altAttr = xmlElement.getAttribute('alt');
    
    // Clean label
    String displayLabel = labelAttr;
    if (labelAttr.startsWith('&') || labelAttr.length > 15) {
      displayLabel = altAttr ?? 'Button';
    }
    if (displayLabel.startsWith('&')) {
      displayLabel = 'Btn';
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
    } else if (lower.contains('up') || lower == '▲') {
      type = 'dpad_up';
    } else if (lower.contains('down') || lower == '▼') {
      type = 'dpad_down';
    } else if (lower.contains('left') || lower == '◄') {
      type = 'dpad_left';
    } else if (lower.contains('right') || lower == '►') {
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
