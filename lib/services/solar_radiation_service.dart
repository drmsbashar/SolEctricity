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
  final Map<String, double> monthlyPsh;
  final double ambientTemp;
  final double tempMax;
  final double tempMin;
  final bool isCoastal;

  // ➕ বৈশ্বিক বাতাস ও ১২ মাসের তাপমাত্রার নতুন প্যারামিটার
  final double windSpeed; // গড় বাতাসের বেগ (m/s)
  final Map<String, double> monthlyTempAvg; // ১২ মাসের গড় তাপমাত্রা
  final Map<String, double> monthlyTempMax; // ১২ মাসের সর্বোচ্চ তাপমাত্রা
  final Map<String, double> monthlyTempMin; // ১২ মাসের সর্বনিম্ন তাপমাত্রা

  SolarRadiationResult({
    required this.peakSunHours,
    required this.messageBn,
    required this.messageEn,
    this.placeName = '',
    required this.isSuccess,
    this.monthlyPsh = const {},
    this.ambientTemp = 26.0,
    this.tempMax = 32.0,
    this.tempMin = 20.0,
    this.isCoastal = false,
    this.windSpeed = 3.5,
    this.monthlyTempAvg = const {},
    this.monthlyTempMax = const {},
    this.monthlyTempMin = const {},
  });

  String getMessage(bool isBangla) => isBangla ? messageBn : messageEn;
}

class LocationNameData {
  final String bn;
  final String en;

  LocationNameData({required this.bn, required this.en});
}

class SolarRadiationService {
  static const double defaultPsh = 4.8;

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

  static Future<SolarRadiationResult> fetchPshByCoordinates(
    double lat,
    double lon,
  ) async {
    final String latStr = lat.toStringAsFixed(3);
    final String lonStr = lon.toStringAsFixed(3);
    try {
      final locationFuture = _fetchLocationNames(lat, lon);

      // 💡 বৈশ্বিক বাতাসের গতি (WS10M) সহ এপিআই কল
      final nasaUrl = Uri.parse(
        'https://power.larc.nasa.gov/api/temporal/climatology/point?'
        'parameters=ALLSKY_SFC_SW_DWN,T2M,T2M_MAX,T2M_MIN,WS10M&community=RE&longitude=$lonStr&latitude=$latStr&format=JSON',
      );
      final nasaFuture = http.get(nasaUrl).timeout(const Duration(seconds: 10));

      final results = await Future.wait([locationFuture, nasaFuture]);
      final LocationNameData placeNames = results[0] as LocationNameData;
      final http.Response nasaResponse = results[1] as http.Response;

      double psh = defaultPsh;
      double avgTemp = 26.0;
      double tMax = 32.0;
      double tMin = 20.0;
      double windSpeed = 3.5;
      final Map<String, double> monthlyPsh = {};
      final Map<String, double> monthlyTempAvg = {};
      final Map<String, double> monthlyTempMax = {};
      final Map<String, double> monthlyTempMin = {};
      bool isSuccess = false;

      final months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];

      if (nasaResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(nasaResponse.body);
        final params = data['properties']?['parameter'];

        // ১. সৌর বিকিরণ (PSH)
        final solarData = params?['ALLSKY_SFC_SW_DWN'];
        if (solarData != null) {
          if (solarData['ANN'] != null) {
            psh = double.parse(
              (solarData['ANN'] as num).toDouble().toStringAsFixed(2),
            );
            isSuccess = true;
          }
          for (var m in months) {
            if (solarData[m] != null) {
              monthlyPsh[m] = double.parse(
                (solarData[m] as num).toDouble().toStringAsFixed(2),
              );
            }
          }
        }

        // ২. তাপমাত্রা পার্সিং (বাৎসরিক ও ১২ মাসের মান)
        final tAvgData = params?['T2M'];
        if (tAvgData != null) {
          if (tAvgData['ANN'] != null)
            avgTemp = double.parse(
              (tAvgData['ANN'] as num).toDouble().toStringAsFixed(1),
            );
          for (var m in months) {
            if (tAvgData[m] != null)
              monthlyTempAvg[m] = (tAvgData[m] as num).toDouble();
          }
        }

        final tMaxData = params?['T2M_MAX'];
        if (tMaxData != null) {
          if (tMaxData['ANN'] != null)
            tMax = double.parse(
              (tMaxData['ANN'] as num).toDouble().toStringAsFixed(1),
            );
          for (var m in months) {
            if (tMaxData[m] != null)
              monthlyTempMax[m] = (tMaxData[m] as num).toDouble();
          }
        }

        final tMinData = params?['T2M_MIN'];
        if (tMinData != null) {
          if (tMinData['ANN'] != null)
            tMin = double.parse(
              (tMinData['ANN'] as num).toDouble().toStringAsFixed(1),
            );
          for (var m in months) {
            if (tMinData[m] != null)
              monthlyTempMin[m] = (tMinData[m] as num).toDouble();
          }
        }

        // ৩. বাতাসের গতিবেগ (WS10M) পার্সিং
        final wsData = params?['WS10M'];
        if (wsData != null && wsData['ANN'] != null) {
          windSpeed = double.parse(
            (wsData['ANN'] as num).toDouble().toStringAsFixed(1),
          );
        }
      }

      // 🌍 বৈশ্বিক উপকূলীয়/উচ্চ বায়ুপ্রবাহ যাচাই: বাতাসের গতিবেগ ৫.০ m/s এর বেশি হলে
      final bool isCoastal = windSpeed >= 4.8;

      final String placeEn = placeNames.en;
      final String placeBn = placeNames.bn;
      final String labelBn = placeBn.isNotEmpty ? '📍 $placeBn | ' : '';
      final String labelEn = placeEn.isNotEmpty ? '📍 $placeEn | ' : '';

      return SolarRadiationResult(
        peakSunHours: psh,
        monthlyPsh: monthlyPsh,
        ambientTemp: avgTemp,
        tempMax: tMax,
        tempMin: tMin,
        windSpeed: windSpeed,
        monthlyTempAvg: monthlyTempAvg,
        monthlyTempMax: monthlyTempMax,
        monthlyTempMin: monthlyTempMin,
        isCoastal: isCoastal,
        placeName: placeEn,
        messageBn: '${labelBn}নাসা ডেটাবেজ ($latStr°N, $lonStr°E)',
        messageEn: '${labelEn}NASA DB ($latStr°N, $lonStr°E)',
        isSuccess: isSuccess,
      );
    } catch (e) {
      debugPrint('Solar Fetch By Coords Error: $e');
      return SolarRadiationResult(
        peakSunHours: defaultPsh,
        messageBn: 'ডিফল্ট মান ($defaultPsh ঘণ্টা) ব্যবহার করা হয়েছে।',
        messageEn: 'Default value ($defaultPsh hrs) used.',
        isSuccess: false,
      );
    }
  }
}
