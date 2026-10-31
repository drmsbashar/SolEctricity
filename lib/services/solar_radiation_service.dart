import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class SolarRadiationResult {
  final double peakSunHours;
  final String messageBn;
  final String messageEn;
  final String placeName;
  final bool isSuccess;

  SolarRadiationResult({
    required this.peakSunHours,
    required this.messageBn,
    required this.messageEn,
    this.placeName = '',
    required this.isSuccess,
  });

  String getMessage(bool isBangla) => isBangla ? messageBn : messageEn;
}

class LocationNameData {
  final String bn;
  final String en;

  LocationNameData({required this.bn, required this.en});
}

class SolarRadiationService {
  static const double defaultPsh = 5.5;

  /// ওপেনস্ট্রিটম্যাপ রিভার্স জিওকোডিং দিয়ে জেলা/স্থানের নাম সংগ্রহ
  static Future<LocationNameData> _fetchLocationNames(
    double lat,
    double lon,
  ) async {
    String nameBn = '';
    String nameEn = '';

    try {
      // ১. ইংরেজি নাম সংগ্রহ
      final urlEn = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en',
      );
      final resEn = await http
          .get(urlEn, headers: const {'User-Agent': 'SolectricityApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (resEn.statusCode == 200) {
        final Map<String, dynamic> dataEn = json.decode(resEn.body);
        final addr = dataEn['address'];
        if (addr != null && addr is Map<String, dynamic>) {
          nameEn =
              addr['city'] ??
              addr['state_district'] ??
              addr['county'] ??
              addr['state'] ??
              '';
          nameEn = nameEn.replaceAll('District', '').trim();
        }
      }

      // ২. বাংলা নাম সংগ্রহ
      final urlBn = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=bn',
      );
      final resBn = await http
          .get(urlBn, headers: const {'User-Agent': 'SolectricityApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (resBn.statusCode == 200) {
        final Map<String, dynamic> dataBn = json.decode(resBn.body);
        final addr = dataBn['address'];
        if (addr != null && addr is Map<String, dynamic>) {
          nameBn =
              addr['city'] ??
              addr['state_district'] ??
              addr['county'] ??
              addr['state'] ??
              '';
          nameBn = nameBn.replaceAll('জেলা', '').trim();
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    return LocationNameData(bn: nameBn, en: nameEn);
  }

  /// বর্তমান অবস্থান থেকে নাসা এপিআই ও স্থানের নাম সংগ্রহ
  static Future<SolarRadiationResult> fetchPeakSunHours() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return SolarRadiationResult(
          peakSunHours: defaultPsh,
          messageBn:
              'লোকেশন সার্ভিস বন্ধ। ডিফল্ট মান ($defaultPsh ঘণ্টা) যুক্ত হলো।',
          messageEn: 'Location disabled. Using default ($defaultPsh hrs).',
          isSuccess: false,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return SolarRadiationResult(
            peakSunHours: defaultPsh,
            messageBn:
                'পারমিশন বাতিল। ডিফল্ট মান ($defaultPsh ঘণ্টা) যুক্ত হলো।',
            messageEn: 'Permission denied. Using default ($defaultPsh hrs).',
            isSuccess: false,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return SolarRadiationResult(
          peakSunHours: defaultPsh,
          messageBn:
              'লোকেশন পারমিশন বন্ধ। ডিফল্ট মান ($defaultPsh ঘণ্টা) যুক্ত হলো।',
          messageEn:
              'Location permission permanently denied. Default ($defaultPsh hrs) used.',
          isSuccess: false,
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      final double lat = position.latitude;
      final double lon = position.longitude;
      final String latStr = lat.toStringAsFixed(3);
      final String lonStr = lon.toStringAsFixed(3);

      // প্যারালালে স্থানের নাম ও নাসা এপিআই কল
      final locationFuture = _fetchLocationNames(lat, lon);
      final nasaUrl = Uri.parse(
        'https://power.larc.nasa.gov/api/temporal/climatology/point?'
        'parameters=ALLSKY_SFC_SW_DWN&community=RE&longitude=$lonStr&latitude=$latStr&format=JSON',
      );
      final nasaFuture = http.get(nasaUrl).timeout(const Duration(seconds: 10));

      final results = await Future.wait([locationFuture, nasaFuture]);
      final LocationNameData placeNames = results[0] as LocationNameData;
      final http.Response nasaResponse = results[1] as http.Response;

      double psh = defaultPsh;
      bool isSuccess = false;

      if (nasaResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(nasaResponse.body);
        final parameterData =
            data['properties']?['parameter']?['ALLSKY_SFC_SW_DWN'];
        if (parameterData != null && parameterData['ANN'] != null) {
          final annualAverage = (parameterData['ANN'] as num).toDouble();
          psh = double.parse(annualAverage.toStringAsFixed(2));
          isSuccess = true;
        }
      }

      final String placeBn = placeNames.bn;
      final String placeEn = placeNames.en;

      final String labelBn = placeBn.isNotEmpty ? '📍 $placeBn | ' : '';
      final String labelEn = placeEn.isNotEmpty ? '📍 $placeEn | ' : '';

      return SolarRadiationResult(
        peakSunHours: psh,
        placeName: placeEn,
        messageBn: '${labelBn}নাসা ডেটাবেজ ($latStr°N, $lonStr°E)',
        messageEn: '${labelEn}NASA DB ($latStr°N, $lonStr°E)',
        isSuccess: isSuccess,
      );
    } catch (e) {
      debugPrint('Solar Fetch Error: $e');
      return SolarRadiationResult(
        peakSunHours: defaultPsh,
        messageBn:
            'সংযোগের সমস্যার কারণে ডিফল্ট মান ($defaultPsh ঘণ্টা) রাখা হলো।',
        messageEn: 'Network error. Using default value ($defaultPsh hrs).',
        isSuccess: false,
      );
    }
  }
}
