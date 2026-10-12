import 'package:flutter/material.dart';
import '../models/remote_model.dart';

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

  void _addCustomButton() {
    final label = _btnLabelController.text.trim();
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
      _btnLabelController.clear();
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
            const Text('Remote Metadata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Remote Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mfrController,
                    decoration: const InputDecoration(labelText: 'Category / Brand', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _protocolController,
                    decoration: const InputDecoration(labelText: 'Protocol (e.g. NEC)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Add Button', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _btnLabelController,
              decoration: const InputDecoration(labelText: 'Button Label (e.g. Power, Vol+, 1)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _btnCodeController,
              decoration: const InputDecoration(labelText: 'IR Hex Code (e.g. 0xE0E040BF)', border: OutlineInputBorder()),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _btnType,
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
              onChanged: (val) => setState(() => _btnType = val ?? 'general'),
            ),
            const SizedBox(height: 12),
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
