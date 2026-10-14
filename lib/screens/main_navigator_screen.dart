import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_model.dart';
import '../services/ir_blaster_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSavedRemotes();
  }

  Future<void> _loadSavedRemotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStringList = prefs.getStringList('saved_remotes_list') ?? [];
      final loaded = jsonStringList.map((str) {
        try {
          return RemoteConfig.fromJson(jsonDecode(str));
        } catch (e) {
          return null;
        }
      }).whereType<RemoteConfig>().toList();

      setState(() {
        _savedRemotes = loaded;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveRemotesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStringList = _savedRemotes.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('saved_remotes_list', jsonStringList);
    } catch (e) {
      // ignore
    }
  }

  void _addRemote(RemoteConfig config) {
    if (!_savedRemotes.any((r) => r.filePath == config.filePath)) {
      setState(() {
        _savedRemotes.add(config);
      });
      _saveRemotesToPrefs();
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
    _saveRemotesToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "${config.name}" from My Remotes.')),
    );
  }

  void _resetData() async {
    setState(() {
      _savedRemotes.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_remotes_list');
      await prefs.remove('cached_all_remotes_json');
      await prefs.remove('is_dark_theme');
      await prefs.remove('is_audio_aux_transmission');
      await prefs.remove('blaster_speed_ms');

      widget.themeNotifier.value = ThemeMode.light;
      TransmissionSettings.mode.value = TransmissionMode.hardware;
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
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
