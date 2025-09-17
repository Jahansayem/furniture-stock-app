import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_config.dart';
import 'config/environment.dart';
import 'models/product.dart';
import 'models/stock.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/enhanced_notification_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/permission_provider.dart';
// import 'providers/analytics_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/products/edit_product_screen.dart';
import 'screens/stock/stock_overview_screen.dart';
import 'screens/stock/stock_movement_screen.dart';
import 'screens/sales/create_sale_screen.dart';
import 'screens/sales/online_cod_order_screen.dart';
import 'screens/orders/order_management_screen.dart';
import 'screens/orders2/orders_dashboard_screen.dart';
import 'screens/orders2/orders_list_screen.dart';
import 'screens/orders2/orders_analytics_screen.dart';
import 'screens/orders2/orders_settings_screen.dart';
import 'screens/orders2/order_details_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/location_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/debug/onesignal_test_screen.dart';
import 'screens/debug/onesignal_diagnostic_screen.dart';
import 'screens/debug/sms_test_screen.dart';
import 'screens/debug/steadfast_test_screen.dart';
// import 'screens/analytics/analytics_dashboard_screen.dart';
// import 'screens/dashboard/owner_dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'services/onesignal_service.dart';
import 'services/offline_storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
// import 'services/alert_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimizations
  // Disable debug banner in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Optimize UI performance for better frame rates
  // Note: Frame timing monitoring can be added if needed for performance debugging

  // Initialize environment configuration first (AI-coding-resistant)
  try {
    await Environment.initialize();
    AppLogger.info('Environment configuration loaded successfully');
    
    // Debug: Print configuration sources
    final configInfo = Environment.getConfigurationInfo();
    AppLogger.info('Configuration sources: $configInfo');
  } catch (e) {
    AppLogger.error('Error initializing environment', error: e);
  }

  // Initialize Supabase with environment-loaded credentials
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    AppLogger.info('Supabase initialized successfully');
  } catch (e) {
    AppLogger.error('Error initializing Supabase', error: e);
    AppLogger.error('Check your Supabase credentials in .env file');
  }

  // Initialize offline storage
  try {
    await OfflineStorageService.initialize();
    AppLogger.info('Offline storage initialized successfully');
  } catch (e) {
    AppLogger.error('Error initializing offline storage', error: e);
  }

  // Initialize connectivity service
  try {
    await ConnectivityService().initialize();
    AppLogger.info('Connectivity service initialized successfully');
  } catch (e) {
    AppLogger.error('Error initializing connectivity service', error: e);
  }

  // Initialize sync service
  try {
    await SyncService().initialize();
    AppLogger.info('Sync service initialized successfully');
  } catch (e) {
    AppLogger.error('Error initializing sync service', error: e);
  }

  // Initialize alert service
  // try {
  //   await AlertService().initialize();
  //   AppLogger.info('Alert service initialized successfully');
  // } catch (e) {
  //   AppLogger.error('Error initializing alert service', error: e);
  // }

  runApp(const FurnitureStockApp());

  // Initialize OneSignal in background after app starts
  _initializeOneSignalInBackground();
}

/// Initialize OneSignal in background to not block app startup
void _initializeOneSignalInBackground() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await OneSignalService.initialize();
      AppLogger.info('OneSignal initialized successfully in background');
    } catch (e) {
      AppLogger.error('Error initializing OneSignal in background', error: e);
      AppLogger.warning('App will continue without push notifications');
    }
  });
}

class FurnitureStockApp extends StatelessWidget {
  const FurnitureStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedNotificationProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        // ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: Consumer3<AuthProvider, ThemeProvider, EnhancedNotificationProvider>(
        builder: (context, authProvider, themeProvider, notificationProvider, _) {
          return _FurnitureStockAppContent(
            authProvider: authProvider,
            themeProvider: themeProvider,
            notificationProvider: notificationProvider,
          );
        },
      ),
    );
  }
}

class _FurnitureStockAppContent extends StatefulWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  final EnhancedNotificationProvider notificationProvider;

  const _FurnitureStockAppContent({
    required this.authProvider,
    required this.themeProvider,
    required this.notificationProvider,
  });

  @override
  State<_FurnitureStockAppContent> createState() => _FurnitureStockAppContentState();
}

class _FurnitureStockAppContentState extends State<_FurnitureStockAppContent> {
  bool _themeInitialized = false;
  bool _subscriptionsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  void _initializeTheme() {
    if (!widget.themeProvider.isInitialized && !_themeInitialized) {
      _themeInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.themeProvider.initialize();
        }
      });
    }
  }

  void _initializeSubscriptions() {
    if (widget.authProvider.isAuthenticated &&
        !widget.notificationProvider.isSubscriptionActive &&
        !_subscriptionsInitialized) {
      _subscriptionsInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.notificationProvider.initializeRealtimeSubscription();
          widget.notificationProvider.subscribeToStockChanges();

          // Initialize permission provider with user ID
          final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
          if (widget.authProvider.user?.id != null && !permissionProvider.isInitialized) {
            permissionProvider.initialize(widget.authProvider.user!.id);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if subscriptions need initialization
    if (widget.authProvider.isAuthenticated && !_subscriptionsInitialized) {
      _initializeSubscriptions();
    }

    return MaterialApp.router(
      title: 'FurniTrack',
      theme: widget.themeProvider.themeData,
      routerConfig: _createRouter(widget.authProvider),
      debugShowCheckedModeBanner: false,
      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // Prevent text scaling issues
          ),
          child: child!,
        );
      },
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final isSplash = state.matchedLocation == '/';

        // If loading, don't redirect yet
        if (authProvider.isLoading && !isSplash) {
          return null;
        }

        // Skip splash screen after initial load
        if (isSplash && !authProvider.isLoading) {
          return isAuthenticated ? '/home' : '/login';
        }

        if (!isAuthenticated && !isLoggingIn && !isSplash) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductListScreen(),
            ),
            GoRoute(
              path: '/products/add',
              builder: (context, state) => const AddProductScreen(),
            ),
            GoRoute(
              path: '/products/edit',
              builder: (context, state) {
                final product = state.extra as Product;
                return EditProductScreen(product: product);
              },
            ),
            GoRoute(
              path: '/stock',
              builder: (context, state) => const StockOverviewScreen(),
            ),
            GoRoute(
              path: '/stock/movement',
              builder: (context, state) => const StockMovementScreen(),
            ),
            GoRoute(
              path: '/sales/create',
              builder: (context, state) => const CreateSaleScreen(),
            ),
            GoRoute(
              path: '/sales/online-cod',
              builder: (context, state) => const OnlineCodOrderScreen(),
            ),
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrderManagementScreen(),
            ),
            GoRoute(
              path: '/orders2',
              builder: (context, state) => const OrdersDashboardScreen(),
            ),
            GoRoute(
              path: '/orders2/list',
              builder: (context, state) => const OrdersListScreen(),
            ),
            GoRoute(
              path: '/orders2/analytics',
              builder: (context, state) => const OrdersAnalyticsScreen(),
            ),
            GoRoute(
              path: '/orders2/settings',
              builder: (context, state) => const OrdersSettingsScreen(),
            ),
            GoRoute(
              path: '/orders2/details/:orderId',
              builder: (context, state) {
                final orderId = state.pathParameters['orderId']!;
                return OrderDetailsScreen(orderId: orderId);
              },
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
            // GoRoute(
            //   path: '/analytics',
            //   builder: (context, state) => const AnalyticsDashboardScreen(),
            // ),
            // GoRoute(
            //   path: '/dashboard',
            //   builder: (context, state) => const OwnerDashboardScreen(),
            // ),
            GoRoute(
              path: '/reports/location',
              builder: (context, state) {
                final location = state.extra as StockLocation;
                return LocationDetailScreen(location: location);
              },
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationScreen(),
            ),
            GoRoute(
              path: '/debug/onesignal',
              builder: (context, state) => const OneSignalTestScreen(),
            ),
            GoRoute(
              path: '/debug/onesignal-diagnostic',
              builder: (context, state) => const OneSignalDiagnosticScreen(),
            ),
            GoRoute(
              path: '/debug/sms',
              builder: (context, state) => const SmsTestScreen(),
            ),
            GoRoute(
              path: '/debug/steadfast',
              builder: (context, state) => const SteadfastTestScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String _lastRoute = '';
  bool _hasInitialized = false;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.list_alt,
      label: 'Orders',
      route: '/orders',
    ),
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Orders2',
      route: '/orders2',
    ),
    NavigationItem(
      icon: Icons.inventory,
      label: 'Products',
      route: '/products',
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Reports',
      route: '/reports',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize selected index only once or when route actually changes
    if (!_hasInitialized) {
      _updateSelectedIndexFromRoute();
      _hasInitialized = true;
    }
  }

  void _updateSelectedIndexFromRoute() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    // Only update if route actually changed
    if (currentRoute != _lastRoute) {
      final index = _navigationItems.indexWhere((item) => item.route == currentRoute);
      if (index != -1) {
        setState(() {
          _selectedIndex = index;
          _lastRoute = currentRoute;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optimize: Only check route on first build or when necessary
    if (!_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSelectedIndexFromRoute();
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final currentRoute = GoRouterState.of(context).matchedLocation;

        // If not on home screen, navigate to home
        if (currentRoute != '/home') {
          context.go('/home');
          setState(() {
            _selectedIndex = 0; // Dashboard index
            _lastRoute = '/home';
          });
        } else {
          // If on home screen, allow app to exit by calling SystemNavigator.pop()
          // This will properly exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              final targetRoute = _navigationItems[index].route;
              setState(() {
                _selectedIndex = index;
                _lastRoute = targetRoute;
              });
              context.go(targetRoute);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.mediumGrey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            items: _navigationItems.map((item) {
              return BottomNavigationBarItem(
                icon: Icon(item.icon, size: 24),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(item.icon, size: 24),
                ),
                label: item.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}