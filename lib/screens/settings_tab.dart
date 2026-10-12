import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import '../models/remote_model.dart';
import '../services/ir_blaster_service.dart';
import 'remote_designer_screen.dart';

class SettingsTab extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final Function(RemoteConfig) onRemoteImported;
  final VoidCallback onResetData;

  const SettingsTab({
    Key? key,
    required this.themeNotifier,
    required this.onRemoteImported,
    required this.onResetData,
  }) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  double _blasterSpeedMs = 200.0;
  final TextEditingController _xmlController = TextEditingController();

  void _showSyntaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('irplus XML Syntax Reference'),
        content: const SingleChildScrollView(
          child: SelectableText(
            '''Copy and paste or save as .xml file to import custom remotes:

<irplus manufacturer="SAMSUNG" name="My Custom TV">
    <protocol>NEC</protocol>
    <device>0x04</device>
    <button label="Power" type="power" code="0xE0E040BF">0xE0E040BF</button>
    <button label="Vol +" type="vol_up" code="0xE0E0E01F">0xE0E0E01F</button>
    <button label="Vol -" type="vol_down" code="0xE0E0D02F">0xE0E0D02F</button>
    <button label="Mute" type="mute" code="0xE0E0F00F">0xE0E0F00F</button>
    <button label="1" type="num" code="0xE0E020DF">0xE0E020DF</button>
</irplus>''',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String xmlText = '';
        if (file.bytes != null) {
          xmlText = String.fromCharCodes(file.bytes!);
        } else if (!kIsWeb && file.path != null) {
          final f = File(file.path!);
          xmlText = await f.readAsString();
        }

        if (xmlText.isNotEmpty) {
          _parseAndCustomizeXml(context, xmlText);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImportTextDialog(BuildContext context) {
    _xmlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Remote XML'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your irplus XML configuration below:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _xmlController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '<irplus manufacturer="..." name="...">...</irplus>',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
              final xmlText = _xmlController.text.trim();
              if (xmlText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter XML content')),
                );
                return;
              }
              Navigator.pop(context);
              _parseAndCustomizeXml(context, xmlText);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _parseAndCustomizeXml(BuildContext context, String xmlText) {
    try {
      final document = XmlDocument.parse(xmlText);
      final irplusElement = document.findAllElements('irplus').firstOrNull;
      if (irplusElement == null) {
        throw Exception('Missing <irplus> root element');
      }

      final mfrAttr = irplusElement.getAttribute('manufacturer') ?? 'Custom';
      final nameAttr = irplusElement.getAttribute('name') ?? 'Imported Remote';
      final protocol = irplusElement.findAllElements('protocol').firstOrNull?.text ?? 'NEC';
      final deviceCode = irplusElement.findAllElements('device').firstOrNull?.text ?? '0x00';

      final buttonElements = irplusElement.findAllElements('button');
      final buttons = buttonElements.map((el) => RemoteButton.fromXml(el)).toList();

      _showCustomizeDialog(context, RemoteConfig(
        manufacturer: mfrAttr,
        name: nameAttr,
        filePath: 'imported_${DateTime.now().millisecondsSinceEpoch}.xml',
        protocol: protocol,
        deviceCode: deviceCode,
        buttons: buttons,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid XML: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCustomizeDialog(BuildContext context, RemoteConfig initialConfig) {
    final nameController = TextEditingController(text: initialConfig.name);
    final categoryController = TextEditingController(text: initialConfig.manufacturer);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Remote Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Remote Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category / Manufacturer (e.g. TV, AC)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final finalName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : initialConfig.name;
              final finalMfr = categoryController.text.trim().isNotEmpty ? categoryController.text.trim().toUpperCase() : initialConfig.manufacturer;

              final customizedConfig = RemoteConfig(
                manufacturer: finalMfr,
                name: finalName,
                filePath: initialConfig.filePath,
                protocol: initialConfig.protocol,
                deviceCode: initialConfig.deviceCode,
                buttons: initialConfig.buttons,
              );

              widget.onRemoteImported(customizedConfig);
              Navigator.pop(context);
            },
            child: const Text('Save to My Remotes'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Remotes & Settings?'),
        content: const Text('This will clear all saved remotes and reset preferences to default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              widget.onResetData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App data has been reset.')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Remote Designer',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.design_services, color: Colors.blueAccent),
              title: const Text('Create Custom Remote', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Design your own remote with custom buttons & IR codes'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RemoteDesignerScreen(
                      onRemoteCreated: widget.onRemoteImported,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Transmission Mode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ValueListenableBuilder<TransmissionMode>(
              valueListenable: TransmissionSettings.mode,
              builder: (context, currentMode, child) {
                final isAudioAux = currentMode == TransmissionMode.audioAux;
                return SwitchListTile(
                  secondary: Icon(
                    isAudioAux ? Icons.headphones : Icons.settings_remote,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Audio Jack / Aux Blaster', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isAudioAux ? 'Transmitting via audio waveform' : 'Transmitting via built-in Hardware IR'),
                  value: isAudioAux,
                  onChanged: (value) {
                    TransmissionSettings.mode.value = value ? TransmissionMode.audioAux : TransmissionMode.hardware;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Import Remotes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.blueAccent),
                  title: const Text('Import from File (.xml)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select an .xml remote file from device'),
                  onTap: () => _importFromFile(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload, color: Colors.blueAccent),
                  title: const Text('Paste XML Text', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste custom irplus XML configuration'),
                  onTap: () => _showImportTextDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.blueAccent),
                  title: const Text('View XML Syntax Reference', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Check expected irplus XML format'),
                  onTap: () => _showSyntaxDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Advanced Settings',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Blaster Transmission Speed', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_blasterSpeedMs.toInt()} ms', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Delay between transmissions or repeat gap', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Slider(
                    value: _blasterSpeedMs,
                    min: 100,
                    max: 3000,
                    divisions: 29,
                    label: '${_blasterSpeedMs.toInt()} ms',
                    onChanged: (val) => setState(() => _blasterSpeedMs = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.blueAccent,
              ),
              title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isDarkMode ? 'Currently using Dark Mode' : 'Currently using Light Mode'),
              value: isDarkMode,
              onChanged: (value) {
                widget.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.red),
              title: const Text('Reset All Data & Remotes', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Clear saved remotes and reset app preferences'),
              onTap: () => _showResetConfirmation(context),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blueAccent),
              title: Text('Universal Remote', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Version 1.0.0 • powered by DragUpTech'),
            ),
          ),
        ],
      ),
    );
  }
}
