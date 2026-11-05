import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TariffConfig {
  final double residential;
  final double commercial;
  final double institutional;
  final double costPerWatt;
  final DateTime lastUpdated;

  TariffConfig({
    required this.residential,
    required this.commercial,
    required this.institutional,
    required this.costPerWatt,
    required this.lastUpdated,
  });

  // ডিফল্ট মান (অফলাইনে বা প্রাথমিক অবস্থায় তাৎক্ষণিক ব্যবহারের জন্য)
  factory TariffConfig.defaultConfig() {
    return TariffConfig(
      residential: 8.50,
      commercial: 12.50,
      institutional: 7.50,
      costPerWatt: 70.0,
      lastUpdated: DateTime(2026, 1, 1),
    );
  }

  factory TariffConfig.fromJson(Map<String, dynamic> json) {
    return TariffConfig(
      residential: (json['residential'] as num?)?.toDouble() ?? 8.50,
      commercial: (json['commercial'] as num?)?.toDouble() ?? 12.50,
      institutional: (json['institutional'] as num?)?.toDouble() ?? 7.50,
      costPerWatt: (json['cost_per_watt'] as num?)?.toDouble() ?? 70.0,
      lastUpdated:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'residential': residential,
    'commercial': commercial,
    'institutional': institutional,
    'cost_per_watt': costPerWatt,
    'updated_at': lastUpdated.toIso8601String(),
  };
}

class TariffConfigService {
  static const String _prefKey = 'cached_tariff_config';
  // ভবিষ্যতে আপনার GitHub Raw URL বা বিসিএসআইআরের হোস্টেড JSON লিংক এখানে বসাতে পারবেন
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/username/repository/main/tariff_config.json';

  /// লোকাল ক্যাশড ডেটা ফেরত দেয়, ক্যাশ না থাকলে ডিফল্ট ডেটা ফেরত দেয়
  static Future<TariffConfig> getActiveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_prefKey);

      if (cachedStr != null) {
        final Map<String, dynamic> data = json.decode(cachedStr);
        return TariffConfig.fromJson(data);
      }
    } catch (_) {}
    return TariffConfig.defaultConfig();
  }

  /// ব্যাকগ্রাউন্ডে অনলাইন থেকে নিঃশব্দে সিঙ্ক এবং লোকাল ক্যাশে সংরক্ষণ
  static Future<void> syncRemoteConfig() async {
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, json.encode(data));
      }
    } catch (_) {
      // নেটওয়ার্ক ব্যর্থ হলে কোনো এরর থ্রো করবে না, ক্যাশড ডেটাই বহাল থাকবে
    }
  }
}
