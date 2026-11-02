import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      displayName: json['display_name'] ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class LocationSearchService {
  // ওপেনস্ট্রিটম্যাপের ফ্রি Nominatim API (কোনো ক্রেডিট কার্ড বা সাবস্ক্রিপশন ছাড়াই কাজ করে)
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'SolectricityApp/1.0 (contact: support@solectricity.app)',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => PlaceSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
