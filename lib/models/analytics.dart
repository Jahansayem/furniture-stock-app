
/// Analytics model for business intelligence data
class AnalyticsData {
  final String id;
  final String type;
  final DateTime date;
  final Map<String, dynamic> data;
  final String? userId;
  final String? locationId;

  const AnalyticsData({
    required this.id,
    required this.type,
    required this.date,
    required this.data,
    this.userId,
    this.locationId,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      id: json['id'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      data: json['data'] ?? {},
      userId: json['user_id'],
      locationId: json['location_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'data': data,
      'user_id': userId,
      'location_id': locationId,
    };
  }
}

/// Sales metrics for analytics
class SalesMetrics {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int totalCustomers;
  final double growthRate;
  final List<DailySales> dailySales;
  final List<TopProduct> topProducts;
  final List<SalesRepPerformance> repPerformance;

  const SalesMetrics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalCustomers,
    required this.growthRate,
    required this.dailySales,
    required this.topProducts,
    required this.repPerformance,
  });

  factory SalesMetrics.empty() {
    return const SalesMetrics(
      totalRevenue: 0,
      totalOrders: 0,
      averageOrderValue: 0,
      totalCustomers: 0,
      growthRate: 0,
      dailySales: [],
      topProducts: [],
      repPerformance: [],
    );
  }
}

/// Daily sales data point
class DailySales {
  final DateTime date;
  final double revenue;
  final int orderCount;

  const DailySales({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date']),
      revenue: (json['revenue'] ?? 0).toDouble(),
      orderCount: json['order_count'] ?? 0,
    );
  }
}

/// Top performing products
class TopProduct {
  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;
  final double profitMargin;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
    required this.profitMargin,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['product_id'],
      productName: json['product_name'],
      unitsSold: json['units_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      profitMargin: (json['profit_margin'] ?? 0).toDouble(),
    );
  }
}

/// Sales representative performance
class SalesRepPerformance {
  final String repId;
  final String repName;
  final double totalSales;
  final int ordersCompleted;
  final double conversionRate;
  final double averageOrderValue;

  const SalesRepPerformance({
    required this.repId,
    required this.repName,
    required this.totalSales,
    required this.ordersCompleted,
    required this.conversionRate,
    required this.averageOrderValue,
  });

  factory SalesRepPerformance.fromJson(Map<String, dynamic> json) {
    return SalesRepPerformance(
      repId: json['rep_id'],
      repName: json['rep_name'],
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      ordersCompleted: json['orders_completed'] ?? 0,
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
    );
  }
}

/// Inventory analytics
class InventoryMetrics {
  final int totalProducts;
  final double totalInventoryValue;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double turnoverRate;
  final List<StockAlert> stockAlerts;
  final List<InventoryTrend> trends;

  const InventoryMetrics({
    required this.totalProducts,
    required this.totalInventoryValue,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.turnoverRate,
    required this.stockAlerts,
    required this.trends,
  });

  factory InventoryMetrics.empty() {
    return const InventoryMetrics(
      totalProducts: 0,
      totalInventoryValue: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
      turnoverRate: 0,
      stockAlerts: [],
      trends: [],
    );
  }
}

/// Stock alert for low inventory
class StockAlert {
  final String productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final AlertSeverity severity;

  const StockAlert({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.severity,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      productId: json['product_id'],
      productName: json['product_name'],
      currentStock: json['current_stock'] ?? 0,
      minimumStock: json['minimum_stock'] ?? 0,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${json['severity']}',
        orElse: () => AlertSeverity.medium,
      ),
    );
  }
}

/// Inventory trend data
class InventoryTrend {
  final DateTime date;
  final double value;
  final int stockLevel;

  const InventoryTrend({
    required this.date,
    required this.value,
    required this.stockLevel,
  });

  factory InventoryTrend.fromJson(Map<String, dynamic> json) {
    return InventoryTrend(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toDouble(),
      stockLevel: json['stock_level'] ?? 0,
    );
  }
}

/// Predictive analytics result
class PredictiveAnalysis {
  final String analysisId;
  final String type;
  final DateTime generatedAt;
  final Map<String, dynamic> predictions;
  final double confidence;
  final List<Recommendation> recommendations;

  const PredictiveAnalysis({
    required this.analysisId,
    required this.type,
    required this.generatedAt,
    required this.predictions,
    required this.confidence,
    required this.recommendations,
  });

  factory PredictiveAnalysis.fromJson(Map<String, dynamic> json) {
    return PredictiveAnalysis(
      analysisId: json['analysis_id'],
      type: json['type'],
      generatedAt: DateTime.parse(json['generated_at']),
      predictions: json['predictions'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      recommendations: (json['recommendations'] as List?)
          ?.map((r) => Recommendation.fromJson(r))
          .toList() ?? [],
    );
  }
}

/// Business recommendation
class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final double impact;
  final String actionRequired;

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.actionRequired,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: RecommendationType.values.firstWhere(
        (e) => e.toString() == 'RecommendationType.${json['type']}',
        orElse: () => RecommendationType.optimization,
      ),
      impact: (json['impact'] ?? 0).toDouble(),
      actionRequired: json['action_required'] ?? '',
    );
  }
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Recommendation types
enum RecommendationType {
  inventory,
  sales,
  pricing,
  marketing,
  optimization,
  risk,
}

/// Financial metrics for reporting
class FinancialMetrics {
  final double totalRevenue;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final double profitMargin;
  final double costOfGoodsSold;
  final double operatingExpenses;
  final Map<String, double> expenseBreakdown;

  const FinancialMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.costOfGoodsSold,
    required this.operatingExpenses,
    required this.expenseBreakdown,
  });

  factory FinancialMetrics.empty() {
    return const FinancialMetrics(
      totalRevenue: 0,
      totalExpenses: 0,
      grossProfit: 0,
      netProfit: 0,
      profitMargin: 0,
      costOfGoodsSold: 0,
      operatingExpenses: 0,
      expenseBreakdown: {},
    );
  }
}