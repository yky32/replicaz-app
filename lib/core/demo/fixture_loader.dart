import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads offline JSON under `assets/fixtures/demo/`.
///
/// Switch path when backend is ready:
/// - Demo / TF shell: [AppConfig.demoOfflineSession] → fixtures via [DemoSeed]
/// - Live API: `USE_REMOTE_BACKEND=true` + Dio services (no fixture load)
abstract final class FixtureLoader {
  static const assetRoot = 'assets/fixtures/demo';

  static Future<Map<String, dynamic>> loadMap(String name) async {
    final raw = await rootBundle.loadString('$assetRoot/$name');
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    throw FormatException('Expected JSON object in $name');
  }

  static Future<List<Map<String, dynamic>>> loadList(String name) async {
    final raw = await rootBundle.loadString('$assetRoot/$name');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException('Expected JSON array in $name');
    }
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> meta() => loadMap('meta.json');
}
