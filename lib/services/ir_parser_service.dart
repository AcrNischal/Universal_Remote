import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/remote_model.dart';

class IrParserService {
  static Future<List<ManufacturerGroup>> loadAllRemotes() async {
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
          }
        } catch (e) {
          // Skip malformed XML files
        }
      }

      if (manufacturerMap.isEmpty) {
        manufacturerMap = _getFallbackRemotes();
      }

      // Sort manufacturers/categories alphabetically
      final sortedKeys = manufacturerMap.keys.toList()..sort();

      return sortedKeys
          .map((key) => ManufacturerGroup(
                manufacturer: key,
                models: manufacturerMap[key]!..sort((a, b) => a.name.compareTo(b.name)),
              ))
          .toList();
    } catch (e) {
      print('Error loading AssetManifest: $e');
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
