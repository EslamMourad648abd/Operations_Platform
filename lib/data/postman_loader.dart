// lib/utils/postman_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/api_preset.dart';
import '../models/api_prest_group.dart';

class PostmanLoader {
  static Future<List<ApiPresetGroup>> loadFromAssets(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      List<ApiPresetGroup> groups = [];
      if (data['item'] != null) {
        for (var group in data['item']) {
          if (group['item'] == null) continue;

          List<ApiPreset> presets = group['item']
              .map<ApiPreset>((req) => ApiPreset.fromPostman(req))
              .toList();

          groups.add(ApiPresetGroup(name: group['name'], presets: presets));
        }
      }
      return groups;
    } catch (e, s) {
      print("❌ Error loading Postman file: $e");
      print(s);
      return [];
    }
  }
}
