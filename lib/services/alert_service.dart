import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

/// Automated alert and notification service
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();
  final ConnectivityService _connectivity = ConnectivityService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Timer? _alertTimer;
  bool _isInitialized = false;
  List<BusinessAlert> _activeAlerts = [];
  
  // Alert thresholds and settings
  final Map<AlertType, AlertThreshold> _alertThresholds = {
    AlertType.lowStock: AlertThreshold(
      enabled: true,
      threshold: 10.0,
      frequency: AlertFrequency.immediate,
      priority: AlertPriority.high,
    ),
    AlertType.outOfStock: AlertThreshold(
      enabled: true,
      threshold: 0.0,
      frequency: AlertFrequency.immediate,
      priority: AlertPriority.critical,
    ),
    AlertType.highSales: AlertThreshold(
      enabled: true,
      threshold: 100000.0, // Revenue threshold
      frequency: AlertFrequency.daily,
      priority: AlertPriority.medium,
    ),
    AlertType.lowSales: AlertThreshold(
      enabled: true,
      threshold: 10000.0, // Low revenue threshold
      frequency: AlertFrequency.daily,
      priority: AlertPriority.medium,
    ),
    AlertType.profitAlert: AlertThreshold(
      enabled: true,
      threshold: 5.0, // Profit margin percentage
      frequency: AlertFrequency.weekly,
      priority: AlertPriority.high,
    ),
    AlertType.cashFlow: AlertThreshold(
      enabled: true,
      threshold: -50000.0, // Negative cash flow
      frequency: AlertFrequency.daily,
      priority: AlertPriority.critical,
    ),
    AlertType.systemAlert: AlertThreshold(
      enabled: true,
      threshold: 0.0,
      frequency: AlertFrequency.immediate,
      priority: AlertPriority.low,
    ),
  };

  List<BusinessAlert> get activeAlerts => _activeAlerts;

  /// Initialize the alert service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('Initializing Alert Service');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Start periodic alert monitoring
      _startAlertMonitoring();
      
      _isInitialized = true;
      AppLogger.info('Alert Service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize Alert Service: $e');
    }
  }

  /// Start automated alert monitoring
  void _startAlertMonitoring() {
    // Run alert checks every 5 minutes
    _alertTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performAlertChecks();
    });
    
    // Perform initial check
    _performAlertChecks();
  }

  /// Perform comprehensive alert checks
  Future<void> _performAlertChecks() async {
    if (!_connectivity.isOnline) {
      AppLogger.info('Skipping alert checks - offline');
      return;
    }

    try {
      AppLogger.info('Performing alert checks');
      
      final futures = <Future<void>>[
        _checkInventoryAlerts(),
        _checkSalesAlerts(),
        _checkFinancialAlerts(),
        _checkSystemAlerts(),
      ];
      
      await Future.wait(futures);
      
      // Clean up expired alerts
      _cleanupExpiredAlerts();
      
      AppLogger.info('Alert checks completed');
    } catch (e) {
      AppLogger.error('Failed to perform alert checks: $e');
    }
  }

  /// Check inventory-related alerts
  Future<void> _checkInventoryAlerts() async {
    try {
      final inventoryMetrics = await _analyticsService.getInventoryMetrics();
      
      // Check for stock alerts
      for (final stockAlert in inventoryMetrics.stockAlerts) {
        if (stockAlert.severity == AlertSeverity.critical || 
            stockAlert.severity == AlertSeverity.high) {
          
          final alertType = stockAlert.currentStock <= 0 ? AlertType.outOfStock : AlertType.lowStock;
          
          await _createAlert(
            type: alertType,
            title: alertType == AlertType.outOfStock ? 'Product Out of Stock' : 'Low Stock Alert',
            message: '${stockAlert.productName} - ${stockAlert.currentStock} units remaining',
            data: {
              'product_id': stockAlert.productId,
              'product_name': stockAlert.productName,
              'current_stock': stockAlert.currentStock,
              'minimum_stock': stockAlert.minimumStock,
              'severity': stockAlert.severity.name,
            },
            priority: _mapSeverityToPriority(stockAlert.severity),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to check inventory alerts: $e');
    }
  }

  /// Check sales-related alerts  
  Future<void> _checkSalesAlerts() async {
    try {
      final salesMetrics = await _analyticsService.getSalesMetrics(
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now(),
      );
      
      final dailyRevenue = salesMetrics.totalRevenue;
      final highSalesThreshold = _alertThresholds[AlertType.highSales]!.threshold;
      final lowSalesThreshold = _alertThresholds[AlertType.lowSales]!.threshold;
      
      // High sales achievement alert
      if (dailyRevenue > highSalesThreshold && 
          _alertThresholds[AlertType.highSales]!.enabled) {
        await _createAlert(
          type: AlertType.highSales,
          title: 'High Sales Achievement!',
          message: 'Daily revenue reached ৳${dailyRevenue.toStringAsFixed(0)}',
          data: {
            'revenue': dailyRevenue,
            'threshold': highSalesThreshold,
            'date': DateTime.now().toIso8601String(),
          },
          priority: AlertPriority.medium,
        );
      }
      
      // Low sales warning alert
      if (dailyRevenue < lowSalesThreshold && 
          _alertThresholds[AlertType.lowSales]!.enabled) {
        await _createAlert(
          type: AlertType.lowSales,
          title: 'Low Sales Warning',
          message: 'Daily revenue only ৳${dailyRevenue.toStringAsFixed(0)} - below target',
          data: {
            'revenue': dailyRevenue,
            'threshold': lowSalesThreshold,
            'date': DateTime.now().toIso8601String(),
          },
          priority: AlertPriority.medium,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to check sales alerts: $e');
    }
  }

  /// Check financial alerts
  Future<void> _checkFinancialAlerts() async {
    try {
      final financialMetrics = await _analyticsService.getFinancialMetrics(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );
      
      // Profit margin alert
      final profitThreshold = _alertThresholds[AlertType.profitAlert]!.threshold;
      if (financialMetrics.profitMargin < profitThreshold && 
          _alertThresholds[AlertType.profitAlert]!.enabled) {
        await _createAlert(
          type: AlertType.profitAlert,
          title: 'Low Profit Margin Alert',
          message: 'Profit margin is ${financialMetrics.profitMargin.toStringAsFixed(1)}% - below target',
          data: {
            'profit_margin': financialMetrics.profitMargin,
            'threshold': profitThreshold,
            'net_profit': financialMetrics.netProfit,
          },
          priority: AlertPriority.high,
        );
      }
      
      // Cash flow alert
      final cashFlowThreshold = _alertThresholds[AlertType.cashFlow]!.threshold;
      if (financialMetrics.netProfit < cashFlowThreshold && 
          _alertThresholds[AlertType.cashFlow]!.enabled) {
        await _createAlert(
          type: AlertType.cashFlow,
          title: 'Cash Flow Warning',
          message: 'Negative cash flow detected: ৳${financialMetrics.netProfit.toStringAsFixed(0)}',
          data: {
            'net_profit': financialMetrics.netProfit,
            'threshold': cashFlowThreshold,
            'total_expenses': financialMetrics.totalExpenses,
          },
          priority: AlertPriority.critical,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to check financial alerts: $e');
    }
  }

  /// Check system alerts
  Future<void> _checkSystemAlerts() async {
    try {
      // Check connectivity issues
      if (!_connectivity.isOnline) {
        await _createAlert(
          type: AlertType.systemAlert,
          title: 'Connectivity Issue',
          message: 'App is offline - some features may be limited',
          data: {
            'connectivity_status': 'offline',
            'timestamp': DateTime.now().toIso8601String(),
          },
          priority: AlertPriority.low,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to check system alerts: $e');
    }
  }

  /// Create a new business alert
  Future<void> _createAlert({
    required AlertType type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
    required AlertPriority priority,
  }) async {
    try {
      // Check if similar alert already exists (prevent spam)
      final existingAlert = _activeAlerts.where((alert) => 
        alert.type == type && 
        alert.title == title &&
        DateTime.now().difference(alert.createdAt).inMinutes < 30 // 30-minute cooldown
      ).firstOrNull;
      
      if (existingAlert != null) {
        AppLogger.info('Similar alert already exists, skipping: $title');
        return;
      }
      
      final alert = BusinessAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        priority: priority,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
        isActive: true,
      );
      
      _activeAlerts.add(alert);
      
      // Send local notification
      await _sendLocalNotification(alert);
      
      // Track alert creation
      await _analyticsService.trackAnalyticsEvent(
        type: 'alert_created',
        data: {
          'alert_type': type.name,
          'priority': priority.name,
          'title': title,
        },
      );
      
      AppLogger.info('Created alert: $title');
    } catch (e) {
      AppLogger.error('Failed to create alert: $e');
    }
  }

  /// Send local notification
  Future<void> _sendLocalNotification(BusinessAlert alert) async {
    try {
      final notificationId = alert.hashCode;
      
      const androidDetails = AndroidNotificationDetails(
        'business_alerts',
        'Business Alerts',
        channelDescription: 'Important business notifications and alerts',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        notificationId,
        alert.title,
        alert.message,
        notificationDetails,
        payload: alert.id,
      );
    } catch (e) {
      AppLogger.error('Failed to send local notification: $e');
    }
  }

  /// Mark alert as read
  void markAlertAsRead(String alertId) {
    final alertIndex = _activeAlerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _activeAlerts[alertIndex] = _activeAlerts[alertIndex].copyWith(isRead: true);
      AppLogger.info('Marked alert as read: $alertId');
    }
  }

  /// Dismiss alert
  void dismissAlert(String alertId) {
    _activeAlerts.removeWhere((alert) => alert.id == alertId);
    AppLogger.info('Dismissed alert: $alertId');
  }

  /// Get alerts by type
  List<BusinessAlert> getAlertsByType(AlertType type) {
    return _activeAlerts.where((alert) => alert.type == type && alert.isActive).toList();
  }

  /// Get alerts by priority
  List<BusinessAlert> getAlertsByPriority(AlertPriority priority) {
    return _activeAlerts.where((alert) => alert.priority == priority && alert.isActive).toList();
  }

  /// Get unread alerts
  List<BusinessAlert> getUnreadAlerts() {
    return _activeAlerts.where((alert) => !alert.isRead && alert.isActive).toList();
  }

  /// Update alert threshold
  void updateAlertThreshold(AlertType type, AlertThreshold threshold) {
    _alertThresholds[type] = threshold;
    AppLogger.info('Updated alert threshold for ${type.name}');
  }

  /// Get alert threshold
  AlertThreshold? getAlertThreshold(AlertType type) {
    return _alertThresholds[type];
  }

  /// Clean up expired alerts
  void _cleanupExpiredAlerts() {
    final now = DateTime.now();
    _activeAlerts.removeWhere((alert) {
      final age = now.difference(alert.createdAt);
      // Remove alerts older than 7 days
      return age.inDays > 7;
    });
  }

  // Private helper methods
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'business_alerts',
      'Business Alerts',
      description: 'Important business notifications and alerts',
      importance: Importance.high,
    );
    
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final alertId = response.payload;
    if (alertId != null) {
      markAlertAsRead(alertId);
    }
  }

  AlertPriority _mapSeverityToPriority(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AlertPriority.critical;
      case AlertSeverity.high:
        return AlertPriority.high;
      case AlertSeverity.medium:
        return AlertPriority.medium;
      case AlertSeverity.low:
        return AlertPriority.low;
    }
  }

  /// Dispose resources
  void dispose() {
    _alertTimer?.cancel();
  }
}

/// Business alert model
class BusinessAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final bool isActive;

  const BusinessAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.data,
    required this.createdAt,
    required this.isRead,
    required this.isActive,
  });

  BusinessAlert copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? message,
    AlertPriority? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    bool? isActive,
  }) {
    return BusinessAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Alert threshold configuration
class AlertThreshold {
  final bool enabled;
  final double threshold;
  final AlertFrequency frequency;
  final AlertPriority priority;

  const AlertThreshold({
    required this.enabled,
    required this.threshold,
    required this.frequency,
    required this.priority,
  });
}

/// Types of business alerts
enum AlertType {
  lowStock,
  outOfStock,
  highSales,
  lowSales,
  profitAlert,
  cashFlow,
  systemAlert,
}

/// Alert priority levels
enum AlertPriority {
  low,
  medium,
  high,
  critical,
}

/// Alert frequency settings
enum AlertFrequency {
  immediate,
  daily,
  weekly,
  monthly,
}