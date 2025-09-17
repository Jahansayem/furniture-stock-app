import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/sales_provider.dart';
import '../../models/sale.dart';

class OrdersDashboardScreen extends StatefulWidget {
  const OrdersDashboardScreen({super.key});

  @override
  State<OrdersDashboardScreen> createState() => _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends State<OrdersDashboardScreen> {
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
      body: SafeArea(
        child: Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            if (salesProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = salesProvider.sales
                .where((sale) => sale.saleType == 'online_cod')
                .toList();

            return CustomScrollView(
              slivers: [
                // Modern App Bar
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF1E293B),
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Orders Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        context.go('/sales/online-cod');
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'Add New Order',
                    ),
                    IconButton(
                      onPressed: () {
                        context.go('/orders2/list');
                      },
                      icon: const Icon(Icons.list_alt, color: Colors.white),
                      tooltip: 'View All Orders',
                    ),
                    IconButton(
                      onPressed: () {
                        salesProvider.fetchSales();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatsGrid(allOrders),
                        const SizedBox(height: 32),

                        // Quick Actions
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 32),

                        // Recent Orders
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Orders',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                context.go('/orders2/list');
                              },
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentOrdersList(allOrders.take(5).toList()),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<Sale> orders) {
    final totalOrders = orders.length;
    final pendingOrders = orders.where((o) =>
        o.status == 'in_review' && (o.consignmentId == null || o.consignmentId!.isEmpty)).length;
    final deliveredOrders = orders.where((o) => o.courierStatus == 'delivered').length;
    final cancelledOrders = orders.where((o) => o.status == 'cancelled').length;

    final totalRevenue = orders
        .where((o) => o.courierStatus == 'delivered')
        .fold<double>(0.0, (sum, order) => sum + (order.codAmount ?? order.totalAmount));

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Total Orders',
          value: totalOrders.toString(),
          icon: Icons.shopping_bag,
          color: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFEFF6FF),
        ),
        _buildStatCard(
          title: 'Pending',
          value: pendingOrders.toString(),
          icon: Icons.schedule,
          color: const Color(0xFFF59E0B),
          backgroundColor: const Color(0xFFFEF3C7),
        ),
        _buildStatCard(
          title: 'Delivered',
          value: deliveredOrders.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFECFDF5),
        ),
        _buildStatCard(
          title: 'Revenue',
          value: '৳${totalRevenue.toStringAsFixed(0)}',
          icon: Icons.attach_money,
          color: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFFF3E8FF),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Order List',
            subtitle: 'View all orders',
            icon: Icons.list_alt,
            color: const Color(0xFF3B82F6),
            onTap: () => context.go('/orders2/list'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            title: 'Analytics',
            subtitle: 'Order insights',
            icon: Icons.bar_chart,
            color: const Color(0xFF10B981),
            onTap: () => context.go('/orders2/analytics'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            title: 'Settings',
            subtitle: 'Configure orders',
            icon: Icons.settings,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/orders2/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList(List<Sale> recentOrders) {
    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent orders',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: recentOrders.asMap().entries.map((entry) {
          final index = entry.key;
          final order = entry.value;
          final isLast = index == recentOrders.length - 1;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () => context.go('/orders2/details/${order.id}'),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(order).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(order),
                      color: _getStatusColor(order),
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${order.quantity}x ${order.productName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${(order.codAmount ?? order.totalAmount).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(order),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(order),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

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
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'delivered':
        return Icons.check_circle;
      case 'partial_delivered':
        return Icons.local_shipping;
      case 'returned':
        return Icons.keyboard_return;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

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
      default:
        return 'Unknown';
    }
  }
}