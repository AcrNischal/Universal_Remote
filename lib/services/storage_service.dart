import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_model.dart';

class StorageService {
  static const String _savedRemotesKey = 'saved_remotes_list_v1';

  // Save favorite/saved remotes
  static Future<void> saveSavedRemotes(List<RemoteConfig> remotes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = remotes.map((r) => {
        'manufacturer': r.manufacturer,
        'name': r.name,
        'filePath': r.filePath,
        'protocol': r.protocol,
        'deviceCode': r.deviceCode,
        'buttons': r.buttons.map((b) => {'label': b.label, 'code': b.code, 'type': b.type}).toList(),
      }).toList();
      await prefs.setString(_savedRemotesKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving remotes: $e');
    }
  }

  // Load favorite/saved remotes
  static Future<List<RemoteConfig>> loadSavedRemotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_savedRemotesKey);
      if (str == null) return [];
      final List<dynamic> jsonList = json.decode(str);
      return jsonList.map((item) {
        final buttonsList = (item['buttons'] as List<dynamic>).map((b) => RemoteButton(
          label: b['label'],
          code: b['code'],
          type: b['type'],
        )).toList();

        return RemoteConfig(
          manufacturer: item['manufacturer'],
          name: item['name'],
          filePath: item['filePath'],
          protocol: item['protocol'],
          deviceCode: item['deviceCode'],
          buttons: buttonsList,
        );
      }).toList();
    } catch (e) {
      print('Error loading saved remotes: $e');
      return [];
    }
  }

  // Clear all saved data (for reset feature)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
