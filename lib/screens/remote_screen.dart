// Remote Screen UI
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import '../services/ir_blaster_service.dart';

class RemoteScreen extends StatefulWidget {
  final RemoteConfig remoteConfig;

  const RemoteScreen({Key? key, required this.remoteConfig}) : super(key: key);

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _hasIrEmitter = false;
  bool _checkingIr = true;
  bool _isLedActive = false;

  @override
  void initState() {
    super.initState();
    _checkIrEmitter();
  }

  Future<void> _checkIrEmitter() async {
    final hasIr = await IrBlasterService.hasIrEmitter();
    if (mounted) {
      setState(() {
        _hasIrEmitter = hasIr;
        _checkingIr = false;
      });
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('IR Blaster Error: No hardware emitter or permission denied'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = widget.remoteConfig;

    final powerButton = remoteConfig.buttons.where((b) => b.type == 'power' || b.label.toLowerCase().contains('power')).firstOrNull;
    final muteButton = remoteConfig.buttons.where((b) => b.type == 'mute' || b.label.toLowerCase().contains('mute')).firstOrNull;
    
    final volUp = remoteConfig.buttons.where((b) => b.type == 'vol_up' || b.label.toLowerCase().contains('vol+')).firstOrNull;
    final volDown = remoteConfig.buttons.where((b) => b.type == 'vol_down' || b.label.toLowerCase().contains('vol-')).firstOrNull;
    final chUp = remoteConfig.buttons.where((b) => b.type == 'ch_up' || b.label.toLowerCase().contains('ch+')).firstOrNull;
    final chDown = remoteConfig.buttons.where((b) => b.type == 'ch_down' || b.label.toLowerCase().contains('ch-')).firstOrNull;

    final dpadUp = remoteConfig.buttons.where((b) => b.type == 'dpad_up' || b.label.toLowerCase() == 'up').firstOrNull;
    final dpadDown = remoteConfig.buttons.where((b) => b.type == 'dpad_down' || b.label.toLowerCase() == 'down').firstOrNull;
    final dpadLeft = remoteConfig.buttons.where((b) => b.type == 'dpad_left' || b.label.toLowerCase() == 'left').firstOrNull;
    final dpadRight = remoteConfig.buttons.where((b) => b.type == 'dpad_right' || b.label.toLowerCase() == 'right').firstOrNull;
    final dpadCenter = remoteConfig.buttons.where((b) => b.type == 'dpad_center' || b.label.toLowerCase() == 'ok' || b.label.toLowerCase() == 'select').firstOrNull;

    final numButtons = remoteConfig.buttons.where((b) => b.type == 'num' || RegExp(r'^[0-9]$').hasMatch(b.label)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final otherButtons = remoteConfig.buttons.where((b) => 
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
        title: Text(remoteConfig.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: _checkingIr ? [] : <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Tooltip(
                message: _hasIrEmitter ? 'IR Blaster Ready' : 'Simulation Mode (No IR Hardware)',
                child: Icon(
                  _hasIrEmitter ? Icons.settings_remote : Icons.warning_amber_rounded,
                  color: _hasIrEmitter ? Colors.green[700] : Colors.orange[800],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 380,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1),
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
                    remoteConfig.manufacturer.toUpperCase(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remoteConfig.name,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Divider(color: Colors.grey, height: 24),

                  // Power & Mute
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

                  // Volume & Channel Layout (Equal length, hide if absent)
                  if ((volUp != null || volDown != null) && (chUp != null || chDown != null)) ...[
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
                                const SizedBox(height: 6),
                                if (volDown != null) _buildStyledButton(context, volDown, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.remove, compact: true),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        if (chUp != null || chDown != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Text('CH', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                if (chUp != null) _buildStyledButton(context, chUp, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_up, compact: true),
                                const SizedBox(height: 6),
                                if (chDown != null) _buildStyledButton(context, chDown, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_down, compact: true),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ] else if (volUp != null || volDown != null) ...[
                    Column(
                      children: [
                        const Text('VOLUME', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (volDown != null) ...[
                              Expanded(child: _buildStyledButton(context, volDown, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.remove)),
                              const SizedBox(width: 12),
                            ],
                            if (volUp != null)
                              Expanded(child: _buildStyledButton(context, volUp, color: Colors.blue[700]!, textColor: Colors.white, icon: Icons.add)),
                          ],
                        ),
                      ],
                    ),
                  ] else if (chUp != null || chDown != null) ...[
                    Column(
                      children: [
                        const Text('CHANNEL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (chDown != null) ...[
                              Expanded(child: _buildStyledButton(context, chDown, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_down)),
                              const SizedBox(width: 12),
                            ],
                            if (chUp != null)
                              Expanded(child: _buildStyledButton(context, chUp, color: Colors.indigo[700]!, textColor: Colors.white, icon: Icons.keyboard_arrow_up)),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // D-Pad Area
                  if (dpadUp != null || dpadDown != null || dpadLeft != null || dpadRight != null || dpadCenter != null)
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (dpadUp != null)
                            Positioned(
                              top: 2,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_drop_up, size: 36, color: Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadUp),
                              ),
                            ),
                          if (dpadDown != null)
                            Positioned(
                              bottom: 2,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_drop_down, size: 36, color: Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadDown),
                              ),
                            ),
                          if (dpadLeft != null)
                            Positioned(
                              left: 2,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_left, size: 36, color: Colors.black87),
                                onPressed: () => _onButtonPressed(context, dpadLeft),
                              ),
                            ),
                          if (dpadRight != null)
                            Positioned(
                              right: 2,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_right, size: 36, color: Colors.black87),
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

                  // Number Pad (Perfectly Centered, including '0')
                  if (numButtons.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Number Pad', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberPad(context, numButtons),
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
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _onButtonPressed(context, btn),
                            child: Text(
                              btn.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildNumberPad(BuildContext context, List<RemoteButton> numButtons) {
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
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onButtonPressed(context, btn),
                      child: Text(btn.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _onButtonPressed(context, zeroButton),
                    child: const Text('0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ...otherNumbers.map((btn) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _onButtonPressed(context, btn),
                        child: Text(btn.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
