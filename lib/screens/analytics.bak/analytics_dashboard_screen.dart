import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/analytics.dart';
import '../../utils/app_theme.dart';
import '../../widgets/modern_components.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _tabTitles = [
    'Overview',
    'Sales',
    'Inventory', 
    'Financial',
    'Predictions',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAnalytics();
    });
  }

  Future<void> _initializeAnalytics() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    await analyticsProvider.initialize();
    
    // Track dashboard view
    await analyticsProvider.trackEvent('analytics_dashboard_viewed', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.white),
            SizedBox(width: 8),
            Text('Analytics Dashboard'),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: provider.isLoading ? null : () => _showFilterDialog(provider),
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Data',
              );
            }
          ),
          Consumer<AnalyticsProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: provider.isLoading ? null : () => provider.refreshAllMetrics(),
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
              );
            }
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            return _buildErrorView(provider);
          }

          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            children: [
              _buildOverviewTab(provider),
              _buildSalesTab(provider),
              _buildInventoryTab(provider),
              _buildFinancialTab(provider),
              _buildPredictionsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider provider) {
    final summary = provider.getPerformanceSummary();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Performance Indicators
          _buildKPICards(summary),
          const SizedBox(height: 24),
          
          // Revenue Trend Chart
          _buildSectionHeader('Revenue Trend', Icons.trending_up),
          const SizedBox(height: 16),
          _buildRevenueChart(provider),
          const SizedBox(height: 24),
          
          // Alerts Summary
          if (provider.activeAlerts.isNotEmpty) ...[
            _buildSectionHeader('Active Alerts', Icons.warning_amber),
            const SizedBox(height: 16),
            _buildAlertsOverview(provider),
            const SizedBox(height: 24),
          ],
          
          // Recent Recommendations
          if (provider.recentRecommendations.isNotEmpty) ...[
            _buildSectionHeader('AI Recommendations', Icons.lightbulb_outline),
            const SizedBox(height: 16),
            _buildRecommendationsOverview(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesTab(AnalyticsProvider provider) {
    final salesMetrics = provider.salesMetrics;
    
    if (salesMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Summary Cards
          _buildSalesSummaryCards(salesMetrics),
          const SizedBox(height: 24),
          
          // Daily Sales Chart
          _buildSectionHeader('Daily Sales Performance', Icons.show_chart),
          const SizedBox(height: 16),
          _buildDailySalesChart(salesMetrics.dailySales),
          const SizedBox(height: 24),
          
          // Top Products
          _buildSectionHeader('Top Performing Products', Icons.star),
          const SizedBox(height: 16),
          _buildTopProductsList(salesMetrics.topProducts),
          const SizedBox(height: 24),
          
          // Sales Rep Performance
          if (salesMetrics.repPerformance.isNotEmpty) ...[
            _buildSectionHeader('Sales Team Performance', Icons.people),
            const SizedBox(height: 16),
            _buildSalesRepChart(salesMetrics.repPerformance),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryTab(AnalyticsProvider provider) {
    final inventoryMetrics = provider.inventoryMetrics;
    
    if (inventoryMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inventory Overview Cards
          _buildInventoryOverviewCards(inventoryMetrics),
          const SizedBox(height: 24),
          
          // Stock Status Pie Chart
          _buildSectionHeader('Stock Status Distribution', Icons.pie_chart),
          const SizedBox(height: 16),
          _buildStockStatusChart(inventoryMetrics),
          const SizedBox(height: 24),
          
          // Inventory Value Trend
          _buildSectionHeader('Inventory Value Trend', Icons.timeline),
          const SizedBox(height: 16),
          _buildInventoryTrendChart(inventoryMetrics.trends),
          const SizedBox(height: 24),
          
          // Stock Alerts
          if (inventoryMetrics.stockAlerts.isNotEmpty) ...[
            _buildSectionHeader('Stock Alerts', Icons.warning),
            const SizedBox(height: 16),
            _buildStockAlertsList(inventoryMetrics.stockAlerts),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialTab(AnalyticsProvider provider) {
    final financialMetrics = provider.financialMetrics;
    
    if (financialMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary
          _buildFinancialSummaryCards(financialMetrics),
          const SizedBox(height: 24),
          
          // Profit & Loss Chart
          _buildSectionHeader('Profit & Loss Overview', Icons.account_balance),
          const SizedBox(height: 16),
          _buildProfitLossChart(financialMetrics),
          const SizedBox(height: 24),
          
          // Expense Breakdown
          _buildSectionHeader('Expense Breakdown', Icons.pie_chart_outline),
          const SizedBox(height: 16),
          _buildExpenseBreakdownChart(financialMetrics),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab(AnalyticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generate Analysis Buttons
          _buildAnalysisControls(provider),
          const SizedBox(height: 24),
          
          // Recent Analyses
          if (provider.predictiveAnalyses.isNotEmpty) ...[
            _buildSectionHeader('Recent Analyses', Icons.psychology),
            const SizedBox(height: 16),
            _buildPredictiveAnalysesList(provider.predictiveAnalyses),
          ] else ...[
            _buildEmptyPredictionsView(),
          ],
        ],
      ),
    );
  }

  Widget _buildKPICards(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        ModernCard(
          child: _buildKPICard(
            'Total Revenue',
            NumberFormat.currency(symbol: '৳').format(summary['revenue']['current']),
            summary['revenue']['growth'],
            summary['revenue']['trend'] == 'up' ? Icons.trending_up : Icons.trending_down,
            summary['revenue']['trend'] == 'up' ? Colors.green : Colors.red,
          ),
        ),
        ModernCard(
          child: _buildKPICard(
            'Total Orders',
            '${summary['orders']['total']}',
            null,
            Icons.shopping_cart,
            const Color(0xFF2196F3),
          ),
        ),
        ModernCard(
          child: _buildKPICard(
            'Inventory Value',
            NumberFormat.currency(symbol: '৳').format(summary['inventory']['total_value']),
            null,
            Icons.inventory,
            Colors.blue,
          ),
        ),
        ModernCard(
          child: _buildKPICard(
            'Profit Margin',
            '${summary['financial']['profit_margin'].toStringAsFixed(1)}%',
            null,
            Icons.show_chart,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, double? growth, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growth > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: growth > 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AnalyticsProvider provider) {
    final dailySales = provider.salesMetrics?.dailySales ?? [];
    
    if (dailySales.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dailySales.length) {
                        final date = dailySales[value.toInt()].date;
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: dailySales.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.revenue);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF2196F3),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsOverview(AnalyticsProvider provider) {
    final criticalAlerts = provider.criticalAlerts;
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${criticalAlerts.length} Critical Alerts',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...criticalAlerts.take(3).map((alert) => _buildAlertItem(alert)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(StockAlert alert) {
    Color color;
    IconData icon;
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
      case AlertSeverity.high:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.yellow[700]!;
        icon = Icons.info;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${alert.productName} (${alert.currentStock} left)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsOverview(AnalyticsProvider provider) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTabIndex = 4),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.recentRecommendations.take(2).map((rec) => _buildRecommendationItem(rec)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Recommendation recommendation) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.description,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Impact: ${recommendation.impact.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummaryCards(SalesMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: ModernCard(
            child: _buildSummaryCard(
              'Total Revenue',
              NumberFormat.currency(symbol: '৳').format(metrics.totalRevenue),
              Icons.attach_money,
              Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernCard(
            child: _buildSummaryCard(
              'Average Order',
              NumberFormat.currency(symbol: '৳').format(metrics.averageOrderValue),
              Icons.shopping_cart,
              Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesChart(List<DailySales> dailySales) {
    if (dailySales.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No data available')));
    }

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: dailySales.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dailySales.length) {
                        final date = dailySales[value.toInt()].date;
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: dailySales.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.revenue,
                      color: const Color(0xFF2196F3),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductsList(List<TopProduct> topProducts) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: topProducts.take(5).map((product) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      product.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${product.unitsSold} units',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      NumberFormat.currency(symbol: '৳').format(product.revenue),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSalesRepChart(List<SalesRepPerformance> repPerformance) {
    if (repPerformance.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No data available')));
    }

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: repPerformance.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < repPerformance.length) {
                        final rep = repPerformance[value.toInt()];
                        return Text(
                          rep.repName.split(' ').first, // First name only
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: repPerformance.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.totalSales,
                      color: Colors.indigo,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryOverviewCards(InventoryMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        ModernCard(
          child: _buildSummaryCard(
            'Total Products',
            '${metrics.totalProducts}',
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Inventory Value',
            NumberFormat.currency(symbol: '৳').format(metrics.totalInventoryValue),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Low Stock',
            '${metrics.lowStockProducts}',
            Icons.warning,
            Colors.orange,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Out of Stock',
            '${metrics.outOfStockProducts}',
            Icons.error,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStockStatusChart(InventoryMetrics metrics) {
    final inStock = metrics.totalProducts - metrics.lowStockProducts - metrics.outOfStockProducts;
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: inStock.toDouble(),
                  title: 'In Stock\n$inStock',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: metrics.lowStockProducts.toDouble(),
                  title: 'Low Stock\n${metrics.lowStockProducts}',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: metrics.outOfStockProducts.toDouble(),
                  title: 'Out of Stock\n${metrics.outOfStockProducts}',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTrendChart(List<InventoryTrend> trends) {
    if (trends.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No trend data available')));
    }

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < trends.length) {
                        final date = trends[value.toInt()].date;
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: trends.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  color: Colors.purple,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.purple.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockAlertsList(List<StockAlert> alerts) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: alerts.take(10).map((alert) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    alert.severity == AlertSeverity.critical ? Icons.error :
                    alert.severity == AlertSeverity.high ? Icons.warning : Icons.info,
                    color: alert.severity == AlertSeverity.critical ? Colors.red :
                           alert.severity == AlertSeverity.high ? Colors.orange : Colors.yellow[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Current: ${alert.currentStock}, Min: ${alert.minimumStock}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alert.severity == AlertSeverity.critical ? Colors.red.withOpacity(0.1) :
                             alert.severity == AlertSeverity.high ? Colors.orange.withOpacity(0.1) : 
                             Colors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.severity.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: alert.severity == AlertSeverity.critical ? Colors.red :
                               alert.severity == AlertSeverity.high ? Colors.orange : Colors.yellow[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCards(FinancialMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        ModernCard(
          child: _buildSummaryCard(
            'Gross Profit',
            NumberFormat.currency(symbol: '৳').format(metrics.grossProfit),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Net Profit',
            NumberFormat.currency(symbol: '৳').format(metrics.netProfit),
            Icons.account_balance_wallet,
            metrics.netProfit > 0 ? Colors.green : Colors.red,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Profit Margin',
            '${metrics.profitMargin.toStringAsFixed(1)}%',
            Icons.percent,
            metrics.profitMargin > 0 ? Colors.green : Colors.red,
          ),
        ),
        ModernCard(
          child: _buildSummaryCard(
            'Operating Expenses',
            NumberFormat.currency(symbol: '৳').format(metrics.operatingExpenses),
            Icons.money_off,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitLossChart(FinancialMetrics metrics) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: [metrics.totalRevenue, metrics.totalExpenses, metrics.netProfit]
                  .reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0: return const Text('Revenue', style: TextStyle(fontSize: 10));
                        case 1: return const Text('Expenses', style: TextStyle(fontSize: 10));
                        case 2: return const Text('Net Profit', style: TextStyle(fontSize: 10));
                        default: return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: metrics.totalRevenue,
                      color: Colors.green,
                      width: 30,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: metrics.totalExpenses,
                      color: Colors.red,
                      width: 30,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: metrics.netProfit > 0 ? metrics.netProfit : 0,
                      color: metrics.netProfit > 0 ? Colors.blue : Colors.grey,
                      width: 30,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownChart(FinancialMetrics metrics) {
    final expenses = metrics.expenseBreakdown;
    if (expenses.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No expense data available')));
    }

    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.purple, Colors.teal];
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: expenses.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final expense = entry.value;
                      final percentage = (expense.value / expenses.values.reduce((a, b) => a + b)) * 100;
                      
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: expense.value,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: expenses.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final expense = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: colors[index % colors.length],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.key,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '৳').format(expense.value),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisControls(AnalyticsProvider provider) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Predictive Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAnalysisButton(
                  provider,
                  'Demand Forecast',
                  'demand_forecast',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildAnalysisButton(
                  provider,
                  'Inventory Optimization',
                  'inventory_optimization',
                  Icons.inventory,
                  Colors.green,
                ),
                _buildAnalysisButton(
                  provider,
                  'Sales Prediction',
                  'sales_prediction',
                  Icons.show_chart,
                  Colors.purple,
                ),
                _buildAnalysisButton(
                  provider,
                  'Risk Assessment',
                  'risk_assessment',
                  Icons.warning,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisButton(
    AnalyticsProvider provider,
    String title,
    String type,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: provider.isLoading 
          ? null 
          : () => provider.generatePredictiveAnalysis(type: type),
      icon: Icon(icon, size: 16),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildPredictiveAnalysesList(List<PredictiveAnalysis> analyses) {
    return Column(
      children: analyses.map((analysis) => _buildAnalysisCard(analysis)).toList(),
    );
  }

  Widget _buildAnalysisCard(PredictiveAnalysis analysis) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  analysis.type.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Confidence: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(analysis.generatedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Key Predictions:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...analysis.predictions.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.blue)),
                    Text(
                      '${entry.key.replaceAll('_', ' ')}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...analysis.recommendations.take(3).map((rec) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Impact Score: ${rec.impact.toStringAsFixed(1)}/10',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPredictionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Predictive Analyses Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate AI-powered insights to optimize your business',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Use the buttons above to generate analysis',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AnalyticsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'An unexpected error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.refreshAllMetrics(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(AnalyticsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Analytics Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Range: ${DateFormat('MMM dd').format(provider.startDate)} - ${DateFormat('MMM dd, yyyy').format(provider.endDate)}'),
            const SizedBox(height: 8),
            if (provider.selectedLocationId != null) 
              Text('Location: ${provider.selectedLocationId}')
            else
              const Text('Location: All Locations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}