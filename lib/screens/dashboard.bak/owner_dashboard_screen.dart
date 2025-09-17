import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/role_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/adaptive_app_bar.dart';
import '../../widgets/modern_components.dart';
import '../../utils/app_theme.dart';
import '../../models/user_role.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    
    // Verify user has owner permissions
    if (!roleProvider.hasPermission(Permission.viewOwnerDashboard)) {
      context.go('/'); // Redirect to appropriate dashboard
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    try {
      await Future.wait([
        productProvider.fetchProducts(),
        stockProvider.fetchStocks(),
        stockProvider.fetchLocations(),
        stockProvider.fetchMovements(),
        salesProvider.fetchSales(),
      ]);
      
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: const AdaptiveAppBar(
        title: 'Business Overview',
        subtitle: 'Complete business analytics and insights',
      ),
      body: _isDataLoaded
          ? RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context),
                    const SizedBox(height: 20),
                    _buildKPIGrid(context),
                    const SizedBox(height: 20),
                    _buildRevenueChart(context),
                    const SizedBox(height: 20),
                    _buildBusinessInsights(context),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                    const SizedBox(height: 20),
                    _buildRecentActivity(context),
                  ],
                ),
              ),
            )
          : _buildLoadingState(),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userProfile;
        final displayName = user?.displayName ?? 'Owner';
        
        return ModernCard(
          accentColor: AppColors.trustBadge,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.trustBadge,
                      AppColors.trustBadge.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.business_center,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $displayName!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s your business overview for today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateTime.now().toString().split(' ')[0],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.trustBadge,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    return Consumer3<SalesProvider, ProductProvider, StockProvider>(
      builder: (context, salesProvider, productProvider, stockProvider, child) {
        final totalRevenue = salesProvider.sales
            .fold<double>(0, (sum, sale) => sum + (sale.totalAmount ?? 0));
        final totalProducts = productProvider.products.length;
        final lowStockCount = stockProvider.getLowStockCount(productProvider.products);
        final totalOrders = salesProvider.sales.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Performance Indicators',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                MetricCard(
                  title: 'Total Revenue',
                  value: '৳${totalRevenue.toStringAsFixed(0)}',
                  subtitle: 'Last 30 days',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  trend: 12.5,
                  onTap: () => context.go('/finance'),
                ),
                MetricCard(
                  title: 'Total Products',
                  value: totalProducts.toString(),
                  subtitle: 'Active inventory',
                  icon: Icons.inventory_2,
                  color: AppColors.info,
                  trend: 5.2,
                  onTap: () => context.go('/products'),
                ),
                MetricCard(
                  title: 'Low Stock Items',
                  value: lowStockCount.toString(),
                  subtitle: 'Needs attention',
                  icon: Icons.warning,
                  color: AppColors.warning,
                  trend: -8.1,
                  onTap: () => context.go('/stock?filter=low_stock'),
                ),
                MetricCard(
                  title: 'Total Orders',
                  value: totalOrders.toString(),
                  subtitle: 'This month',
                  icon: Icons.shopping_cart,
                  color: AppColors.production,
                  trend: 18.7,
                  onTap: () => context.go('/orders'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+24.5%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
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
                      interval: 50000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toInt()}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateRevenueSpots(),
                    isCurved: true,
                    color: AppColors.trustBadge,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.trustBadge.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateRevenueSpots() {
    return [
      const FlSpot(0, 80000),
      const FlSpot(1, 95000),
      const FlSpot(2, 120000),
      const FlSpot(3, 110000),
      const FlSpot(4, 140000),
      const FlSpot(5, 160000),
    ];
  }

  Widget _buildBusinessInsights(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            context,
            'Top Performing Product',
            'Modern Sofa Set',
            '45 units sold this month',
            Icons.star,
            AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            'Best Sales Person',
            'Ahmed Hassan',
            '৳85,000 revenue generated',
            Icons.person_outline,
            AppColors.info,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            'Inventory Alert',
            'Low stock on 8 items',
            'Reorder required soon',
            Icons.warning_outlined,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context,
              'View Analytics',
              Icons.analytics_outlined,
              AppColors.trustBadge,
              () => context.go('/analytics'),
            ),
            _buildActionCard(
              context,
              'Employee Report',
              Icons.people_outline,
              AppColors.info,
              () => context.go('/employees/reports'),
            ),
            _buildActionCard(
              context,
              'Financial Summary',
              Icons.account_balance_outlined,
              AppColors.success,
              () => context.go('/finance/summary'),
            ),
            _buildActionCard(
              context,
              'System Settings',
              Icons.settings_outlined,
              AppColors.production,
              () => context.go('/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ModernCard(
      accentColor: color,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Consumer2<StockProvider, SalesProvider>(
      builder: (context, stockProvider, salesProvider, child) {
        final recentActivities = <ActivityItem>[];
        
        // Add recent sales
        for (final sale in salesProvider.sales.take(3)) {
          recentActivities.add(ActivityItem(
            title: 'Sale: ${sale.productName}',
            subtitle: 'by ${sale.soldByName} • ${_formatTime(sale.saleDate)}',
            icon: Icons.point_of_sale,
            color: AppColors.success,
            value: '৳${sale.totalAmount?.toStringAsFixed(0) ?? '0'}',
          ));
        }

        // Add stock movements
        for (final movement in stockProvider.movements.take(2)) {
          recentActivities.add(ActivityItem(
            title: 'Stock ${movement.movementType}',
            subtitle: '${movement.productName} • ${_formatTime(movement.createdAt)}',
            icon: _getMovementIcon(movement.movementType),
            color: _getMovementColor(movement.movementType),
            value: '${movement.quantity} units',
          ));
        }

        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/activity'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...recentActivities.map((activity) => 
                _buildActivityItem(context, activity)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: activity.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading business overview...'),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getMovementIcon(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'production':
        return Icons.factory;
      case 'adjustment':
        return Icons.tune;
      default:
        return Icons.move_down;
    }
  }

  Color _getMovementColor(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'transfer':
        return AppColors.transfer;
      case 'production':
        return AppColors.production;
      case 'adjustment':
        return AppColors.adjustment;
      default:
        return AppColors.info;
    }
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String value;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
  });
}