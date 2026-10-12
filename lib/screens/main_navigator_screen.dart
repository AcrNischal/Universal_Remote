import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import 'home_tab.dart';
import 'saved_remotes_tab.dart';
import 'settings_tab.dart';

class MainNavigatorScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainNavigatorScreen({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  State<MainNavigatorScreen> createState() => _MainNavigatorScreenState();
}

class _MainNavigatorScreenState extends State<MainNavigatorScreen> {
  int _currentIndex = 0;
  final List<RemoteConfig> _savedRemotes = [];

  void _addRemote(RemoteConfig config) {
    if (!_savedRemotes.any((r) => r.filePath == config.filePath)) {
      setState(() {
        _savedRemotes.add(config);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${config.name}" to My Remotes!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${config.name}" is already saved.')),
      );
    }
  }

  void _removeRemote(RemoteConfig config) {
    setState(() {
      _savedRemotes.removeWhere((r) => r.filePath == config.filePath);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "${config.name}" from My Remotes.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(onRemoteSaved: _addRemote),
      SavedRemotesTab(savedRemotes: _savedRemotes, onRemoveRemote: _removeRemote),
      SettingsTab(
        themeNotifier: widget.themeNotifier,
        onRemoteImported: _addRemote,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'My Remotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
