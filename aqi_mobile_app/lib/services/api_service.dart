import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';

class ApiService {
  static const String defaultBaseUrl = 'https://aqi-monitoring-project.onrender.com';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Clean URL helper
  static String formatUrl(String raw) {
    String url = raw.trim();
    if (url.isEmpty) return defaultBaseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Fetch the latest real-time sensor reading from the Render backend
  Future<SensorReading> fetchLatestReading({String baseUrl = defaultBaseUrl}) async {
    final cleanUrl = formatUrl(baseUrl);
    final uri = Uri.parse('$cleanUrl/api/readings/latest');

    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) {
          return SensorReading.fromJson(data);
        }
        throw Exception('Unexpected data payload structure from API');
      } else if (response.statusCode == 404) {
        throw Exception('No sensor readings in database yet');
      } else {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw Exception(
        'Cannot reach $cleanUrl. Check phone Wi-Fi/Internet connection, or Render instance may be spinning up.',
      );
    } on TimeoutException catch (_) {
      throw Exception(
        'Request timed out. Render free tier takes ~30-40s during cold start.',
      );
    } catch (e) {
      if (e.toString().contains('Failed host lookup')) {
        throw Exception(
          'DNS Lookup failed for $cleanUrl. Please verify your phone has an active Internet connection.',
        );
      }
      rethrow;
    }
  }

  /// Fetch historical readings from Render backend
  Future<List<SensorReading>> fetchHistory({
    int limit = 20,
    String baseUrl = defaultBaseUrl,
  }) async {
    final cleanUrl = formatUrl(baseUrl);
    final uri = Uri.parse('$cleanUrl/api/readings?limit=$limit');

    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'];
        if (list is List) {
          return list
              .map((item) => SensorReading.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load history: HTTP ${response.statusCode}');
      }
    } catch (_) {
      // Return empty list on network error without crashing
      return [];
    }
  }

  /// Health check for the server & MongoDB status
  Future<Map<String, dynamic>> checkHealth({String baseUrl = defaultBaseUrl}) async {
    final cleanUrl = formatUrl(baseUrl);
    final uri = Uri.parse('$cleanUrl/api/health');

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'error',
          'server': 'offline',
          'code': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      return {
        'status': 'error',
        'message': 'No internet or hostname not found: ${e.message}',
      };
    } on TimeoutException {
      return {
        'status': 'error',
        'message': 'Server timed out (Render free tier waking up)',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Post a new test reading to the backend
  Future<bool> postReading({
    required String deviceId,
    required double co2,
    required double co,
    required double no2,
    required double temperature,
    required double humidity,
    String baseUrl = defaultBaseUrl,
  }) async {
    final cleanUrl = formatUrl(baseUrl);
    final uri = Uri.parse('$cleanUrl/api/readings');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'co2': co2,
        'co': co,
        'no2': no2,
        'temperature': temperature,
        'humidity': humidity,
      }),
    ).timeout(const Duration(seconds: 12));

    return response.statusCode == 201;
  }

  /// Generates synthetic sensor reading for simulation or offline fallback
  static SensorReading generateMockReading([SensorReading? previous]) {
    final rnd = Random();
    final prev = previous ??
        SensorReading(
          deviceId: 'ESP32_002',
          temperature: 26.5,
          humidity: 62.0,
          co2: 520.0,
          co: 1.2,
          no2: 18.5,
          timestamp: DateTime.now(),
        );

    final deltaTemp = (rnd.nextDouble() - 0.48) * 0.4;
    final deltaHum = (rnd.nextDouble() - 0.5) * 0.8;
    final deltaCo2 = (rnd.nextDouble() - 0.48) * 35;
    final deltaCo = (rnd.nextDouble() - 0.5) * 0.2;
    final deltaNo2 = (rnd.nextDouble() - 0.5) * 1.2;

    return SensorReading(
      deviceId: prev.deviceId,
      temperature: double.parse((prev.temperature + deltaTemp).clamp(18.0, 38.0).toStringAsFixed(1)),
      humidity: double.parse((prev.humidity + deltaHum).clamp(25.0, 85.0).toStringAsFixed(1)),
      co2: (prev.co2 + deltaCo2).clamp(350.0, 2200.0).roundToDouble(),
      co: double.parse((prev.co + deltaCo).clamp(0.1, 35.0).toStringAsFixed(1)),
      no2: double.parse((prev.no2 + deltaNo2).clamp(2.0, 120.0).toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
  }
}
