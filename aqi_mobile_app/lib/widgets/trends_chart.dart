import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_reading.dart';

enum ChartMetric { aqi, co2, no2, temperature, humidity }

class TrendsChart extends StatefulWidget {
  final List<SensorReading> history;

  const TrendsChart({super.key, required this.history});

  @override
  State<TrendsChart> createState() => _TrendsChartState();
}

class _TrendsChartState extends State<TrendsChart> {
  ChartMetric _selectedMetric = ChartMetric.aqi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.history.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 36,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              'Collecting telemetry points (${widget.history.length}/2)...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final metricConfig = _getMetricConfig(_selectedMetric);
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.history.length; i++) {
      final r = widget.history[i];
      double val = 0;
      switch (_selectedMetric) {
        case ChartMetric.aqi:
          val = r.compositeScore.toDouble();
          break;
        case ChartMetric.co2:
          val = r.co2;
          break;
        case ChartMetric.no2:
          val = r.no2;
          break;
        case ChartMetric.temperature:
          val = r.temperature;
          break;
        case ChartMetric.humidity:
          val = r.humidity;
          break;
      }
      spots.add(FlSpot(i.toDouble(), val));
    }

    final double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final double padding = (maxY - minY) * 0.15 == 0 ? 5 : (maxY - minY) * 0.15;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historical Telemetry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${widget.history.length} data points',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartMetric.values.map((metric) {
                final isSelected = _selectedMetric == metric;
                final cfg = _getMetricConfig(metric);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cfg.name),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedMetric = metric;
                      });
                    },
                    selectedColor: cfg.color.withOpacity(0.18),
                    checkmarkColor: cfg.color,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? cfg.color
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? cfg.color.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minY: (minY - padding).clamp(0, double.infinity),
                maxY: maxY + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 3).clamp(1.0, 500.0),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 4).clamp(1.0, 10.0),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < widget.history.length) {
                          final time = widget.history[idx].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('HH:mm').format(time),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: metricConfig.color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 15,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: metricConfig.color,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          metricConfig.color.withOpacity(0.35),
                          metricConfig.color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        isDark ? const Color(0xFF0F172A) : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final reading = widget.history[idx];
                        final timeStr = DateFormat('hh:mm:ss a').format(reading.timestamp);
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} ${metricConfig.unit}\n',
                          TextStyle(
                            color: metricConfig.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: timeStr,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _MetricConfig _getMetricConfig(ChartMetric metric) {
    switch (metric) {
      case ChartMetric.aqi:
        return _MetricConfig('AQI Index', 'Index', const Color(0xFF10B981));
      case ChartMetric.co2:
        return _MetricConfig('CO₂ (Carbon Dioxide)', 'ppm', const Color(0xFF06B6D4));
      case ChartMetric.no2:
        return _MetricConfig('NO₂ (Nitrogen Dioxide)', 'ppb', const Color(0xFF8B5CF6));
      case ChartMetric.temperature:
        return _MetricConfig('Temperature', '°C', const Color(0xFFF97316));
      case ChartMetric.humidity:
        return _MetricConfig('Humidity', '%', const Color(0xFF3B82F6));
    }
  }
}

class _MetricConfig {
  final String name;
  final String unit;
  final Color color;

  _MetricConfig(this.name, this.unit, this.color);
}
