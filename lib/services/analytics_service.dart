import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Future<Map<String, dynamic>> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get sales analytics
      final salesResponse = await _supabase
          .from('sales')
          .select('*')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      // Get stock analytics
      final stockResponse = await _supabase
          .from('stocks')
          .select('*');

      // Calculate analytics
      double totalRevenue = 0;
      int totalSales = 0;
      int totalStock = 0;

      if (salesResponse != null) {
        totalSales = salesResponse.length;
        for (var sale in salesResponse) {
          totalRevenue += (sale['price'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (stockResponse != null) {
        totalStock = stockResponse.length;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalSales': totalSales,
        'totalStock': totalStock,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to get analytics data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSalesAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _supabase
          .from('sales')
          .select('*')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw Exception('Failed to get sales analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getStockAnalytics() async {
    try {
      final response = await _supabase
          .from('stocks')
          .select('*, products(name, category)');

      if (response == null) return {};

      // Group by category
      Map<String, int> categoryStock = {};
      int totalStock = 0;
      int lowStockItems = 0;

      for (var stock in response) {
        final quantity = (stock['quantity'] as num?)?.toInt() ?? 0;
        final category = stock['products']?['category'] ?? 'Unknown';

        totalStock += quantity;
        categoryStock[category] = (categoryStock[category] ?? 0) + quantity;

        if (quantity < 10) {
          lowStockItems++;
        }
      }

      return {
        'totalStock': totalStock,
        'lowStockItems': lowStockItems,
        'categoryBreakdown': categoryStock,
      };
    } catch (e) {
      throw Exception('Failed to get stock analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getSalesMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getSalesAnalytics(startDate: startDate, endDate: endDate);
  }

  Future<Map<String, dynamic>> getInventoryMetrics() async {
    return await getStockAnalytics();
  }

  Future<Map<String, dynamic>> getFinancialMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getAnalyticsData(startDate: startDate, endDate: endDate);
  }

  Future<List<Map<String, dynamic>>> generatePredictiveAnalysis() async {
    // Simple predictive analysis - return empty for now
    return [];
  }

  Future<void> trackAnalyticsEvent(String event, Map<String, dynamic> data) async {
    // Track analytics event - placeholder implementation
    // In a real app, this would send to analytics service
  }
}