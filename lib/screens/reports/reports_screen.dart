import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../models/sale.dart';
import '../../utils/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    productProvider.fetchProducts();
    stockProvider.fetchStocks();
    stockProvider.fetchLocations();
    stockProvider.fetchMovements();
    salesProvider.fetchSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer3<ProductProvider, StockProvider, SalesProvider>(
        builder: (context, productProvider, stockProvider, salesProvider, child) {
          if (productProvider.isLoading || stockProvider.isLoading || salesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetchData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Total Products',
                          '${productProvider.products.length}',
                          Icons.inventory_2,
                          AppTheme.primaryOrange,
                          () => context.go('/products'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Total Locations',
                          '${stockProvider.locations.length}',
                          Icons.location_on,
                          Colors.green,
                          () => context.go('/stock'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Total Movements',
                          '${stockProvider.movements.length}',
                          Icons.swap_horiz,
                          Colors.purple,
                          () => context.go('/stock/movement'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Low Stock Items',
                          '${stockProvider.getLowStockCount(productProvider.products)}',
                          Icons.warning,
                          Colors.orange,
                          () => context.go('/products?filter=low_stock'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Courier tracking cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Pending Deliveries',
                          '${salesProvider.getPendingDeliveries().length}',
                          Icons.local_shipping,
                          Colors.orange,
                          () => _showCourierDetailsDialog(context, salesProvider.getPendingDeliveries(), 'Pending Deliveries'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildClickableMetricCard(
                          'Total Courier Orders',
                          '${salesProvider.getCourierOrders().length}',
                          Icons.assignment,
                          Colors.blue,
                          () => _showCourierDetailsDialog(context, salesProvider.getCourierOrders(), 'All Courier Orders'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stock Summary by Location
                  Text(
                    'Stock by Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkOrange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  if (stockProvider.locations.isEmpty)
                    _buildEmptyState(
                      'No locations configured',
                      'Stock locations will appear here when configured',
                      Icons.location_off,
                    )
                  else
                    ...stockProvider.locations.map((location) {
                      final locationStocks = stockProvider.stocks
                          .where((stock) => stock.locationId == location.id)
                          .toList();
                      final totalQuantity = locationStocks.fold(
                          0, (sum, stock) => sum + stock.quantity);
                      final uniqueProducts = locationStocks.length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            context.go('/reports/location', extra: location);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _getLocationColor(location.locationType)
                                            .withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getLocationIcon(location.locationType),
                                    color: _getLocationColor(
                                        location.locationType),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.locationName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        location.locationType.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
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
                                      '$totalQuantity',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: _getLocationColor(
                                                location.locationType),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '$uniqueProducts product${uniqueProducts != 1 ? 's' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Low Stock Alert
                  Text(
                    'স্টক কম এলার্ট',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkOrange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildLowStockSection(productProvider, stockProvider),

                  const SizedBox(height: 24),

                  // Courier Tracking Section
                  Text(
                    'Courier Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkOrange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildCourierTrackingSection(salesProvider),

                  const SizedBox(height: 24),

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkOrange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  if (stockProvider.movements.isEmpty)
                    _buildEmptyState(
                      'No recent activity',
                      'Stock movements will appear here',
                      Icons.history,
                    )
                  else
                    ...stockProvider.movements.take(5).map((movement) {
                      final product = productProvider.products
                          .where((p) => p.id == movement.productId)
                          .firstOrNull;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _getMovementColor(movement.movementType)
                                          .withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getMovementIcon(movement.movementType),
                                  color:
                                      _getMovementColor(movement.movementType),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product?.productName ?? 'Unknown Product',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      _formatMovementDescription(
                                          movement.movementType),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                    Text(
                                      _formatDateTime(movement.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[500],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getMovementColor(movement.movementType)
                                          .withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${movement.quantity}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _getMovementColor(
                                            movement.movementType),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClickableMetricCard(String title, String value, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(
      ProductProvider productProvider, StockProvider stockProvider) {
    final lowStockProducts = <Map<String, dynamic>>[];

    for (final product in productProvider.products) {
      final productStocks =
          stockProvider.stocks.where((stock) => stock.productId == product.id);
      final totalQuantity =
          productStocks.fold(0, (sum, stock) => sum + stock.quantity);

      if (totalQuantity <= product.lowStockThreshold) {
        lowStockProducts.add({
          'product': product,
          'currentStock': totalQuantity,
          'threshold': product.lowStockThreshold,
        });
      }
    }

    if (lowStockProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            Text(
              'All stock levels are healthy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'No products are below their stock threshold',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lowStockProducts.map<Widget>((item) {
        final product = item['product'];
        final currentStock = item['currentStock'] as int;
        final threshold = item['threshold'] as int;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(76)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'বর্তমানে স্টক: $currentStock | মিনিমাম স্টক থাকা উচিৎ: $threshold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$currentStock',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getLocationColor(String locationType) {
    switch (locationType.toLowerCase()) {
      case 'factory':
        return AppColors.production;
      case 'showroom':
        return AppColors.success;
      case 'warehouse':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  IconData _getLocationIcon(String locationType) {
    switch (locationType.toLowerCase()) {
      case 'factory':
        return Icons.factory;
      case 'showroom':
        return Icons.store;
      case 'warehouse':
        return Icons.warehouse;
      default:
        return Icons.location_on;
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
      case 'sale':
        return AppColors.sale;
      default:
        return AppColors.info;
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
      case 'sale':
        return Icons.shopping_cart;
      default:
        return Icons.move_down;
    }
  }

  String _formatMovementDescription(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'transfer':
        return 'Stock transferred';
      case 'production':
        return 'Production completed';
      case 'adjustment':
        return 'Stock adjusted';
      case 'sale':
        return 'Stock sold';
      default:
        return 'Stock movement';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildCourierTrackingSection(SalesProvider salesProvider) {
    final pendingDeliveries = salesProvider.getPendingDeliveries();
    final allCourierOrders = salesProvider.getCourierOrders();

    if (allCourierOrders.isEmpty) {
      return _buildEmptyState(
        'No courier orders yet',
        'Online COD orders with courier tracking will appear here',
        Icons.local_shipping_outlined,
      );
    }

    return Column(
      children: [
        // Summary Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${pendingDeliveries.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pending',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${allCourierOrders.where((s) => s.courierStatus == 'delivered').length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Delivered',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.assignment, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${allCourierOrders.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Orders',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Refresh Status Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: salesProvider.isLoading ? null : () async {
              await salesProvider.refreshAllCourierStatuses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Courier statuses refreshed')),
              );
            },
            icon: salesProvider.isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
            label: Text(salesProvider.isLoading ? 'Refreshing...' : 'Refresh All Statuses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recent Pending Orders
        if (pendingDeliveries.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Pending Deliveries',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showCourierDetailsDialog(context, pendingDeliveries, 'Pending Deliveries'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pendingDeliveries.take(3).map((sale) => _buildCourierOrderCard(sale, salesProvider)),
        ]
      ],
    );
  }

  Widget _buildCourierOrderCard(Sale sale, SalesProvider salesProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getCourierStatusColor(sale.courierStatus ?? '').withAlpha(76)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
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
                    color: _getCourierStatusColor(sale.courierStatus ?? '').withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCourierStatusIcon(sale.courierStatus ?? ''),
                    color: _getCourierStatusColor(sale.courierStatus ?? ''),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Customer: ${sale.customerName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (sale.consignmentId != null)
                        Text(
                          'Consignment: ${sale.consignmentId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCourierStatusColor(sale.courierStatus ?? '').withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sale.deliveryStatusDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getCourierStatusColor(sale.courierStatus ?? ''),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${sale.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await salesProvider.updateCourierStatus(
                        saleId: sale.id,
                        consignmentId: sale.consignmentId,
                      );
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status updated')),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Update Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCourierOrderDetails(context, sale),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCourierStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'in_transit':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
      case 'returned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCourierStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'in_transit':
        return Icons.local_shipping;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.keyboard_return;
      default:
        return Icons.help_outline;
    }
  }

  void _showCourierDetailsDialog(BuildContext context, List<Sale> orders, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              if (orders.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No courier orders found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final sale = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getCourierStatusColor(sale.courierStatus ?? '').withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCourierStatusIcon(sale.courierStatus ?? ''),
                              color: _getCourierStatusColor(sale.courierStatus ?? ''),
                              size: 20,
                            ),
                          ),
                          title: Text(sale.productName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${sale.customerName}'),
                              if (sale.consignmentId != null)
                                Text(
                                  'Consignment: ${sale.consignmentId}',
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              Text('Date: ${_formatDateTime(sale.saleDate)}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCourierStatusColor(sale.courierStatus ?? '').withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sale.deliveryStatusDisplay,
                                  style: TextStyle(
                                    color: _getCourierStatusColor(sale.courierStatus ?? ''),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '৳${sale.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          onTap: () => _showCourierOrderDetails(context, sale),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourierOrderDetails(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Courier Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Product', sale.productName),
              _buildDetailRow('Customer', sale.customerName),
              _buildDetailRow('Phone', sale.customerPhone ?? 'Not provided'),
              _buildDetailRow('Amount', '৳${sale.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Sale Date', _formatDateTime(sale.saleDate)),
              if (sale.deliveryType != null)
                _buildDetailRow('Delivery Type', sale.deliveryType!),
              if (sale.recipientName != null)
                _buildDetailRow('Recipient Name', sale.recipientName!),
              if (sale.recipientPhone != null)
                _buildDetailRow('Recipient Phone', sale.recipientPhone!),
              if (sale.recipientAddress != null)
                _buildDetailRow('Recipient Address', sale.recipientAddress!),
              if (sale.codAmount != null)
                _buildDetailRow('COD Amount', '৳${sale.codAmount!.toStringAsFixed(2)}'),
              if (sale.consignmentId != null)
                _buildDetailRow('Consignment ID', sale.consignmentId!),
              if (sale.trackingCode != null)
                _buildDetailRow('Tracking Code', sale.trackingCode!),
              _buildDetailRow('Courier Status', sale.deliveryStatusDisplay),
              if (sale.courierCreatedAt != null)
                _buildDetailRow('Courier Order Date', _formatDateTime(sale.courierCreatedAt!)),
              if (sale.deliveryDate != null)
                _buildDetailRow('Delivery Date', _formatDateTime(sale.deliveryDate!)),
              if (sale.courierNotes != null)
                _buildDetailRow('Courier Notes', sale.courierNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final salesProvider = Provider.of<SalesProvider>(context, listen: false);
              final success = await salesProvider.updateCourierStatus(
                saleId: sale.id,
                consignmentId: sale.consignmentId,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status updated successfully')),
                );
              }
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
