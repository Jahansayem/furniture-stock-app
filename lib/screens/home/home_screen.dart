import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';

class ActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final int quantity;
  final IconData icon;
  final Color color;
  final DateTime date;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.icon,
    required this.color,
    required this.date,
  });
}

class CheckeredPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final squareSize = 8.0;

    for (int i = 0; i < (size.width / squareSize).ceil(); i++) {
      for (int j = 0; j < (size.height / squareSize).ceil(); j++) {
        paint.color = (i + j) % 2 == 0 ? Colors.black : Colors.white;
        canvas.drawRect(
          Rect.fromLTWH(
            i * squareSize,
            j * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Start lazy loading after a small delay to not block initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLazyDataLoading();
    });
  }

  Future<void> _startLazyDataLoading() async {
    // Small delay to ensure UI is rendered first
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      _fetchDataInChunks();
    }
  }

  Future<void> _fetchDataInChunks() async {
    try {
      // Load critical data first (products and stocks)
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);

      await Future.wait([
        productProvider.fetchProducts(),
        stockProvider.fetchStocks(),
      ]);

      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }

      // Load remaining data in background
      _loadRemainingDataInBackground();
    } catch (e) {
      AppLogger.error('Error loading initial data', error: e);
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    }
  }

  Future<void> _loadRemainingDataInBackground() async {
    // Load less critical data in background without blocking UI
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Load each data type with small delays between them
    // Load remaining data concurrently - no need for artificial delays
    Future.microtask(() => stockProvider.fetchLocations());
    Future.microtask(() => stockProvider.fetchMovements());
    Future.microtask(() => salesProvider.fetchSales());
    Future.microtask(() => notificationProvider.fetchNotifications());
  }

  Future<void> _fetchData() async {
    // This is used for refresh - load everything at once
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    await Future.wait([
      productProvider.fetchProducts(),
      stockProvider.fetchStocks(),
      stockProvider.fetchLocations(),
      stockProvider.fetchMovements(),
      salesProvider.fetchSales(),
      notificationProvider.fetchNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchData();
          },
          child: _isDataLoaded
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Section
                      _buildProfileHeader(context),

                      const SizedBox(height: 24),

                      // Store Analytics Section
                      _buildStoreAnalytics(context),

                      const SizedBox(height: 24),

                      // Best Selling Section
                      _buildBestSellingSection(context),
                    ],
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading dashboard...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userProfile;
        final authUser = authProvider.user;

        String displayName = 'User';
        if (user != null && user.fullName != null) {
          final nameParts = user.fullName!.trim().split(' ');
          if (nameParts.length >= 2) {
            displayName = '${nameParts.first} ${nameParts.last}';
          } else if (nameParts.isNotEmpty) {
            displayName = nameParts.first;
          } else {
            displayName = user.displayName;
          }
        } else if (authUser?.email != null) {
          displayName = authUser!.email!.split('@')[0];
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Profile Photo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(26),
                      image: const DecorationImage(
                        image: NetworkImage('https://via.placeholder.com/52'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Welcome Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Notification Icon
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  return GestureDetector(
                    onTap: () {
                      context.go('/notifications');
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: Colors.black,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildStoreAnalytics(BuildContext context) {
    return Consumer3<SalesProvider, StockProvider, ProductProvider>(
      builder: (context, salesProvider, stockProvider, productProvider, child) {
        // Calculate totals from actual data
        final totalRevenue = salesProvider.sales.fold<double>(
          0.0,
          (sum, sale) => sum + sale.totalAmount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Store Overview',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Analytics Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildAnalyticsCard(
                  'Products',
                  '${productProvider.products.length}',
                  'Total items',
                  const Color(0xFF1890FF),
                  Icons.arrow_upward,
                ),
                _buildAnalyticsCard(
                  'Low Stock',
                  '${stockProvider.getLowStockCount(productProvider.products)}',
                  'Items low',
                  const Color(0xFFFF4D4F),
                  Icons.arrow_downward,
                ),
                _buildAnalyticsCard(
                  'Factory Stock',
                  '${stockProvider.factoryStockCount}',
                  'In factory',
                  const Color(0xFF52C41A),
                  Icons.arrow_upward,
                ),
                _buildAnalyticsCard(
                  'Showroom Stock',
                  '${stockProvider.showroomStockCount}',
                  'In showroom',
                  const Color(0xFF722ED1),
                  Icons.arrow_upward,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String amount,
    String period,
    Color trendColor,
    IconData trendIcon,
  ) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                trendIcon,
                size: 12,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBestSellingSection(BuildContext context) {
    return Consumer2<ProductProvider, SalesProvider>(
      builder: (context, productProvider, salesProvider, child) {
        // Get products with sales data - for now using mock data to match Figma
        final products = productProvider.products.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Products',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product, index);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(dynamic product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Product Image (checkered pattern as in Figma)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: CustomPaint(
              painter: CheckeredPatternPainter(),
              child: Container(),
            ),
          ),
          const SizedBox(width: 16),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name ?? 'Product Name',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${product.category ?? 'General'}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Star Rating
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      Icons.star,
                      size: 14,
                      color: starIndex < 5 ? Colors.orange : Colors.grey[300],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Price and Quantity
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1890FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'USD 470',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: const Color(0xFF1890FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '20',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bars
                _buildProgressIndicator('Varian', 0.9, const Color(0xFF1890FF)),
                const SizedBox(height: 4),
                _buildProgressIndicator('Like', 0.3, Colors.orange),
                const SizedBox(height: 4),
                _buildProgressIndicator('Sahar', 0.5, const Color(0xFF52C41A)),
              ],
            ),
          ),
          // Dropdown arrow
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
      ],
    );
  }







}
