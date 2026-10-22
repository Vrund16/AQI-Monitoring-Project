import 'package:aqi_mobile_app/models/sensor_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SensorReading readingWithScore(int score) => SensorReading(
        deviceId: 'ESP32_002',
        temperature: 24,
        humidity: 50,
        co2: score * 20,
        co: 0,
        no2: 0,
        timestamp: DateTime.utc(2026, 10, 22),
      );

  test('AQI categories match the web dashboard thresholds', () {
    expect(readingWithScore(50).aqiCategory, 'Good');
    expect(readingWithScore(51).aqiCategory, 'Moderate');
    expect(readingWithScore(101).aqiCategory, 'Unhealthy for sensitive groups');
    expect(readingWithScore(151).aqiCategory, 'Unhealthy');
    expect(readingWithScore(201).aqiCategory, 'Very unhealthy');
    expect(readingWithScore(301).aqiCategory, 'Hazardous');
  });

  test('rejects an API reading with missing sensor values', () {
    expect(
      () => SensorReading.fromJson({
        'deviceId': 'ESP32_002',
        'temperature': 24.0,
        'humidity': 50.0,
        'co2': 400,
        'co': 0.2,
      }),
      throwsFormatException,
    );
  });
}
