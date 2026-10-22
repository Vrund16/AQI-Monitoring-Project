import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class ApiService {
  static const String defaultApiUrl =
      'https://aqi-monitoring-project.onrender.com/api/readings/latest';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static String formatLatestEndpoint(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return defaultApiUrl;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw const FormatException('Enter a valid HTTP or HTTPS API URL.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('API URL must use HTTP or HTTPS.');
    }

    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/api/readings')) {
      path = '$path/latest';
    } else if (!path.endsWith('/api/readings/latest')) {
      path = '$path/api/readings/latest';
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }

  static Uri _latestUri(String endpoint) =>
      Uri.parse(formatLatestEndpoint(endpoint));

  static Uri _backendUri(String endpoint, String path) {
    final uri = _latestUri(endpoint);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    );
  }

  Future<SensorReading> fetchLatestReading({
    String endpoint = defaultApiUrl,
  }) async {
    final uri = _latestUri(endpoint);
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception('No sensor readings in the database yet.');
      }
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);
      final data =
          decoded is Map<String, dynamic> ? decoded['data'] ?? decoded : null;
      if (data is! Map<String, dynamic>) {
        throw Exception('The API returned an invalid readings response.');
      }
      return SensorReading.fromJson(data);
    } on SocketException {
      throw Exception(
        'Cannot reach ${uri.host}. Check the phone internet connection or wait for the Render service to start.',
      );
    } on TimeoutException {
      throw Exception('The readings API request timed out.');
    } on FormatException catch (error) {
      throw Exception('The API returned invalid JSON: ${error.message}');
    } catch (error) {
      if (error.toString().contains('Failed host lookup')) {
        throw Exception(
          'DNS lookup failed for ${uri.host}. Check that the phone has internet access.',
        );
      }
      rethrow;
    }
  }

  Future<List<SensorReading>> fetchHistory({
    int limit = 20,
    String endpoint = defaultApiUrl,
  }) async {
    final uri = _backendUri(endpoint, '/api/readings')
        .replace(queryParameters: {'limit': '$limit'});
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('History API returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw Exception('The history API returned an invalid response.');
    }
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception('The history API returned an invalid reading.');
      }
      return SensorReading.fromJson(item);
    }).toList();
  }

  Future<Map<String, dynamic>> checkHealth({
    String endpoint = defaultApiUrl,
  }) async {
    final uri = _backendUri(endpoint, '/api/health');
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Health check returned HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('The health API returned an invalid response.');
      }
      return decoded;
    } on SocketException {
      throw Exception(
          'Cannot reach ${uri.host}. Check the phone internet connection.');
    } on TimeoutException {
      throw Exception('The server health check timed out.');
    }
  }

  void close() => _client.close();
}
