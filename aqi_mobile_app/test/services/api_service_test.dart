import 'dart:convert';

import 'package:aqi_mobile_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiService.formatLatestEndpoint', () {
    test('uses the shared Render readings endpoint by default', () {
      expect(
        ApiService.formatLatestEndpoint(''),
        'https://aqi-monitoring-project.onrender.com/api/readings/latest',
      );
    });

    test('accepts the full endpoint without adding a duplicate path', () {
      expect(
        ApiService.formatLatestEndpoint(
          'https://aqi-monitoring-project.onrender.com/api/readings/latest/',
        ),
        'https://aqi-monitoring-project.onrender.com/api/readings/latest',
      );
    });

    test('converts a saved base URL to the latest readings endpoint', () {
      expect(
        ApiService.formatLatestEndpoint('aqi-monitoring-project.onrender.com'),
        'https://aqi-monitoring-project.onrender.com/api/readings/latest',
      );
    });

    test('rejects unsupported protocols', () {
      expect(
        () => ApiService.formatLatestEndpoint('ftp://example.com'),
        throwsFormatException,
      );
    });
  });

  test('fetches and parses the backend latest-reading response', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        ApiService.defaultApiUrl,
      );
      return http.Response(
        jsonEncode({
          'status': 'success',
          'data': {
            'deviceId': 'ESP32_002',
            'temperature': 28.0,
            'humidity': 59.4,
            'co2': 1062,
            'co': 0,
            'no2': 1.9,
            'createdAt': '2026-10-22T10:00:00.000Z',
          },
        }),
        200,
      );
    });
    final service = ApiService(client: client);

    final reading = await service.fetchLatestReading();

    expect(reading.deviceId, 'ESP32_002');
    expect(reading.temperature, 28.0);
    expect(reading.humidity, 59.4);
    expect(reading.co2, 1062);
    service.close();
  });

  test('uses the shared backend history and health routes', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/readings') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'deviceId': 'ESP32_002',
                'temperature': 28.0,
                'humidity': 59.4,
                'co2': 1062,
                'co': 0,
                'no2': 1.9,
                'createdAt': '2026-10-22T10:00:00.000Z',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'status': 'success',
          'server': 'running',
          'database': 'connected',
        }),
        200,
      );
    });
    final service = ApiService(client: client);

    final history = await service.fetchHistory();
    final health = await service.checkHealth();

    expect(history, hasLength(1));
    expect(requests[0].url.path, '/api/readings');
    expect(requests[0].url.queryParameters['limit'], '20');
    expect(requests[1].url.path, '/api/health');
    expect(health['database'], 'connected');
    service.close();
  });
}
