import 'package:flutter/material.dart';

enum AlertLevel { safe, warning, danger }

class SensorReading {
  final String? id;
  final String deviceId;
  final double temperature;
  final double humidity;
  final double co2;
  final double co;
  final double no2;
  final DateTime timestamp;

  SensorReading({
    this.id,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.co,
    required this.no2,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['_id'] as String?,
      deviceId: json['deviceId']?.toString() ?? 'ESP32_DEV',
      temperature: _toDouble(json['temperature'], 24.0),
      humidity: _toDouble(json['humidity'], 50.0),
      co2: _toDouble(json['co2'], 450.0),
      co: _toDouble(json['co'], 0.5),
      no2: _toDouble(json['no2'], 15.0),
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'deviceId': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'co2': co2,
        'co': co,
        'no2': no2,
        'createdAt': timestamp.toIso8601String(),
      };

  /// Composite AQI score calculation matching web dashboard logic
  int get compositeScore {
    final score = (co2 / 20.0) + (co * 8.0) + (no2 * 0.8);
    return score.round().clamp(0, 500);
  }

  String get aqiCategory {
    final score = compositeScore;
    if (score <= 50) return 'GOOD';
    if (score <= 100) return 'MODERATE';
    if (score <= 150) return 'UNHEALTHY FOR SENSITIVE';
    if (score <= 200) return 'UNHEALTHY';
    if (score <= 300) return 'VERY UNHEALTHY';
    return 'HAZARDOUS';
  }

  Color get aqiColor {
    final score = compositeScore;
    if (score <= 50) return const Color(0xFF10B981); // Emerald Green
    if (score <= 100) return const Color(0xFFF59E0B); // Amber / Yellow
    if (score <= 150) return const Color(0xFFF97316); // Orange
    if (score <= 200) return const Color(0xFFEF4444); // Crimson Red
    if (score <= 300) return const Color(0xFF8B5CF6); // Purple
    return const Color(0xFF881337); // Dark Maroon
  }

  AlertLevel get co2AlertLevel {
    if (co2 >= 1500) return AlertLevel.danger;
    if (co2 >= 1000) return AlertLevel.warning;
    return AlertLevel.safe;
  }

  AlertLevel get coAlertLevel {
    if (co >= 25.0) return AlertLevel.danger;
    if (co >= 9.0) return AlertLevel.warning;
    return AlertLevel.safe;
  }

  AlertLevel get no2AlertLevel {
    if (no2 >= 100.0) return AlertLevel.danger;
    if (no2 >= 54.0) return AlertLevel.warning;
    return AlertLevel.safe;
  }

  String get healthSummary {
    if (compositeScore <= 50) {
      return 'Air quality is pristine. Perfect conditions for outdoor activities and fresh ventilation.';
    } else if (compositeScore <= 100) {
      return 'Air quality is acceptable. Sensitive individuals may consider limiting prolonged outdoor exertion.';
    } else if (compositeScore <= 150) {
      return 'Elevated pollutant levels. Vulnerable groups may experience cough or shortness of breath.';
    } else {
      return 'Hazardous concentration detected! Keep windows closed, turn on air purifiers, and wear protective masks outdoors.';
    }
  }

  SensorReading copyWith({
    String? id,
    String? deviceId,
    double? temperature,
    double? humidity,
    double? co2,
    double? co,
    double? no2,
    DateTime? timestamp,
  }) {
    return SensorReading(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      co2: co2 ?? this.co2,
      co: co ?? this.co,
      no2: no2 ?? this.no2,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
