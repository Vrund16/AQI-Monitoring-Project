import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_reading.dart';
import '../services/api_service.dart';

enum ConnectionStateStatus {
  initial,
  connecting,
  connected,
  error,
}

class AqiProvider extends ChangeNotifier {
  static const int _pollIntervalSeconds = 5;

  final ApiService _apiService = ApiService();

  SensorReading? _latestReading;
  List<SensorReading> _history = [];
  ConnectionStateStatus _status = ConnectionStateStatus.initial;
  String? _errorMessage;

  bool _isPollingActive = true;
  int _countdown = _pollIntervalSeconds;
  String _apiUrl = ApiService.defaultApiUrl;
  bool _isFetching = false;

  Timer? _countdownTimer;
  DateTime? _lastSyncedTime;

  SensorReading? get latestReading => _latestReading;
  List<SensorReading> get history => _history;
  ConnectionStateStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isPollingActive => _isPollingActive;
  int get pollIntervalSeconds => _pollIntervalSeconds;
  int get countdown => _countdown;
  String get apiUrl => _apiUrl;
  DateTime? get lastSyncedTime => _lastSyncedTime;

  AqiProvider() {
    _initSettings();
  }

  Future<void> _initSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl =
          prefs.getString('api_url') ?? prefs.getString('api_base_url');
      _apiUrl = ApiService.formatLatestEndpoint(
        savedUrl ?? ApiService.defaultApiUrl,
      );
      if (prefs.getString('api_url') == null) {
        await prefs.setString('api_url', _apiUrl);
      }
      await prefs.remove('api_base_url');
      await prefs.remove('force_mock');
      await prefs.remove('poll_interval');
    } catch (e) {
      debugPrint('Preferences init error: $e');
    }

    // Initial fetch and start polling loop
    await refreshData();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (!_isPollingActive) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        _countdown = _pollIntervalSeconds;
        notifyListeners();
        _fetchTelemetry();
      } else {
        _countdown--;
        notifyListeners();
      }
    });
  }

  void togglePolling() {
    _isPollingActive = !_isPollingActive;
    if (_isPollingActive) {
      _countdown = _pollIntervalSeconds;
      _startTimer();
      _fetchTelemetry();
    } else {
      _countdownTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> updateApiUrl(String newUrl) async {
    final endpoint = ApiService.formatLatestEndpoint(newUrl);
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('api_url', endpoint);
    if (!saved) throw StateError('Could not save the readings API URL.');
    _apiUrl = endpoint;
    await refreshData();
  }

  Future<void> refreshData() async {
    if (_latestReading == null) {
      _status = ConnectionStateStatus.connecting;
    }
    notifyListeners();
    await _fetchTelemetry();
    if (_status == ConnectionStateStatus.connected) {
      await _fetchHistory();
    }
  }

  Future<void> _fetchTelemetry() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final reading = await _apiService.fetchLatestReading(endpoint: _apiUrl);
      _latestReading = reading;
      _status = ConnectionStateStatus.connected;
      _lastSyncedTime = DateTime.now();
      _errorMessage = null;
      _addToHistory(reading);
    } catch (e) {
      debugPrint('Telemetry fetch error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ConnectionStateStatus.error;
    } finally {
      _isFetching = false;
    }
    notifyListeners();
  }

  Future<void> _fetchHistory() async {
    try {
      final list = await _apiService.fetchHistory(limit: 20, endpoint: _apiUrl);
      if (list.isNotEmpty) {
        // Sort chronologically ascending for charts
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _history = list;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('History fetch error: $e');
    }
  }

  void _addToHistory(SensorReading reading) {
    if (_history.isEmpty || _history.last.timestamp != reading.timestamp) {
      _history.add(reading);
      if (_history.length > 30) {
        _history.removeAt(0);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _apiService.close();
    super.dispose();
  }
}
