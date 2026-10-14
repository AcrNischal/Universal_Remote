import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import '../models/remote_model.dart';

class IrParserService {
  static List<ManufacturerGroup>? _cachedGroups;

  static Future<List<ManufacturerGroup>> loadAllRemotes() async {
    if (_cachedGroups != null) {
      return _cachedGroups!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJsonString = prefs.getString('cached_all_remotes_json');

      if (cachedJsonString != null && cachedJsonString.isNotEmpty) {
        try {
          final List<dynamic> decodedList = jsonDecode(cachedJsonString);
          Map<String, List<RemoteConfig>> manufacturerMap = {};
          for (var item in decodedList) {
            final config = RemoteConfig.fromJson(item);
            manufacturerMap.putIfAbsent(config.manufacturer, () => []).add(config);
          }

          if (manufacturerMap.isNotEmpty) {
            final sortedKeys = manufacturerMap.keys.toList()..sort();
            _cachedGroups = sortedKeys
                .map((key) => ManufacturerGroup(
                      manufacturer: key,
                      models: manufacturerMap[key]!..sort((a, b) => a.name.compareTo(b.name)),
                    ))
                .toList();
            return _cachedGroups!;
          }
        } catch (e) {
          // Fall back to parsing assets
        }
      }

      final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = assetManifest.listAssets();

      final xmlPaths = allAssets
          .where((key) => key.startsWith('assets/ircodes/') && key.endsWith('.xml'))
          .toList();

      Map<String, List<RemoteConfig>> manufacturerMap = {};
      List<RemoteConfig> allConfigs = [];

      for (String path in xmlPaths) {
        try {
          final xmlString = await rootBundle.loadString(path);
          final document = XmlDocument.parse(xmlString);
          final irplusElement = document.findAllElements('irplus').firstOrNull;

          if (irplusElement != null) {
            final pathSegments = path.split('/');
            // Use the exact folder name under assets/ircodes/ as the manufacturer/category group
            // e.g. assets/ircodes/LG (TV)/Model.xml -> "LG (TV)"
            final folderManufacturer = pathSegments.length > 2 ? pathSegments[2] : 'Unknown';

            final deviceElement = irplusElement.findAllElements('device').firstOrNull;
            final fileName = pathSegments.last.replaceAll('.xml', '');
            final xmlModel = deviceElement?.getAttribute('model') ?? irplusElement.getAttribute('name');
            final name = (xmlModel != null && xmlModel.isNotEmpty) ? xmlModel : fileName;

            final protocol = deviceElement?.getAttribute('format') ?? irplusElement.findAllElements('protocol').firstOrNull?.text ?? 'IR';
            final deviceCode = deviceElement?.getAttribute('device') ?? irplusElement.findAllElements('device').firstOrNull?.text ?? '';

            final buttonElements = irplusElement.findAllElements('button');
            List<RemoteButton> buttons = buttonElements
                .map((el) => RemoteButton.fromXml(el))
                .toList();

            final remoteConfig = RemoteConfig(
              manufacturer: folderManufacturer.toUpperCase(),
              name: name,
              filePath: path,
              protocol: protocol,
              deviceCode: deviceCode,
              buttons: buttons,
            );

            manufacturerMap.putIfAbsent(folderManufacturer.toUpperCase(), () => []).add(remoteConfig);
            allConfigs.add(remoteConfig);
          }
        } catch (e) {
          // Skip malformed XML files
        }
      }

      if (manufacturerMap.isEmpty) {
        manufacturerMap = _getFallbackRemotes();
        allConfigs = manufacturerMap.values.expand((element) => element).toList();
      } else {
        try {
          final jsonString = jsonEncode(allConfigs.map((c) => c.toJson()).toList());
          await prefs.setString('cached_all_remotes_json', jsonString);
        } catch (e) {
          // ignore cache save errors
        }
      }

      // Sort manufacturers/categories alphabetically
      final sortedKeys = manufacturerMap.keys.toList()..sort();

      _cachedGroups = sortedKeys
          .map((key) => ManufacturerGroup(
                manufacturer: key,
                models: manufacturerMap[key]!..sort((a, b) => a.name.compareTo(b.name)),
              ))
          .toList();

      return _cachedGroups!;
    } catch (e) {
      print('Error loading AssetManifest: $e');
      if (_cachedGroups != null) return _cachedGroups!;
      final fallback = _getFallbackRemotes();
      final sortedKeys = fallback.keys.toList()..sort();
      _cachedGroups = sortedKeys
          .map((key) => ManufacturerGroup(
                manufacturer: key,
                models: fallback[key]!,
              ))
          .toList();
      return _cachedGroups!;
    }
  }

  static Map<String, List<RemoteConfig>> _getFallbackRemotes() {
    return {
      'SAMSUNG': [
        RemoteConfig(
          manufacturer: 'SAMSUNG',
          name: 'SMT-C Smart TV',
          filePath: 'assets/ircodes/SAMSUNG/SMT-C.xml',
          protocol: 'NEC',
          deviceCode: '0x04',
          buttons: [
            RemoteButton(label: 'Power', code: '0xE0E040BF', type: 'power'),
            RemoteButton(label: 'Mute', code: '0xE0E0F00F', type: 'mute'),
            RemoteButton(label: 'Vol +', code: '0xE0E0E01F', type: 'vol_up'),
            RemoteButton(label: 'Vol -', code: '0xE0E0D02F', type: 'vol_down'),
            RemoteButton(label: 'CH +', code: '0xE0E048B7', type: 'ch_up'),
            RemoteButton(label: 'CH -', code: '0xE0E008F7', type: 'ch_down'),
            RemoteButton(label: 'OK', code: '0x16CF0F0', type: 'dpad_center'),
          ],
        ),
      ],
    };
  }
}
