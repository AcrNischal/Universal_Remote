import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import '../models/remote_model.dart';

class IrParserService {
  static List<ManufacturerGroup>? _memoryCache;
  static const String _parserCacheKey = 'all_parsed_remotes_cache_v2';

  static Future<List<ManufacturerGroup>> loadAllRemotes() async {
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      return _memoryCache!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_parserCacheKey);
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        _memoryCache = decoded.map((group) {
          final mfr = group['manufacturer'] as String;
          final modelsList = (group['models'] as List<dynamic>).map((m) {
            final buttonsList = (m['buttons'] as List<dynamic>).map((b) => RemoteButton(
              label: b['label'],
              code: b['code'],
              type: b['type'],
            )).toList();

            return RemoteConfig(
              manufacturer: mfr,
              name: m['name'],
              filePath: m['filePath'],
              protocol: m['protocol'],
              deviceCode: m['deviceCode'],
              buttons: buttonsList,
            );
          }).toList();

          return ManufacturerGroup(manufacturer: mfr, models: modelsList);
        }).toList();

        return _memoryCache!;
      }
    } catch (e) {
      print('Cache load error: $e');
    }

    // Otherwise parse from assets
    try {
      final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = assetManifest.listAssets();

      final xmlPaths = allAssets
          .where((key) => key.startsWith('assets/ircodes/') && key.endsWith('.xml'))
          .toList();

      Map<String, List<RemoteConfig>> manufacturerMap = {};

      for (String path in xmlPaths) {
        try {
          final xmlString = await rootBundle.loadString(path);
          final document = XmlDocument.parse(xmlString);
          final irplusElement = document.findAllElements('irplus').firstOrNull;

          if (irplusElement != null) {
            final pathSegments = path.split('/');
            final folderManufacturer = pathSegments.length > 2 ? pathSegments[2] : 'Unknown';

            final deviceElement = irplusElement.findAllElements('device').firstOrNull;
            final xmlManufacturer = deviceElement?.getAttribute('manufacturer') ?? irplusElement.getAttribute('manufacturer');
            
            final manufacturer = (xmlManufacturer != null && xmlManufacturer.isNotEmpty && xmlManufacturer != 'Unknown')
                ? xmlManufacturer
                : folderManufacturer;

            final fileName = pathSegments.last.replaceAll('.xml', '');
            final xmlModel = deviceElement?.getAttribute('model') ?? irplusElement.findAllElements('name').firstOrNull?.text ?? irplusElement.getAttribute('name');
            final name = (xmlModel != null && xmlModel.isNotEmpty) ? xmlModel : fileName;

            final protocol = deviceElement?.getAttribute('format') ?? irplusElement.findAllElements('protocol').firstOrNull?.text ?? 'IR';
            final deviceCode = deviceElement?.getAttribute('device') ?? irplusElement.findAllElements('device').firstOrNull?.text ?? '';

            final buttonElements = irplusElement.findAllElements('button');
            List<RemoteButton> buttons = buttonElements
                .map((el) => RemoteButton.fromXml(el))
                .toList();

            final remoteConfig = RemoteConfig(
              manufacturer: manufacturer.toUpperCase(),
              name: name,
              filePath: path,
              protocol: protocol,
              deviceCode: deviceCode,
              buttons: buttons,
            );

            manufacturerMap.putIfAbsent(manufacturer.toUpperCase(), () => []).add(remoteConfig);
          }
        } catch (e) {
          // Skip malformed XML files
        }
      }

      if (manufacturerMap.isEmpty) {
        manufacturerMap = _getFallbackRemotes();
      }

      final sortedKeys = manufacturerMap.keys.toList()..sort();

      _memoryCache = sortedKeys
          .map((key) => ManufacturerGroup(
                manufacturer: key,
                models: manufacturerMap[key]!..sort((a, b) => a.name.compareTo(b.name)),
              ))
          .toList();

      // Cache to SharedPreferences asynchronously
      _saveCacheToPrefs(_memoryCache!);

      return _memoryCache!;
    } catch (e) {
      print('Error parsing AssetManifest: $e');
      final fallback = _getFallbackRemotes();
      final sortedKeys = fallback.keys.toList()..sort();
      return sortedKeys
          .map((key) => ManufacturerGroup(
                manufacturer: key,
                models: fallback[key]!,
              ))
          .toList();
    }
  }

  static void _saveCacheToPrefs(List<ManufacturerGroup> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = groups.map((g) => {
        'manufacturer': g.manufacturer,
        'models': g.models.map((m) => {
          'manufacturer': m.manufacturer,
          'name': m.name,
          'filePath': m.filePath,
          'protocol': m.protocol,
          'deviceCode': m.deviceCode,
          'buttons': m.buttons.map((b) => {'label': b.label, 'code': b.code, 'type': b.type}).toList(),
        }).toList(),
      }).toList();
      await prefs.setString(_parserCacheKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving parser cache: $e');
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
