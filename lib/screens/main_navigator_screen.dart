import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import '../services/storage_service.dart';
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
  List<RemoteConfig> _savedRemotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRemotes();
  }

  Future<void> _loadSavedRemotes() async {
    final remotes = await StorageService.loadSavedRemotes();
    if (mounted) {
      setState(() {
        _savedRemotes = remotes;
        _isLoading = false;
      });
    }
  }

  void _addRemote(RemoteConfig config) {
    if (!_savedRemotes.any((r) => r.filePath == config.filePath)) {
      setState(() {
        _savedRemotes.add(config);
      });
      StorageService.saveSavedRemotes(_savedRemotes);
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
    StorageService.saveSavedRemotes(_savedRemotes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "${config.name}" from My Remotes.')),
    );
  }

  void _resetData() async {
    await StorageService.clearAllData();
    setState(() {
      _savedRemotes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = [
      HomeTab(onRemoteSaved: _addRemote),
      SavedRemotesTab(savedRemotes: _savedRemotes, onRemoveRemote: _removeRemote),
      SettingsTab(
        themeNotifier: widget.themeNotifier,
        onRemoteImported: _addRemote,
        onResetData: _resetData,
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
