import 'package:flutter/foundation.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

/// Provider for analytics data and business intelligence
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ConnectivityService _connectivity = ConnectivityService();

  // State variables
  SalesMetrics? _salesMetrics;
  InventoryMetrics? _inventoryMetrics;
  FinancialMetrics? _financialMetrics;
  List<PredictiveAnalysis> _predictiveAnalyses = [];
  List<StockAlert> _activeAlerts = [];

  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefresh;

  // Filter settings
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedLocationId;

  // Getters
  SalesMetrics? get salesMetrics => _salesMetrics;
  InventoryMetrics? get inventoryMetrics => _inventoryMetrics;
  FinancialMetrics? get financialMetrics => _financialMetrics;
  List<PredictiveAnalysis> get predictiveAnalyses => _predictiveAnalyses;
  List<StockAlert> get activeAlerts => _activeAlerts;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String? get selectedLocationId => _selectedLocationId;

  // Quick metrics getters
  double get totalRevenue => _salesMetrics?.totalRevenue ?? 0;
  int get totalOrders => _salesMetrics?.totalOrders ?? 0;
  double get averageOrderValue => _salesMetrics?.averageOrderValue ?? 0;
  double get growthRate => _salesMetrics?.growthRate ?? 0;
  int get totalProducts => _inventoryMetrics?.totalProducts ?? 0;
  double get inventoryValue => _inventoryMetrics?.totalInventoryValue ?? 0;
  int get lowStockCount => _inventoryMetrics?.lowStockProducts ?? 0;
  int get outOfStockCount => _inventoryMetrics?.outOfStockProducts ?? 0;
  double get profitMargin => _financialMetrics?.profitMargin ?? 0;
  double get netProfit => _financialMetrics?.netProfit ?? 0;

  // Critical alerts (high and critical severity)
  List<StockAlert> get criticalAlerts => 
    _activeAlerts.where((alert) => 
      alert.severity == AlertSeverity.critical || 
      alert.severity == AlertSeverity.high
    ).toList();

  // Recent recommendations
  List<Recommendation> get recentRecommendations {
    final allRecommendations = _predictiveAnalyses
        .expand((analysis) => analysis.recommendations)
        .toList();
    
    // Sort by impact and take top 5
    allRecommendations.sort((a, b) => b.impact.compareTo(a.impact));
    return allRecommendations.take(5).toList();
  }

  /// Initialize analytics provider
  Future<void> initialize() async {
    await refreshAllMetrics();
    _setupConnectivityListener();
  }

  /// Refresh all analytics data
  Future<void> refreshAllMetrics() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('Refreshing all analytics metrics');

      // Fetch all metrics in parallel
      final futures = await Future.wait([
        _fetchSalesMetrics(),
        _fetchInventoryMetrics(),
        _fetchFinancialMetrics(),
      ]);

      // Update active alerts from inventory metrics
      _updateActiveAlerts();

      _lastRefresh = DateTime.now();
      AppLogger.info('Analytics metrics refreshed successfully');
    } catch (e) {
      _setError('Failed to refresh analytics: ${e.toString()}');
      AppLogger.error('Failed to refresh analytics metrics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch sales metrics
  Future<void> _fetchSalesMetrics() async {
    try {
      _salesMetrics = await _analyticsService.getSalesMetrics(
        startDate: _startDate,
        endDate: _endDate,
        locationId: _selectedLocationId,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to fetch sales metrics: $e');
      _salesMetrics = SalesMetrics.empty();
    }
  }

  /// Fetch inventory metrics
  Future<void> _fetchInventoryMetrics() async {
    try {
      _inventoryMetrics = await _analyticsService.getInventoryMetrics(
        locationId: _selectedLocationId,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to fetch inventory metrics: $e');
      _inventoryMetrics = InventoryMetrics.empty();
    }
  }

  /// Fetch financial metrics
  Future<void> _fetchFinancialMetrics() async {
    try {
      _financialMetrics = await _analyticsService.getFinancialMetrics(
        startDate: _startDate,
        endDate: _endDate,
        locationId: _selectedLocationId,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to fetch financial metrics: $e');
      _financialMetrics = FinancialMetrics.empty();
    }
  }

  /// Generate predictive analysis
  Future<void> generatePredictiveAnalysis({
    required String type,
    String? productId,
  }) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('Generating predictive analysis: $type');

      final analysis = await _analyticsService.generatePredictiveAnalysis(
        type: type,
        productId: productId,
        locationId: _selectedLocationId,
      );

      // Add to existing analyses (keep recent ones)
      _predictiveAnalyses.add(analysis);
      
      // Keep only last 10 analyses
      if (_predictiveAnalyses.length > 10) {
        _predictiveAnalyses = _predictiveAnalyses.sublist(_predictiveAnalyses.length - 10);
      }

      // Sort by generation date (newest first)
      _predictiveAnalyses.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      // Track the analytics event
      await _analyticsService.trackAnalyticsEvent(
        type: 'predictive_analysis_generated',
        data: {
          'analysis_type': type,
          'confidence': analysis.confidence,
          'recommendations_count': analysis.recommendations.length,
        },
      );

      notifyListeners();
      AppLogger.info('Predictive analysis generated successfully');
    } catch (e) {
      _setError('Failed to generate analysis: ${e.toString()}');
      AppLogger.error('Failed to generate predictive analysis: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update date range filter
  void updateDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      _setError('Start date cannot be after end date');
      return;
    }

    _startDate = startDate;
    _endDate = endDate;
    _clearError();
    
    // Auto-refresh metrics with new date range
    refreshAllMetrics();
  }

  /// Update location filter
  void updateLocationFilter(String? locationId) {
    _selectedLocationId = locationId;
    _clearError();
    
    // Auto-refresh metrics with new location filter
    refreshAllMetrics();
  }

  /// Clear all filters and refresh
  void clearFilters() {
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _selectedLocationId = null;
    _clearError();
    
    refreshAllMetrics();
  }

  /// Get performance summary for dashboard
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'revenue': {
        'current': totalRevenue,
        'growth': growthRate,
        'trend': growthRate > 0 ? 'up' : growthRate < 0 ? 'down' : 'stable',
      },
      'orders': {
        'total': totalOrders,
        'average_value': averageOrderValue,
      },
      'inventory': {
        'total_value': inventoryValue,
        'total_products': totalProducts,
        'low_stock': lowStockCount,
        'out_of_stock': outOfStockCount,
        'turnover_rate': _inventoryMetrics?.turnoverRate ?? 0,
      },
      'financial': {
        'profit_margin': profitMargin,
        'net_profit': netProfit,
        'expenses': _financialMetrics?.totalExpenses ?? 0,
      },
      'alerts': {
        'total': _activeAlerts.length,
        'critical': criticalAlerts.length,
      },
    };
  }

  /// Export analytics data for reporting
  Map<String, dynamic> exportAnalyticsData() {
    return {
      'generated_at': DateTime.now().toIso8601String(),
      'date_range': {
        'start': _startDate.toIso8601String(),
        'end': _endDate.toIso8601String(),
      },
      'location_id': _selectedLocationId,
      'sales_metrics': _salesMetrics != null ? {
        'total_revenue': _salesMetrics!.totalRevenue,
        'total_orders': _salesMetrics!.totalOrders,
        'average_order_value': _salesMetrics!.averageOrderValue,
        'total_customers': _salesMetrics!.totalCustomers,
        'growth_rate': _salesMetrics!.growthRate,
        'daily_sales': _salesMetrics!.dailySales.map((ds) => {
          'date': ds.date.toIso8601String(),
          'revenue': ds.revenue,
          'order_count': ds.orderCount,
        }).toList(),
        'top_products': _salesMetrics!.topProducts.map((tp) => {
          'product_id': tp.productId,
          'product_name': tp.productName,
          'units_sold': tp.unitsSold,
          'revenue': tp.revenue,
          'profit_margin': tp.profitMargin,
        }).toList(),
      } : null,
      'inventory_metrics': _inventoryMetrics != null ? {
        'total_products': _inventoryMetrics!.totalProducts,
        'total_value': _inventoryMetrics!.totalInventoryValue,
        'low_stock_products': _inventoryMetrics!.lowStockProducts,
        'out_of_stock_products': _inventoryMetrics!.outOfStockProducts,
        'turnover_rate': _inventoryMetrics!.turnoverRate,
      } : null,
      'financial_metrics': _financialMetrics != null ? {
        'total_revenue': _financialMetrics!.totalRevenue,
        'total_expenses': _financialMetrics!.totalExpenses,
        'gross_profit': _financialMetrics!.grossProfit,
        'net_profit': _financialMetrics!.netProfit,
        'profit_margin': _financialMetrics!.profitMargin,
        'expense_breakdown': _financialMetrics!.expenseBreakdown,
      } : null,
      'active_alerts': _activeAlerts.map((alert) => {
        'product_id': alert.productId,
        'product_name': alert.productName,
        'current_stock': alert.currentStock,
        'minimum_stock': alert.minimumStock,
        'severity': alert.severity.toString(),
      }).toList(),
      'recent_recommendations': recentRecommendations.map((rec) => {
        'id': rec.id,
        'title': rec.title,
        'description': rec.description,
        'type': rec.type.toString(),
        'impact': rec.impact,
        'action_required': rec.actionRequired,
      }).toList(),
    };
  }

  /// Track user analytics event
  Future<void> trackEvent(String eventType, Map<String, dynamic> eventData) async {
    try {
      await _analyticsService.trackAnalyticsEvent(
        type: eventType,
        data: eventData,
        locationId: _selectedLocationId,
      );
    } catch (e) {
      AppLogger.error('Failed to track analytics event: $e');
    }
  }

  // Private helper methods
  void _updateActiveAlerts() {
    _activeAlerts = _inventoryMetrics?.stockAlerts ?? [];
  }

  void _setupConnectivityListener() {
    // Auto-refresh when connectivity changes
    // Note: ConnectivityService callback system needs to be implemented
    // For now, we'll skip this setup
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    AppLogger.error('AnalyticsProvider error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any subscriptions or resources
    super.dispose();
  }
}