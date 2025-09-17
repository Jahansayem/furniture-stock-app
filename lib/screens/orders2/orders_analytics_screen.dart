import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/sales_provider.dart';
import '../../models/sale.dart';

class OrdersAnalyticsScreen extends StatefulWidget {
  const OrdersAnalyticsScreen({super.key});

  @override
  State<OrdersAnalyticsScreen> createState() => _OrdersAnalyticsScreenState();
}

class _OrdersAnalyticsScreenState extends State<OrdersAnalyticsScreen> {
  String _selectedPeriod = '7days';

  final Map<String, String> _periodLabels = {
    '7days': 'Last 7 Days',
    '30days': 'Last 30 Days',
    '3months': 'Last 3 Months',
    'all': 'All Time',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Order Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) {
              return _periodLabels.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _selectedPeriod == entry.key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, _) {
          if (salesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = salesProvider.sales
              .where((sale) => sale.saleType == 'online_cod')
              .toList();

          final filteredOrders = _filterOrdersByPeriod(allOrders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                Text(
                  'Analytics for ${_periodLabels[_selectedPeriod]}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),

                // Key Metrics Cards
                _buildMetricsGrid(filteredOrders),
                const SizedBox(height: 32),

                // Order Status Distribution
                _buildStatusDistributionChart(filteredOrders),
                const SizedBox(height: 32),

                // Revenue Trend Chart
                _buildRevenueTrendChart(filteredOrders),
                const SizedBox(height: 32),

                // Top Products
                _buildTopProductsList(filteredOrders),
                const SizedBox(height: 32),

                // Performance Metrics
                _buildPerformanceMetrics(filteredOrders),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Sale> _filterOrdersByPeriod(List<Sale> orders) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedPeriod) {
      case '7days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case 'all':
      default:
        return orders;
    }

    return orders.where((order) {
      return order.saleDate.isAfter(cutoffDate);
    }).toList();
  }

  Widget _buildMetricsGrid(List<Sale> orders) {
    final totalOrders = orders.length;
    final totalRevenue = orders
        .where((o) => o.courierStatus == 'delivered')
        .fold<double>(0.0, (sum, order) => sum + (order.codAmount ?? order.totalAmount));
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completionRate = totalOrders > 0
        ? (orders.where((o) => o.courierStatus == 'delivered').length / totalOrders * 100)
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          title: 'Total Orders',
          value: totalOrders.toString(),
          subtitle: 'All time: ${orders.length}',
          icon: Icons.shopping_bag,
          color: const Color(0xFF3B82F6),
        ),
        _buildMetricCard(
          title: 'Total Revenue',
          value: '৳${totalRevenue.toStringAsFixed(0)}',
          subtitle: 'Delivered orders',
          icon: Icons.attach_money,
          color: const Color(0xFF10B981),
        ),
        _buildMetricCard(
          title: 'Avg Order Value',
          value: '৳${avgOrderValue.toStringAsFixed(0)}',
          subtitle: 'Per order',
          icon: Icons.trending_up,
          color: const Color(0xFF8B5CF6),
        ),
        _buildMetricCard(
          title: 'Completion Rate',
          value: '${completionRate.toStringAsFixed(1)}%',
          subtitle: 'Delivered/Total',
          icon: Icons.check_circle,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionChart(List<Sale> orders) {
    final statusCounts = <String, int>{};

    for (final order in orders) {
      final status = order.status == 'cancelled'
          ? 'cancelled'
          : order.status == 'in_review'
            ? 'pending'
            : (order.courierStatus ?? 'unknown');

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final sections = statusCounts.entries.map((entry) {
      return PieChartSectionData(
        color: _getStatusColor(entry.key),
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: statusCounts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_getStatusDisplayName(entry.key)}: ${entry.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart(List<Sale> orders) {
    final deliveredOrders = orders
        .where((o) => o.courierStatus == 'delivered')
        .toList();

    // Group by date
    final dailyRevenue = <DateTime, double>{};
    for (final order in deliveredOrders) {
      final date = DateTime(
        order.saleDate.year,
        order.saleDate.month,
        order.saleDate.day,
      );
      dailyRevenue[date] = (dailyRevenue[date] ?? 0.0) +
          (order.codAmount ?? order.totalAmount);
    }

    final sortedDates = dailyRevenue.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyRevenue[entry.value]!);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'No revenue data available',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: spots.length <= 10),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF10B981).withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                                final date = sortedDates[value.toInt()];
                                return Text('${date.day}/${date.month}');
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
                              return Text('৳${value.toInt()}');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsList(List<Sale> orders) {
    // Group by product
    final productCounts = <String, int>{};
    final productRevenue = <String, double>{};

    for (final order in orders) {
      productCounts[order.productName] = (productCounts[order.productName] ?? 0) + order.quantity;
      if (order.courierStatus == 'delivered') {
        productRevenue[order.productName] = (productRevenue[order.productName] ?? 0.0) +
            (order.codAmount ?? order.totalAmount);
      }
    }

    // Sort by quantity sold
    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...sortedProducts.take(5).map((entry) {
            final productName = entry.key;
            final quantity = entry.value;
            final revenue = productRevenue[productName] ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Revenue: ৳${revenue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$quantity sold',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(List<Sale> orders) {
    final totalOrders = orders.length;
    final pendingOrders = orders.where((o) =>
        o.status == 'in_review' && (o.consignmentId == null || o.consignmentId!.isEmpty)).length;
    final deliveredOrders = orders.where((o) => o.courierStatus == 'delivered').length;
    final cancelledOrders = orders.where((o) => o.status == 'cancelled').length;
    final returnedOrders = orders.where((o) => o.courierStatus == 'returned').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceRow('Total Orders', totalOrders.toString(), Colors.blue),
          _buildPerformanceRow('Pending Orders', pendingOrders.toString(), Colors.orange),
          _buildPerformanceRow('Delivered Orders', deliveredOrders.toString(), Colors.green),
          _buildPerformanceRow('Cancelled Orders', cancelledOrders.toString(), Colors.red),
          _buildPerformanceRow('Returned Orders', returnedOrders.toString(), Colors.grey),
          const SizedBox(height: 12),
          _buildPerformanceRow(
            'Success Rate',
            totalOrders > 0 ? '${(deliveredOrders / totalOrders * 100).toStringAsFixed(1)}%' : '0%',
            Colors.green,
          ),
          _buildPerformanceRow(
            'Cancellation Rate',
            totalOrders > 0 ? '${(cancelledOrders / totalOrders * 100).toStringAsFixed(1)}%' : '0%',
            Colors.red,
          ),
          _buildPerformanceRow(
            'Return Rate',
            totalOrders > 0 ? '${(returnedOrders / totalOrders * 100).toStringAsFixed(1)}%' : '0%',
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'partial_delivered':
        return const Color(0xFF3B82F6);
      case 'returned':
        return const Color(0xFF6B7280);
      case 'hold':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'delivered':
        return 'Delivered';
      case 'partial_delivered':
        return 'Partial';
      case 'returned':
        return 'Returned';
      case 'hold':
        return 'Hold';
      default:
        return 'Unknown';
    }
  }
}