import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aqi_provider.dart';
import '../widgets/aqi_hero_gauge.dart';
import '../widgets/climate_card.dart';
import '../widgets/gas_metric_card.dart';
import '../widgets/health_advisory_card.dart';
import '../widgets/live_status_bar.dart';
import '../widgets/trends_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aqi = context.watch<AqiProvider>();
    final reading = aqi.latestReading;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.air_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AeroWatch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Air Quality Monitoring System',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Telemetry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => aqi.refreshData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => aqi.refreshData(),
        color: const Color(0xFF10B981),
        child: reading == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  if (aqi.status == ConnectionStateStatus.error)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Connecting to Render Cloud (free tier may take ~30s to wake up). Showing active telemetry.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.amber[200]
                                    : Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Live Connection Status
                  const LiveStatusBar(),
                  const SizedBox(height: 16),

                  // Hero Gauge
                  AqiHeroGauge(reading: reading),
                  const SizedBox(height: 16),

                  // Climate Cards (Temp & Humidity)
                  ClimateCard(
                    temperature: reading.temperature,
                    humidity: reading.humidity,
                  ),
                  const SizedBox(height: 16),

                  // Section Header: Gas Pollutants
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Gas Sensors Telemetry',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // CO2 Metric Card
                  GasMetricCard(
                    title: 'CO₂',
                    subtitle: 'Carbon Dioxide',
                    value: reading.co2,
                    unit: 'ppm',
                    minVal: 400,
                    maxVal: 2000,
                    alertLevel: reading.co2AlertLevel,
                    safeRangeText: '<1000 Pure, >1500 Drowsy',
                    icon: Icons.cloud_rounded,
                  ),
                  const SizedBox(height: 12),

                  // CO Metric Card
                  GasMetricCard(
                    title: 'CO',
                    subtitle: 'Carbon Monoxide',
                    value: reading.co,
                    unit: 'ppm',
                    minVal: 0,
                    maxVal: 50,
                    alertLevel: reading.coAlertLevel,
                    safeRangeText: '<9 Safe, >25 Hazard',
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 12),

                  // NO2 Metric Card
                  GasMetricCard(
                    title: 'NO₂',
                    subtitle: 'Nitrogen Dioxide',
                    value: reading.no2,
                    unit: 'ppb',
                    minVal: 0,
                    maxVal: 150,
                    alertLevel: reading.no2AlertLevel,
                    safeRangeText: '<53 Good, >100 Hazard',
                    icon: Icons.science_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Trends Graph
                  TrendsChart(history: aqi.history),
                  const SizedBox(height: 16),

                  // Health Advisory Card
                  HealthAdvisoryCard(reading: reading),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
