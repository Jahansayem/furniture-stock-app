import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/sync_service.dart';
import '../../services/connectivity_service.dart';

import '../../utils/app_theme.dart';

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
      print('Error loading initial data: $e');
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
    Future.microtask(() => stockProvider.fetchLocations());

    await Future.delayed(const Duration(milliseconds: 200));
    Future.microtask(() => stockProvider.fetchMovements());

    await Future.delayed(const Duration(milliseconds: 200));
    Future.microtask(() => salesProvider.fetchSales());

    await Future.delayed(const Duration(milliseconds: 200));
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
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      context.go('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
                    // Welcome Section
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.userProfile;
                        final authUser = authProvider.user;

                        // Get first and last name from user profile or fallback to email
                        String displayName = 'User';
                        if (user != null && user.fullName != null) {
                          final nameParts = user.fullName!.trim().split(' ');
                          if (nameParts.length >= 2) {
                            displayName =
                                '${nameParts.first} ${nameParts.last}';
                          } else if (nameParts.isNotEmpty) {
                            displayName = nameParts.first;
                          } else {
                            displayName = user.displayName;
                          }
                        } else if (authUser?.email != null) {
                          displayName = authUser!.email!.split('@')[0];
                        }

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.lightBlue
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withAlpha(76),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user?.roleDisplayName ?? 'Staff',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildBackupButton(context),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats
                    Consumer2<ProductProvider, StockProvider>(
                      builder:
                          (context, productProvider, stockProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Overview',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.darkBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildClickableStatCard(
                                    context,
                                    'প্রোডাক্ট লিস্ট',
                                    '${productProvider.products.length}',
                                    Icons.inventory_2,
                                    AppColors.info,
                                    () => context.go('/products'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildClickableStatCard(
                                    context,
                                    'স্টক কম আইটেম',
                                    '${stockProvider.getLowStockCount(productProvider.products)}',
                                    Icons.warning,
                                    AppColors.warning,
                                    () => context
                                        .go('/products?filter=low_stock'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildClickableStatCard(
                                    context,
                                    'ফ্যাক্টরি স্টক',
                                    '${stockProvider.factoryStockCount}',
                                    Icons.factory,
                                    AppColors.production,
                                    () => context.go('/stock?filter=factory'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildClickableStatCard(
                                    context,
                                    'শোরুম স্টক',
                                    '${stockProvider.showroomStockCount}',
                                    Icons.store,
                                    AppColors.success,
                                    () => context.go('/stock?filter=showroom'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.darkBlue,
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
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          context,
                          'প্রোডাক্ট যুক্ত করুন',
                          Icons.add_box,
                          AppTheme.primaryBlue,
                          () => context.go('/products/add'),
                        ),
                        _buildActionCard(
                          context,
                          'স্টকের হিসাব',
                          Icons.inventory,
                          AppTheme.accentBlue,
                          () => context.go('/stock'),
                        ),
                        _buildActionCard(
                          context,
                          'স্টক ট্র্যান্সফার',
                          Icons.swap_horiz,
                          AppColors.transfer,
                          () => context.go('/stock/movement'),
                        ),
                        _buildActionCard(
                          context,
                          'স্টক রিপোর্ট',
                          Icons.analytics,
                          AppColors.info,
                          () => context.go('/reports'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recent Activity
                    Consumer2<StockProvider, SalesProvider>(
                      builder: (context, stockProvider, salesProvider, child) {
                        // Combine movements and sales into a single activity list
                        final List<ActivityItem> activities = [];

                        // Add stock movements
                        for (final movement
                            in stockProvider.movements.take(10)) {
                          activities.add(ActivityItem(
                            type: 'movement',
                            title: _getMovementDescription(movement),
                            subtitle: _formatDateTime(movement.createdAt),
                            quantity: movement.quantity,
                            icon: _getMovementIcon(movement.movementType),
                            color: _getMovementColor(movement.movementType),
                            date: movement.createdAt,
                          ));
                        }

                        // Add recent sales
                        for (final sale in salesProvider.sales.take(10)) {
                          activities.add(ActivityItem(
                            type: 'sale',
                            title:
                                'Sale: ${sale.productName} to ${sale.customerName}',
                            subtitle:
                                '${_formatDateTime(sale.saleDate)} - by ${sale.soldByName}',
                            quantity: sale.quantity,
                            icon: Icons.point_of_sale,
                            color: Colors.green,
                            date: sale.saleDate,
                          ));
                        }

                        // Sort by date (most recent first)
                        activities.sort((a, b) => b.date.compareTo(a.date));
                        final recentActivities = activities.take(5).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.darkBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
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
                              child: recentActivities.isEmpty
                                  ? Column(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No recent activity',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        Text(
                                          'Start by adding products, managing stock, or making sales',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[500],
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children:
                                          recentActivities.map((activity) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: activity.color
                                                      .withAlpha(25),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  activity.icon,
                                                  color: activity.color,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      activity.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                    Text(
                                                      activity.subtitle,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${activity.quantity}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: activity.color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
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
    );
  }

  Widget _buildClickableStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
                    fontFamily: 'Tiro Bangla',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tiro Bangla',
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  String _getMovementDescription(dynamic movement) {
    switch (movement.movementType.toLowerCase()) {
      case 'transfer':
        return 'Stock transferred between locations';
      case 'production':
        return 'Production completed';
      case 'adjustment':
        return 'Stock adjustment made';
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
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildBackupButton(BuildContext context) {
    return Consumer2<SyncService, ConnectivityService>(
      builder: (context, syncService, connectivity, child) {
        return ElevatedButton.icon(
          onPressed:
              syncService.isSyncing ? null : () => _performBackup(context),
          icon: syncService.isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  connectivity.isOnline ? Icons.cloud_upload : Icons.cloud_off,
                  size: 18,
                ),
          label: Text(
            syncService.isSyncing ? 'সিঙ্ক হচ্ছে...' : 'ডাটা ব্যাকআপ',
            style: const TextStyle(
              fontFamily: 'Tiro Bangla',
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    final connectivity =
        Provider.of<ConnectivityService>(context, listen: false);

    if (!connectivity.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ইন্টারনেট সংযোগ নেই। অনলাইন হয়ে আবার চেষ্টা করুন।'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('ডাটা ব্যাকআপ শুরু হয়েছে...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await syncService.performBackupSync();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'ডাটা সফলভাবে ব্যাকআপ হয়েছে!'
                : 'ব্যাকআপ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          action: !success
              ? SnackBarAction(
                  label: 'বিস্তারিত',
                  textColor: Colors.white,
                  onPressed: () => _showSyncDetails(context),
                )
              : null,
        ),
      );

      // Refresh data after successful sync
      if (success) {
        await _fetchData();
      }
    }
  }

  void _showSyncDetails(BuildContext context) {
    final syncService = Provider.of<SyncService>(context, listen: false);
    final stats = syncService.getSyncStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('সিঙ্ক বিস্তারিত'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('স্ট্যাটাস: ${stats['syncStatus']}'),
            Text('পেন্ডিং অ্যাকশন: ${stats['pendingActionsCount']}'),
            Text('অনলাইন: ${stats['isOnline'] ? 'হ্যাঁ' : 'না'}'),
            if (stats['syncErrors'].isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('ত্রুটি:'),
              ...stats['syncErrors'].map<Widget>((error) => Text('• $error')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }
}
