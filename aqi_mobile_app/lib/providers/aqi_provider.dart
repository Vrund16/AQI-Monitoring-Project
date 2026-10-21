import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_reading.dart';
import '../services/api_service.dart';

enum ConnectionStateStatus {
  initial,
  connecting,
  connected,
  mock,
  error,
}

class AqiProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  SensorReading? _latestReading;
  List<SensorReading> _history = [];
  ConnectionStateStatus _status = ConnectionStateStatus.initial;
  String? _errorMessage;

  bool _isPollingActive = true;
  int _pollIntervalSeconds = 5;
  int _countdown = 5;
  String _baseUrl = ApiService.defaultBaseUrl;
  bool _forceMock = false;

  Timer? _countdownTimer;
  DateTime? _lastSyncedTime;

  SensorReading? get latestReading => _latestReading;
  List<SensorReading> get history => _history;
  ConnectionStateStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isPollingActive => _isPollingActive;
  int get pollIntervalSeconds => _pollIntervalSeconds;
  int get countdown => _countdown;
  String get baseUrl => _baseUrl;
  bool get forceMock => _forceMock;
  DateTime? get lastSyncedTime => _lastSyncedTime;

  AqiProvider() {
    _initSettings();
  }

  Future<void> _initSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('api_base_url') ?? ApiService.defaultBaseUrl;
      _pollIntervalSeconds = prefs.getInt('poll_interval') ?? 5;
      _countdown = _pollIntervalSeconds;
      _forceMock = prefs.getBool('force_mock') ?? false;
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

  Future<void> setPollingInterval(int seconds) async {
    _pollIntervalSeconds = seconds;
    _countdown = seconds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('poll_interval', seconds);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setForceMock(bool mock) async {
    _forceMock = mock;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('force_mock', mock);
    } catch (_) {}
    refreshData();
  }

  Future<void> updateBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', _baseUrl);
    } catch (_) {}
    await refreshData();
  }

  Future<void> refreshData() async {
    _status = ConnectionStateStatus.connecting;
    notifyListeners();
    await _fetchTelemetry();
    await _fetchHistory();
  }

  Future<void> _fetchTelemetry() async {
    if (_forceMock) {
      _status = ConnectionStateStatus.mock;
      _latestReading = ApiService.generateMockReading(_latestReading);
      _addToHistory(_latestReading!);
      _lastSyncedTime = DateTime.now();
      _errorMessage = null;
      notifyListeners();
      return;
    }

    try {
      final reading = await _apiService.fetchLatestReading(baseUrl: _baseUrl);
      _latestReading = reading;
      _status = ConnectionStateStatus.connected;
      _lastSyncedTime = DateTime.now();
      _errorMessage = null;
      _addToHistory(reading);
    } catch (e) {
      debugPrint('Telemetry fetch error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ConnectionStateStatus.error;

      // If we don't have any reading yet, provide mock fallback with offline warning
      _latestReading ??= ApiService.generateMockReading();
    }
    notifyListeners();
  }

  Future<void> _fetchHistory() async {
    if (_forceMock) return;

    try {
      final list = await _apiService.fetchHistory(limit: 20, baseUrl: _baseUrl);
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

  void ingestCustomReading(SensorReading reading) {
    _latestReading = reading;
    _status = ConnectionStateStatus.mock;
    _addToHistory(reading);
    _lastSyncedTime = DateTime.now();
    notifyListeners();
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
    super.dispose();
  }
}
