import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sensor_reading.dart';
import '../providers/aqi_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aqi = context.watch<AqiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Show newest first for log review
    final historyList = aqi.history.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Readings History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => aqi.refreshData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => aqi.refreshData(),
        color: const Color(0xFF10B981),
        child: historyList.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No historical records available yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => aqi.refreshData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sync with Server'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                itemCount: historyList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reading = historyList[index];
                  return _buildLogCard(context, reading, isDark);
                },
              ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, SensorReading reading, bool isDark) {
    final aqiColor = reading.aqiColor;
    final timeStr = DateFormat('MMM dd, yyyy • hh:mm:ss a').format(reading.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: aqiColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reading.deviceId,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: aqiColor.withOpacity(0.3)),
                ),
                child: Text(
                  'AQI ${reading.compositeScore} • ${reading.aqiCategory}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: aqiColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const Divider(height: 20, thickness: 0.8),

          // Telemetry readings grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricPill(
                isDark: isDark,
                label: 'CO₂',
                value: '${reading.co2.round()} ppm',
                color: const Color(0xFF06B6D4),
              ),
              _buildMetricPill(
                isDark: isDark,
                label: 'CO',
                value: '${reading.co.toStringAsFixed(1)} ppm',
                color: const Color(0xFFF59E0B),
              ),
              _buildMetricPill(
                isDark: isDark,
                label: 'NO₂',
                value: '${reading.no2.toStringAsFixed(1)} ppb',
                color: const Color(0xFF8B5CF6),
              ),
              _buildMetricPill(
                isDark: isDark,
                label: 'Temp',
                value: '${reading.temperature.toStringAsFixed(1)}°C',
                color: const Color(0xFFF97316),
              ),
              _buildMetricPill(
                isDark: isDark,
                label: 'Hum',
                value: '${reading.humidity.toStringAsFixed(0)}%',
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
