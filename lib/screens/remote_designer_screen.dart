import 'dart:async';
import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import '../services/ir_blaster_service.dart';

class RemoteDesignerScreen extends StatefulWidget {
  final Function(RemoteConfig) onRemoteCreated;

  const RemoteDesignerScreen({Key? key, required this.onRemoteCreated}) : super(key: key);

  @override
  State<RemoteDesignerScreen> createState() => _RemoteDesignerScreenState();
}

class _RemoteDesignerScreenState extends State<RemoteDesignerScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'My Custom Remote');
  final TextEditingController _mfrController = TextEditingController(text: 'CUSTOM');
  final TextEditingController _protocolController = TextEditingController(text: 'NEC');
  final TextEditingController _deviceController = TextEditingController(text: '0x04');

  final List<RemoteButton> _customButtons = [];

  final TextEditingController _btnLabelController = TextEditingController();
  final TextEditingController _btnCodeController = TextEditingController();
  String _btnType = 'general';
  String _selectedNumLabel = '0';
  bool _isLedActive = false;

  void _addCustomButton() {
    final label = _btnType == 'num' ? _selectedNumLabel : _btnLabelController.text.trim();
    final code = _btnCodeController.text.trim();

    if (label.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter button label and IR hex code')),
      );
      return;
    }

    setState(() {
      _customButtons.add(RemoteButton(
        label: label,
        code: code,
        type: _btnType,
      ));
      if (_btnType != 'num') {
        _btnLabelController.clear();
      }
      _btnCodeController.clear();
      _btnType = 'general';
    });
  }

  void _saveRemote() {
    if (_customButtons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one button to your remote')),
      );
      return;
    }

    final config = RemoteConfig(
      manufacturer: _mfrController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      filePath: 'designer_${DateTime.now().millisecondsSinceEpoch}.xml',
      protocol: _protocolController.text.trim(),
      deviceCode: _deviceController.text.trim(),
      buttons: _customButtons,
    );

    widget.onRemoteCreated(config);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully created and saved "${config.name}"!')),
    );
  }

  void _showPopupPreview() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remote Test Popup'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: _buildRemoteCard(
              isPopup: true,
              onStateChanged: () => setDialogState(() {}),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteCard({required bool isPopup, VoidCallback? onStateChanged}) {
    final previewConfig = RemoteConfig(
      manufacturer: _mfrController.text.trim().toUpperCase().isNotEmpty ? _mfrController.text.trim().toUpperCase() : 'CUSTOM',
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'My Remote',
      filePath: 'preview.xml',
      protocol: _protocolController.text.trim().isNotEmpty ? _protocolController.text.trim() : 'NEC',
      deviceCode: '0x04',
      buttons: _customButtons,
    );

    final powerButton = previewConfig.buttons.where((b) => b.type == 'power' || b.label.toLowerCase().contains('power')).firstOrNull;
    final muteButton = previewConfig.buttons.where((b) => b.type == 'mute' || b.label.toLowerCase().contains('mute')).firstOrNull;
    
    final volUp = previewConfig.buttons.where((b) => b.type == 'vol_up' || b.label.toLowerCase().contains('vol+')).firstOrNull;
    final volDown = previewConfig.buttons.where((b) => b.type == 'vol_down' || b.label.toLowerCase().contains('vol-')).firstOrNull;
    final chUp = previewConfig.buttons.where((b) => b.type == 'ch_up' || b.label.toLowerCase().contains('ch+')).firstOrNull;
    final chDown = previewConfig.buttons.where((b) => b.type == 'ch_down' || b.label.toLowerCase().contains('ch-')).firstOrNull;

    final dpadUp = previewConfig.buttons.where((b) => b.type == 'dpad_up' || b.label.toLowerCase() == 'up').firstOrNull;
    final dpadDown = previewConfig.buttons.where((b) => b.type == 'dpad_down' || b.label.toLowerCase() == 'down').firstOrNull;
    final dpadLeft = previewConfig.buttons.where((b) => b.type == 'dpad_left' || b.label.toLowerCase() == 'left').firstOrNull;
    final dpadRight = previewConfig.buttons.where((b) => b.type == 'dpad_right' || b.label.toLowerCase().contains('right')).firstOrNull;
    final dpadCenter = previewConfig.buttons.where((b) => b.type == 'dpad_center' || b.label.toLowerCase() == 'ok' || b.label.toLowerCase() == 'select').firstOrNull;

    final numButtons = previewConfig.buttons.where((b) => b.type == 'num' || RegExp(r'^[0-9]$').hasMatch(b.label)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final otherButtons = previewConfig.buttons.where((b) => 
      b != powerButton && 
      b != muteButton && 
      b != volUp && 
      b != volDown && 
      b != chUp && 
      b != chDown && 
      b != dpadUp && 
      b != dpadDown && 
      b != dpadLeft && 
      b != dpadRight && 
      b != dpadCenter &&
      !numButtons.contains(b)
    ).toList();

    return Center(
      child: SizedBox(
        width: isPopup ? 340 : 170,
        child: Container(
          padding: EdgeInsets.all(isPopup ? 16 : 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isPopup ? 24 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: isPopup ? 550 : 145),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLedActive ? Colors.red : Colors.grey[400],
                      boxShadow: _isLedActive
                          ? [BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewConfig.name,
                    style: TextStyle(color: Colors.black87, fontSize: isPopup ? 12 : 9, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(color: Colors.grey, height: 10),

                  // Power & Mute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (powerButton != null)
                        _buildPreviewButton(context, powerButton, color: Colors.red[700]!, textColor: Colors.white, icon: Icons.power_settings_new, isSmall: !isPopup, onStateChanged: onStateChanged),
                      if (powerButton != null && muteButton != null) SizedBox(width: isPopup ? 12 : 4),
                      if (muteButton != null)
                        _buildPreviewButton(context, muteButton, color: Colors.orange[800]!, textColor: Colors.white, icon: Icons.volume_off, isSmall: !isPopup, onStateChanged: onStateChanged),
                    ],
                  ),
                  SizedBox(height: isPopup ? 14 : 6),

                  // Volume & Channel
                  if (volUp != null || volDown != null || chUp != null || chDown != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (volUp != null || volDown != null)
                          Expanded(
                            child: Column(
                              children: [
                                Text('VOL', style: TextStyle(color: Colors.grey, fontSize: isPopup ? 10 : 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                if (volUp != null) _buildPreviewButton(context, volUp, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.add, compact: true, isSmall: !isPopup, onStateChanged: onStateChanged),
                                if (volUp != null && volDown != null) const SizedBox(height: 2),
                                if (volDown != null) _buildPreviewButton(context, volDown, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.remove, compact: true, isSmall: !isPopup, onStateChanged: onStateChanged),
                              ],
                            ),
                          ),
                        if ((volUp != null || volDown != null) && (chUp != null || chDown != null))
                          SizedBox(width: isPopup ? 12 : 4),
                        if (chUp != null || chDown != null)
                          Expanded(
                            child: Column(
                              children: [
                                Text('CH', style: TextStyle(color: Colors.grey, fontSize: isPopup ? 10 : 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                if (chUp != null) _buildPreviewButton(context, chUp, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_up, compact: true, isSmall: !isPopup, onStateChanged: onStateChanged),
                                if (chUp != null && chDown != null) const SizedBox(height: 2),
                                if (chDown != null) _buildPreviewButton(context, chDown, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_down, compact: true, isSmall: !isPopup, onStateChanged: onStateChanged),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isPopup ? 16 : 6),
                  ],

                  // D-Pad Area
                  if (dpadUp != null || dpadDown != null || dpadLeft != null || dpadRight != null || dpadCenter != null)
                    Container(
                      width: isPopup ? 150 : 90,
                      height: isPopup ? 150 : 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (dpadUp != null)
                            Positioned(
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_up, size: isPopup ? 30 : 18, color: Colors.black87),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _onPreviewButtonPressed(context, dpadUp, onStateChanged),
                              ),
                            ),
                          if (dpadDown != null)
                            Positioned(
                              bottom: 0,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_down, size: isPopup ? 30 : 18, color: Colors.black87),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _onPreviewButtonPressed(context, dpadDown, onStateChanged),
                              ),
                            ),
                          if (dpadLeft != null)
                            Positioned(
                              left: 0,
                              child: IconButton(
                                icon: Icon(Icons.arrow_left, size: isPopup ? 30 : 18, color: Colors.black87),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _onPreviewButtonPressed(context, dpadLeft, onStateChanged),
                              ),
                            ),
                          if (dpadRight != null)
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.arrow_right, size: isPopup ? 30 : 18, color: Colors.black87),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _onPreviewButtonPressed(context, dpadRight, onStateChanged),
                              ),
                            ),
                          if (dpadCenter != null)
                            GestureDetector(
                              onTap: () => _onPreviewButtonPressed(context, dpadCenter, onStateChanged),
                              child: Container(
                                width: isPopup ? 48 : 30,
                                height: isPopup ? 48 : 30,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    dpadCenter.label,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPopup ? 11 : 8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  SizedBox(height: isPopup ? 16 : 6),

                  // Number Pad
                  if (numButtons.isNotEmpty) ...[
                    _buildPreviewNumberPad(context, numButtons, isSmall: !isPopup, onStateChanged: onStateChanged),
                    const SizedBox(height: 6),
                  ],

                  // Other buttons
                  if (otherButtons.isNotEmpty) ...[
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      alignment: WrapAlignment.center,
                      children: otherButtons.map((btn) {
                        return SizedBox(
                          width: isPopup ? 75 : 45,
                          height: isPopup ? 32 : 22,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              elevation: 1,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () => _onPreviewButtonPressed(context, btn, onStateChanged),
                            child: Text(
                              btn.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: isPopup ? 10 : 7, fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPreviewButtonPressed(BuildContext context, RemoteButton button, [VoidCallback? onStateChanged]) async {
    setState(() {
      _isLedActive = true;
    });
    onStateChanged?.call();

    Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _isLedActive = false;
        });
        onStateChanged?.call();
      }
    });

    try {
      await IrBlasterService.transmitHex(button.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transmitted "${button.label}" (${button.code})'), duration: const Duration(milliseconds: 600)),
      );
    } catch (e) {
      // ignore
    }
  }

  Widget _buildPreviewButton(BuildContext context, RemoteButton button, {required Color color, required Color textColor, IconData? icon, bool compact = false, bool isSmall = false, VoidCallback? onStateChanged}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 1,
        padding: EdgeInsets.symmetric(horizontal: compact ? (isSmall ? 2 : 8) : (isSmall ? 4 : 14), vertical: compact ? (isSmall ? 1 : 6) : (isSmall ? 2 : 8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmall ? 4 : 8)),
      ),
      onPressed: () => _onPreviewButtonPressed(context, button, onStateChanged),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? (isSmall ? 8 : 14) : (isSmall ? 10 : 16)),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              button.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? (isSmall ? 7 : 10) : (isSmall ? 8 : 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewNumberPad(BuildContext context, List<RemoteButton> numButtons, {required bool isSmall, VoidCallback? onStateChanged}) {
    final mainNumbers = numButtons.where((b) => int.tryParse(b.label) != null && int.parse(b.label) > 0).toList()
      ..sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));
    final zeroButton = numButtons.where((b) => b.label == '0').firstOrNull;

    List<Widget> rowWidgets = [];
    for (int i = 0; i < mainNumbers.length; i += 3) {
      final chunk = mainNumbers.skip(i).take(3).toList();
      rowWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isSmall ? 2.0 : 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chunk.map((btn) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 1.5 : 3.0),
                  child: SizedBox(
                    height: isSmall ? 20 : 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => _onPreviewButtonPressed(context, btn, onStateChanged),
                      child: Text(btn.label, style: TextStyle(fontSize: isSmall ? 9 : 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...rowWidgets,
        if (zeroButton != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isSmall ? 45 : 75,
                height: isSmall ? 20 : 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () => _onPreviewButtonPressed(context, zeroButton, onStateChanged),
                  child: const Text('0', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetadataAndPreviewSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final metadataWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Remote Metadata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Remote Name', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mfrController,
                    decoration: const InputDecoration(labelText: 'Category / Brand', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _protocolController,
                    decoration: const InputDecoration(labelText: 'Protocol (e.g. NEC)', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        );

        final previewWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent, padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Popup Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              onPressed: _showPopupPreview,
            ),
            const SizedBox(height: 2),
            _buildRemoteCard(isPopup: false),
          ],
        );

        if (isWide) {
          return SizedBox(
            height: 175,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: metadataWidget),
                const SizedBox(width: 16),
                SizedBox(
                  width: 170,
                  child: previewWidget,
                ),
              ],
            ),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              metadataWidget,
              const SizedBox(height: 20),
              previewWidget,
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Designer'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Remote',
            onPressed: _saveRemote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetadataAndPreviewSection(),
            const SizedBox(height: 24),
            const Text('Add Button', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            // 1. Button Function Type first
            DropdownButtonFormField<String>(
              value: _btnType,
              decoration: const InputDecoration(labelText: '1. Button Function Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'power', child: Text('Power')),
                DropdownMenuItem(value: 'vol_up', child: Text('Volume Up')),
                DropdownMenuItem(value: 'vol_down', child: Text('Volume Down')),
                DropdownMenuItem(value: 'ch_up', child: Text('Channel Up')),
                DropdownMenuItem(value: 'ch_down', child: Text('Channel Down')),
                DropdownMenuItem(value: 'mute', child: Text('Mute')),
                DropdownMenuItem(value: 'num', child: Text('Number')),
                DropdownMenuItem(value: 'dpad_up', child: Text('D-Pad Up')),
                DropdownMenuItem(value: 'dpad_down', child: Text('D-Pad Down')),
                DropdownMenuItem(value: 'dpad_left', child: Text('D-Pad Left')),
                DropdownMenuItem(value: 'dpad_right', child: Text('D-Pad Right')),
                DropdownMenuItem(value: 'dpad_center', child: Text('D-Pad OK')),
              ],
              onChanged: (val) {
                setState(() {
                  _btnType = val ?? 'general';
                  if (_btnType == 'num' && _selectedNumLabel.isEmpty) {
                    _selectedNumLabel = '0';
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            // 2. Button Label (Dropdown if num, TextField otherwise)
            _btnType == 'num'
                ? DropdownButtonFormField<String>(
                    value: _selectedNumLabel,
                    decoration: const InputDecoration(labelText: '2. Button Label (Number)', border: OutlineInputBorder()),
                    items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
                        .map((digit) => DropdownMenuItem(value: digit, child: Text('Number $digit')))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedNumLabel = val ?? '0'),
                  )
                : TextField(
                    controller: _btnLabelController,
                    decoration: const InputDecoration(labelText: '2. Button Label (e.g. Power, Vol+, Play)', border: OutlineInputBorder()),
                  ),
            const SizedBox(height: 10),
            // 3. IR Hex Code with Test button on the side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _btnCodeController,
                    decoration: const InputDecoration(labelText: '3. IR Hex Code (e.g. 0xE0E040BF)', border: OutlineInputBorder()),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Test', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final code = _btnCodeController.text.trim();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an IR hex code to test')),
                      );
                      return;
                    }
                    try {
                      await IrBlasterService.transmitHex(code);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Test transmitted: $code'), duration: const Duration(milliseconds: 800)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transmission failed: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 4. Add Button to Remote button below
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Button to Remote', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _addCustomButton,
            ),
            const Divider(height: 32, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Configured Buttons (${_customButtons.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_customButtons.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, color: Colors.red),
                    label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    onPressed: () => setState(() => _customButtons.clear()),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _customButtons.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No buttons added yet. Add buttons above to design your remote.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customButtons.length,
                    itemBuilder: (context, index) {
                      final btn = _customButtons[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(btn.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Type: ${btn.type} | Code: ${btn.code}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _customButtons.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveRemote,
              child: const Text('Save Custom Remote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
