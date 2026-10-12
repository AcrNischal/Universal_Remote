import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsTab({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              },
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
