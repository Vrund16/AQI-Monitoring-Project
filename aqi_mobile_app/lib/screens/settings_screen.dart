import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _urlController = TextEditingController(text: aqi.apiUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final endpoint = ApiService.formatLatestEndpoint(_urlController.text);
      _urlController.text = endpoint;
      final res = await _apiService.checkHealth(endpoint: endpoint);
      stopwatch.stop();
      if (!mounted) return;
      setState(() => _pingResult = {
            ...res,
            'latency': '${stopwatch.elapsedMilliseconds}ms',
          });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() => _pingResult = {
            'status': 'error',
            'message': e.toString().replaceFirst('Exception: ', ''),
            'latency': '${stopwatch.elapsedMilliseconds}ms',
          });
    } finally {
      if (mounted) setState(() => _isPinging = false);
    }
  }

  Future<void> _saveApiUrl() async {
    final aqi = context.read<AqiProvider>();
    try {
      final endpoint = ApiService.formatLatestEndpoint(_urlController.text);
      _urlController.text = endpoint;
      await aqi.updateApiUrl(endpoint);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live readings API updated.')),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save the API URL: $error')),
        );
      }
    }
  }

  Future<void> _resetApiUrl() async {
    _urlController.text = ApiService.defaultApiUrl;
    await _saveApiUrl();
  }

  @override
  Widget build(BuildContext context) {
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
                    labelText: 'Readings API URL',
                    hintText: ApiService.defaultApiUrl,
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981)),
                      onPressed: _saveApiUrl,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _resetApiUrl,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Use shared Render API'),
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.speed_rounded),
                    label: Text(_isPinging
                        ? 'Pinging Server...'
                        : 'Test Connection & Server Health'),
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
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
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

          // Section: App Preferences
          _buildCard(
            isDark: isDark,
            title: 'Preferences & Modes',
            icon: Icons.tune_rounded,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Toggle between sleek dark & bright theme',
                      style: TextStyle(fontSize: 11)),
                  value: theme.isDarkMode,
                  onChanged: (val) => theme.toggleTheme(),
                  activeColor: const Color(0xFF10B981),
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
                _specItem(
                    'Microcontroller', 'ESP32 NodeMCU (Wi-Fi 802.11 b/g/n)'),
                _specItem(
                    'CO₂ & Gas Sensor', 'MQ-135 Semiconductor Gas Sensor'),
                _specItem('CO Sensor', 'MQ-7 Carbon Monoxide Sensor'),
                _specItem('NO₂ Detection',
                    'Calibrated Differential Electrochemical Sensor'),
                _specItem(
                    'Climate Sensor', 'DHT11 / DHT22 (Temp ±0.5°C, Hum ±2%)'),
                _specItem('Cloud Backend',
                    'Node.js Express + MongoDB Atlas on Render'),
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
          Text('• $label: ',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
