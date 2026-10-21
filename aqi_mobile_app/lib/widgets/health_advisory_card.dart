import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';

class HealthAdvisoryCard extends StatelessWidget {
  final SensorReading reading;

  const HealthAdvisoryCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aqi = reading.compositeScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Health Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildItem(
            context,
            icon: Icons.masks_rounded,
            title: 'Face Mask',
            status: aqi > 150
                ? 'N95 Mask Strongly Advised'
                : (aqi > 100 ? 'Recommended for Sensitive Groups' : 'Not Required'),
            isWarning: aqi > 100,
          ),
          const Divider(height: 20, thickness: 0.8),
          _buildItem(
            context,
            icon: Icons.window_rounded,
            title: 'Ventilation',
            status: aqi > 120
                ? 'Keep Windows Closed'
                : (reading.co2 > 1200
                    ? 'Ventilate Room (High CO₂)'
                    : 'Open Windows for Fresh Air'),
            isWarning: aqi > 120 || reading.co2 > 1200,
          ),
          const Divider(height: 20, thickness: 0.8),
          _buildItem(
            context,
            icon: Icons.directions_run_rounded,
            title: 'Outdoor Exercise',
            status: aqi > 150
                ? 'Avoid Outdoor Workouts'
                : (aqi > 100 ? 'Reduce Intense Cardio' : 'Ideal for Outdoor Sports'),
            isWarning: aqi > 100,
          ),
          const Divider(height: 20, thickness: 0.8),
          _buildItem(
            context,
            icon: Icons.air_rounded,
            title: 'Air Purifier',
            status: aqi > 100
                ? 'Turn Purifier ON (High Fan)'
                : 'Eco / Auto Mode Sufficient',
            isWarning: aqi > 100,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String status,
    required bool isWarning,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isWarning
        ? const Color(0xFFF59E0B)
        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669));

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
