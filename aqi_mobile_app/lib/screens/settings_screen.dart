import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_reading.dart';
import '../providers/aqi_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  final ApiService _apiService = ApiService();
  bool _isPinging = false;
  Map<String, dynamic>? _pingResult;

  @override
  void initState() {
    super.initState();
    final aqi = context.read<AqiProvider>();
    _urlController = TextEditingController(text: aqi.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final rawUrl = _urlController.text.trim();
    final cleanUrl = ApiService.formatUrl(rawUrl);
    _urlController.text = cleanUrl;

    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final res = await _apiService.checkHealth(baseUrl: cleanUrl);
      stopwatch.stop();
      setState(() {
        _pingResult = {
          ...res,
          'latency': '${stopwatch.elapsedMilliseconds}ms',
        };
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _pingResult = {
          'status': 'error',
          'message': e.toString(),
          'latency': '${stopwatch.elapsedMilliseconds}ms',
        };
      });
    } finally {
      setState(() {
        _isPinging = false;
      });
    }
  }

  Future<void> _sendTestTelemetry() async {
    final aqi = context.read<AqiProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transmitting sample ESP32 reading...')),
    );

    try {
      final ok = await _apiService.postReading(
        deviceId: 'ESP32_002',
        co2: 520,
        co: 1.1,
        no2: 12.5,
        temperature: 26.4,
        humidity: 55.0,
        baseUrl: aqi.baseUrl,
      );

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text('Successfully posted reading to Render backend!'),
            ),
          );
          aqi.refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Failed to post reading to backend.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  void _simulateSpike(AlertLevel level) {
    final aqi = context.read<AqiProvider>();
    SensorReading spike;
    if (level == AlertLevel.danger) {
      spike = SensorReading(
        deviceId: 'ESP32_SIMULATOR',
        temperature: 31.5,
        humidity: 42.0,
        co2: 1750,
        co: 28.5,
        no2: 115.0,
        timestamp: DateTime.now(),
      );
    } else if (level == AlertLevel.warning) {
      spike = SensorReading(
        deviceId: 'ESP32_SIMULATOR',
        temperature: 28.0,
        humidity: 50.0,
        co2: 1180,
        co: 12.0,
        no2: 65.0,
        timestamp: DateTime.now(),
      );
    } else {
      spike = SensorReading(
        deviceId: 'ESP32_SIMULATOR',
        temperature: 24.5,
        humidity: 52.0,
        co2: 540,
        co: 1.2,
        no2: 18.0,
        timestamp: DateTime.now(),
      );
    }
    aqi.ingestCustomReading(spike);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${level.name.toUpperCase()} simulation spike!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aqi = context.watch<AqiProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section: Backend API Configuration
          _buildCard(
            isDark: isDark,
            title: 'Backend API Endpoint',
            icon: Icons.cloud_sync_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Render API Base URL',
                    hintText: 'https://aqi-monitoring-project.onrender.com',
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                      onPressed: () {
                        final formatted = ApiService.formatUrl(_urlController.text);
                        _urlController.text = formatted;
                        aqi.updateBaseUrl(formatted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API URL updated and saved!')),
                        );
                      },
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Reset to Render Default
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _urlController.text = ApiService.defaultBaseUrl;
                        aqi.updateBaseUrl(ApiService.defaultBaseUrl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset to live Render Cloud URL')),
                        );
                      },
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Reset to Render Cloud'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _urlController.text = 'http://10.0.2.2:5000';
                        aqi.updateBaseUrl('http://10.0.2.2:5000');
                      },
                      icon: const Icon(Icons.laptop_chromebook_rounded, size: 16),
                      label: const Text('Localhost PC'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ping Test Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPinging ? null : _testConnection,
                    icon: _isPinging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.speed_rounded),
                    label: Text(_isPinging ? 'Pinging Server...' : 'Test Connection & Server Health'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_pingResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _pingResult!['status'] == 'success'
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pingResult!['status'] == 'success'
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : Colors.red.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _pingResult!['status'] == 'success'
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              size: 16,
                              color: _pingResult!['status'] == 'success'
                                  ? const Color(0xFF10B981)
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _pingResult!['status'] == 'success'
                                  ? 'Server Online (${_pingResult!['latency']})'
                                  : 'Connection Failed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _pingResult!['status'] == 'success'
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _pingResult!['message'] != null
                              ? '${_pingResult!['message']}'
                              : 'Server: ${_pingResult!['server']} • Database: ${_pingResult!['database']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Simulation Spike Controls (Matching web frontend features)
          _buildCard(
            isDark: isDark,
            title: 'Simulation & Spike Testing',
            icon: Icons.science_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test visual alerts, needle indicators, and notifications without waiting for live sensors:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _simulateSpike(AlertLevel.danger),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('🚨 Hazard Spike', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _simulateSpike(AlertLevel.warning),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('⚠️ Warning Spike', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _simulateSpike(AlertLevel.safe),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('✓ Reset to Safe Normal Readings', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Polling & Refresh
          _buildCard(
            isDark: isDark,
            title: 'Polling Frequency',
            icon: Icons.timer_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose how frequently the mobile app syncs live telemetry with Render:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [3, 5, 10, 30].map((sec) {
                    final isSelected = aqi.pollIntervalSeconds == sec;
                    return ChoiceChip(
                      label: Text('${sec}s interval'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) aqi.setPollingInterval(sec);
                      },
                      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF10B981),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: App Preferences
          _buildCard(
            isDark: isDark,
            title: 'Preferences & Modes',
            icon: Icons.tune_rounded,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Toggle between sleek dark & bright theme', style: TextStyle(fontSize: 11)),
                  value: theme.isDarkMode,
                  onChanged: (val) => theme.toggleTheme(),
                  activeColor: const Color(0xFF10B981),
                ),
                const Divider(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simulation / Mock Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Generates realistic live walk data for testing', style: TextStyle(fontSize: 11)),
                  value: aqi.forceMock,
                  onChanged: (val) => aqi.setForceMock(val),
                  activeColor: const Color(0xFF10B981),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Send Test Telemetry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Simulate ESP32 POST request to Render backend', style: TextStyle(fontSize: 11)),
                  trailing: ElevatedButton.icon(
                    onPressed: _sendTestTelemetry,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hardware & Sensor Spec Info
          _buildCard(
            isDark: isDark,
            title: 'Hardware & Sensor Stack',
            icon: Icons.memory_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _specItem('Microcontroller', 'ESP32 NodeMCU (Wi-Fi 802.11 b/g/n)'),
                _specItem('CO₂ & Gas Sensor', 'MQ-135 Semiconductor Gas Sensor'),
                _specItem('CO Sensor', 'MQ-7 Carbon Monoxide Sensor'),
                _specItem('NO₂ Detection', 'Calibrated Differential Electrochemical Sensor'),
                _specItem('Climate Sensor', 'DHT11 / DHT22 (Temp ±0.5°C, Hum ±2%)'),
                _specItem('Cloud Backend', 'Node.js Express + MongoDB Atlas on Render'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _specItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
