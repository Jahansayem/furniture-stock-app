import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../models/stock.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';

class LocationDetailScreen extends StatefulWidget {
  final StockLocation location;

  const LocationDetailScreen({
    super.key,
    required this.location,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: Text(widget.location.locationName),
        backgroundColor: _getLocationColor(widget.location.locationType),
      ),
      body: Consumer2<ProductProvider, StockProvider>(
        builder: (context, productProvider, stockProvider, child) {
          if (productProvider.isLoading || stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get stocks for this location
          final locationStocks = stockProvider.stocks
              .where((stock) => stock.locationId == widget.location.id)
              .toList();

          // Get products that have stock in this location
          final productsWithStock = <Map<String, dynamic>>[];

          for (final stock in locationStocks) {
            final product = productProvider.products
                .where((p) => p.id == stock.productId)
                .firstOrNull;

            if (product != null) {
              productsWithStock.add({
                'product': product,
                'stock': stock,
              });
            }
          }

          // Sort by product name
          productsWithStock.sort((a, b) => (a['product'] as Product)
              .productName
              .compareTo((b['product'] as Product).productName));

          return RefreshIndicator(
            onRefresh: () async {
              _fetchData();
            },
            child: Column(
              children: [
                // Location info header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getLocationColor(widget.location.locationType)
                              .withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getLocationIcon(widget.location.locationType),
                          color:
                              _getLocationColor(widget.location.locationType),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location.locationName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              widget.location.locationType.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
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
                            '${locationStocks.fold(0, (sum, stock) => sum + stock.quantity)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _getLocationColor(
                                      widget.location.locationType),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Total Items',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                          Text(
                            '${productsWithStock.length} Products',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Products list
                Expanded(
                  child: productsWithStock.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: productsWithStock.length,
                          itemBuilder: (context, index) {
                            final item = productsWithStock[index];
                            final product = item['product'] as Product;
                            final stock = item['stock'] as Stock;

                            return _buildProductCard(product, stock);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, Stock stock) {
    final isLowStock = stock.quantity <= product.lowStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock
            ? Border.all(color: AppColors.warning.withAlpha(76))
            : null,
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
          // Product image placeholder or icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.chair,
                          color: AppTheme.primaryBlue,
                          size: 32,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.chair,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  product.productType,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (product.price > 0)
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                if (isLowStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Low Stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
          ),

          // Stock quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? AppColors.warning.withAlpha(25)
                      : AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stock.quantity}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            isLowStock ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'In Stock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (product.lowStockThreshold > 0)
                Text(
                  'Min: ${product.lowStockThreshold}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This location doesn\'t have any products in stock yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
}

