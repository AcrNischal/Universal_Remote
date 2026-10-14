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
  bool _isLedActive = false;

  void _showMetadataDialog() {
    final nameC = TextEditingController(text: _nameController.text);
    final mfrC = TextEditingController(text: _mfrController.text);
    final protoC = TextEditingController(text: _protocolController.text);
    final devC = TextEditingController(text: _deviceController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Remote Metadata'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Remote Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mfrC,
                decoration: const InputDecoration(labelText: 'Category / Brand', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: protoC,
                decoration: const InputDecoration(labelText: 'Protocol (e.g. NEC)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: devC,
                decoration: const InputDecoration(labelText: 'Device Code (e.g. 0x04)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _nameController.text = nameC.text.trim().isNotEmpty ? nameC.text.trim() : _nameController.text;
                _mfrController.text = mfrC.text.trim().toUpperCase().isNotEmpty ? mfrC.text.trim().toUpperCase() : _mfrController.text;
                _protocolController.text = protoC.text.trim().isNotEmpty ? protoC.text.trim() : _protocolController.text;
                _deviceController.text = devC.text.trim().isNotEmpty ? devC.text.trim() : _deviceController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save Metadata'),
          ),
        ],
      ),
    );
  }

  void _showEditButtonDialog(BuildContext context, [RemoteButton? existingButton]) {
    final isEditingExisting = existingButton != null;
    final labelController = TextEditingController(text: isEditingExisting ? existingButton.label : '');
    final codeController = TextEditingController(text: isEditingExisting ? existingButton.code : '');
    String btnType = isEditingExisting ? existingButton.type : 'general';
    String selectedNumLabel = (btnType == 'num' && isEditingExisting) ? existingButton.label : '0';
    int codeFormatIndex = (isEditingExisting && existingButton.code.contains(' ')) ? 1 : 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditingExisting ? 'Edit Button: ${existingButton.label}' : 'Add New Button'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: btnType,
                    decoration: const InputDecoration(labelText: 'Button Function Type', border: OutlineInputBorder()),
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
                      setDialogState(() {
                        btnType = val ?? 'general';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  btnType == 'num'
                      ? DropdownButtonFormField<String>(
                          value: selectedNumLabel,
                          decoration: const InputDecoration(labelText: 'Button Label (Number)', border: OutlineInputBorder()),
                          items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
                              .map((digit) => DropdownMenuItem(value: digit, child: Text('Number $digit')))
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedNumLabel = val ?? '0'),
                        )
                      : TextField(
                          controller: labelController,
                          decoration: const InputDecoration(labelText: 'Button Label', border: OutlineInputBorder()),
                        ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ChoiceChip(
                        label: const Text('Standard IR', style: TextStyle(fontSize: 10)),
                        selected: codeFormatIndex == 0,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) => setDialogState(() => codeFormatIndex = 0),
                      ),
                      ChoiceChip(
                        label: const Text('Pronto Hex', style: TextStyle(fontSize: 10)),
                        selected: codeFormatIndex == 1,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) => setDialogState(() => codeFormatIndex = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeController,
                    maxLines: codeFormatIndex == 1 ? 3 : 1,
                    decoration: InputDecoration(
                      labelText: codeFormatIndex == 1 ? 'Pronto Hex (0000 006D ...)' : 'IR Hex Code (0xE0E040BF)',
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEditingExisting)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _customButtons.remove(existingButton);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Button deleted')),
                  );
                },
                child: const Text('Delete'),
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isNotEmpty) {
                  await IrBlasterService.transmitHex(code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Test transmitted: $code'), duration: const Duration(milliseconds: 600)),
                  );
                }
              },
              child: const Text('Test'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = btnType == 'num' ? selectedNumLabel : labelController.text.trim();
                final code = codeController.text.trim();
                if (label.isEmpty || code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter label and IR code')),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() {
                  if (isEditingExisting) {
                    final index = _customButtons.indexOf(existingButton);
                    if (index != -1) {
                      _customButtons[index] = RemoteButton(label: label, code: code, type: btnType);
                    }
                  } else {
                    _customButtons.add(RemoteButton(label: label, code: code, type: btnType));
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button saved successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _onButtonPressed(BuildContext context, RemoteButton button) async {
    setState(() {
      _isLedActive = true;
    });
    Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _isLedActive = false;
        });
      }
    });

    try {
      await IrBlasterService.transmitHex(button.code);
    } catch (e) {
      // ignore
    }
    _showEditButtonDialog(context, button);
  }

  void _saveRemote() {
    if (_customButtons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one button to your remote before saving')),
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

  @override
  Widget build(BuildContext context) {
    final remoteName = _nameController.text;
    final mfr = _mfrController.text;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final powerButton = _customButtons.where((b) => b.type == 'power' || b.label.toLowerCase().contains('power')).firstOrNull;
    final muteButton = _customButtons.where((b) => b.type == 'mute' || b.label.toLowerCase().contains('mute')).firstOrNull;
    
    final volUp = _customButtons.where((b) => b.type == 'vol_up' || b.label.toLowerCase().contains('vol+')).firstOrNull;
    final volDown = _customButtons.where((b) => b.type == 'vol_down' || b.label.toLowerCase().contains('vol-')).firstOrNull;
    final chUp = _customButtons.where((b) => b.type == 'ch_up' || b.label.toLowerCase().contains('ch+')).firstOrNull;
    final chDown = _customButtons.where((b) => b.type == 'ch_down' || b.label.toLowerCase().contains('ch-')).firstOrNull;

    final dpadUp = _customButtons.where((b) => b.type == 'dpad_up' || b.label.toLowerCase() == 'up').firstOrNull;
    final dpadDown = _customButtons.where((b) => b.type == 'dpad_down' || b.label.toLowerCase() == 'down').firstOrNull;
    final dpadLeft = _customButtons.where((b) => b.type == 'dpad_left' || b.label.toLowerCase() == 'left').firstOrNull;
    final dpadRight = _customButtons.where((b) => b.type == 'dpad_right' || b.label.toLowerCase().contains('right')).firstOrNull;
    final dpadCenter = _customButtons.where((b) => b.type == 'dpad_center' || b.label.toLowerCase() == 'ok' || b.label.toLowerCase() == 'select').firstOrNull;

    final numButtons = _customButtons.where((b) => b.type == 'num' || RegExp(r'^[0-9]$').hasMatch(b.label)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final otherButtons = _customButtons.where((b) => 
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Design: $remoteName'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Metadata',
            onPressed: _showMetadataDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Remote',
            onPressed: _saveRemote,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditButtonDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Button'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 380,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
                border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300, width: 1),
              ),
              child: Column(
                children: [
                  // LED Indicator Light
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLedActive ? Colors.red : Colors.grey[400],
                      boxShadow: _isLedActive
                          ? [BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Small Vendor & Model Name
                  Text(
                    mfr.toUpperCase(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remoteName,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey, height: 24),

                  if (_customButtons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: Column(
                        children: [
                          Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No buttons added yet.\nTap "Add Button" below to build your remote!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                  // Power & Mute
                  if (powerButton != null || muteButton != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (powerButton != null)
                          _buildStyledButton(context, powerButton, color: Colors.red[700]!, textColor: Colors.white, icon: Icons.power_settings_new),
                        if (powerButton != null && muteButton != null) const SizedBox(width: 20),
                        if (muteButton != null)
                          _buildStyledButton(context, muteButton, color: Colors.orange[800]!, textColor: Colors.white, icon: Icons.volume_off),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Volume & Channel Layout
                  if (volUp != null || volDown != null || chUp != null || chDown != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (volUp != null || volDown != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Text('VOL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                if (volUp != null) _buildStyledButton(context, volUp, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.add, compact: true),
                                if (volUp != null && volDown != null) const SizedBox(height: 6),
                                if (volDown != null) _buildStyledButton(context, volDown, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.remove, compact: true),
                              ],
                            ),
                          ),
                        if ((volUp != null || volDown != null) && (chUp != null || chDown != null))
                          const SizedBox(width: 16),
                        if (chUp != null || chDown != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Text('CH', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                if (chUp != null) _buildStyledButton(context, chUp, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_up, compact: true),
                                if (chUp != null && chDown != null) const SizedBox(height: 6),
                                if (chDown != null) _buildStyledButton(context, chDown, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_down, compact: true),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // D-Pad Area
                  if (dpadUp != null || dpadDown != null || dpadLeft != null || dpadRight != null || dpadCenter != null) ...[
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
                        ],
                        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (dpadUp != null)
                            Positioned(
                              top: 2,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_up, size: 36, color: isDarkMode ? Colors.white70 : Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadUp),
                              ),
                            ),
                          if (dpadDown != null)
                            Positioned(
                              bottom: 2,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_down, size: 36, color: isDarkMode ? Colors.white70 : Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadDown),
                              ),
                            ),
                          if (dpadLeft != null)
                            Positioned(
                              left: 2,
                              child: IconButton(
                                icon: Icon(Icons.arrow_left, size: 36, color: isDarkMode ? Colors.white70 : Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadLeft),
                              ),
                            ),
                          if (dpadRight != null)
                            Positioned(
                              right: 2,
                              child: IconButton(
                                icon: Icon(Icons.arrow_right, size: 36, color: isDarkMode ? Colors.white70 : Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadRight),
                              ),
                            ),
                          if (dpadCenter != null)
                            GestureDetector(
                              onTap: () => _onButtonPressed(context, dpadCenter),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    dpadCenter.label,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Number Pad
                  if (numButtons.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Number Pad', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberPad(context, numButtons, isDarkMode),
                    const SizedBox(height: 20),
                  ],

                  // ALL OTHER XML BUTTONS
                  if (otherButtons.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('All Functions', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: otherButtons.map((btn) {
                        return SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _onButtonPressed(context, btn),
                            child: Text(
                              btn.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
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

  Widget _buildNumberPad(BuildContext context, List<RemoteButton> numButtons, bool isDarkMode) {
    final mainNumbers = numButtons.where((b) => int.tryParse(b.label) != null && int.parse(b.label) > 0).toList()
      ..sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));
    final zeroButton = numButtons.where((b) => b.label == '0').firstOrNull;
    final otherNumbers = numButtons.where((b) => !mainNumbers.contains(b) && b != zeroButton).toList();

    List<Widget> rowWidgets = [];
    for (int i = 0; i < mainNumbers.length; i += 3) {
      final chunk = mainNumbers.skip(i).take(3).toList();
      rowWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chunk.map((btn) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onButtonPressed(context, btn),
                      child: Text(btn.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
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
        if (zeroButton != null || otherNumbers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (zeroButton != null)
                SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _onButtonPressed(context, zeroButton),
                    child: Text('0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                  ),
                ),
              ...otherNumbers.map((btn) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _onButtonPressed(context, btn),
                        child: Text(btn.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStyledButton(BuildContext context, RemoteButton button, {required Color color, required Color textColor, IconData? icon, bool compact = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 8 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _onButtonPressed(context, button),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 16 : 20),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              button.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }
}
