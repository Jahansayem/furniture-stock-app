import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;

  bool _isOnline = true;
  bool _isInitialized = false;
  List<VoidCallback> _onlineCallbacks = [];
  List<VoidCallback> _offlineCallbacks = [];

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity status
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) => _updateConnectionStatus(result),
        onError: (error) {
          print('❌ Connectivity stream error: $error');
        },
      );

      _isInitialized = true;
      print('✅ Connectivity service initialized');
    } catch (e) {
      print('❌ Error initializing connectivity service: $e');
      // Assume online if we can't check
      _isOnline = true;
      _isInitialized = true;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;

    // Check if the result indicates connectivity
    _isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    print('🌐 Connectivity status: ${_isOnline ? "Online" : "Offline"}');

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      notifyListeners();

      // Execute callbacks
      if (_isOnline) {
        for (final callback in _onlineCallbacks) {
          try {
            callback();
          } catch (e) {
            print('❌ Error in online callback: $e');
          }
        }
      } else {
        for (final callback in _offlineCallbacks) {
          try {
            callback();
          } catch (e) {
            print('❌ Error in offline callback: $e');
          }
        }
      }
    }
  }

  /// Add callback to be executed when device comes online
  void addOnlineCallback(VoidCallback callback) {
    _onlineCallbacks.add(callback);
  }

  /// Add callback to be executed when device goes offline
  void addOfflineCallback(VoidCallback callback) {
    _offlineCallbacks.add(callback);
  }

  /// Remove online callback
  void removeOnlineCallback(VoidCallback callback) {
    _onlineCallbacks.remove(callback);
  }

  /// Remove offline callback
  void removeOfflineCallback(VoidCallback callback) {
    _offlineCallbacks.remove(callback);
  }

  /// Clear all callbacks
  void clearCallbacks() {
    _onlineCallbacks.clear();
    _offlineCallbacks.clear();
  }

  /// Force check connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return _isOnline; // Return current status if check fails
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    clearCallbacks();
    super.dispose();
  }

  /// Get detailed connectivity information
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.wifi) {
        return 'WiFi';
      } else if (result == ConnectivityResult.mobile) {
        return 'Mobile Data';
      } else if (result == ConnectivityResult.ethernet) {
        return 'Ethernet';
      } else {
        return 'No Connection';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
