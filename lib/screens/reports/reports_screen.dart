import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
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

    productProvider.fetchProducts();
    stockProvider.fetchStocks();
    stockProvider.fetchLocations();
    stockProvider.fetchMovements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer2<ProductProvider, StockProvider>(
        builder: (context, productProvider, stockProvider, child) {
          if (productProvider.isLoading || stockProvider.isLoading) {
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
                          AppTheme.primaryBlue,
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
                  const SizedBox(height: 24),

                  // Stock Summary by Location
                  Text(
                    'Stock by Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkBlue,
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
                    }).toList(),

                  const SizedBox(height: 24),

                  // Low Stock Alert
                  Text(
                    'স্টক কম এলার্ট',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildLowStockSection(productProvider, stockProvider),

                  const SizedBox(height: 24),

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkBlue,
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
                    }).toList(),
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
}
