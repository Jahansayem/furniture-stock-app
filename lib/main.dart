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
import 'screens/reports/reports_screen.dart';
import 'screens/reports/location_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/debug/onesignal_test_screen.dart';
import 'screens/debug/onesignal_diagnostic_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'services/onesignal_service.dart';
import 'services/offline_storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: Consumer3<AuthProvider, EnhancedNotificationProvider, ThemeProvider>(
        builder: (context, authProvider, notificationProvider, themeProvider, _) {
          // Initialize theme provider on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeProvider.initialize();
          });
          
          // Initialize realtime subscriptions when user is authenticated
          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notificationProvider.initializeRealtimeSubscription();
              notificationProvider.subscribeToStockChanges();
            });
          }

          return MaterialApp.router(
            title: 'FurniTrack',
            theme: themeProvider.themeData,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
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
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
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

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.inventory,
      label: 'Products',
      route: '/products',
    ),
    NavigationItem(
      icon: Icons.store,
      label: 'Stock',
      route: '/stock',
    ),
    NavigationItem(
      icon: Icons.list_alt,
      label: 'Orders',
      route: '/orders',
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Reports',
      route: '/reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).matchedLocation;
      final index =
          _navigationItems.indexWhere((item) => item.route == currentRoute);
      if (index != -1 && index != _selectedIndex) {
        setState(() {
          _selectedIndex = index;
        });
      }
    });

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
          });
        } else {
          // If on home screen, allow app to exit by calling SystemNavigator.pop()
          // This will properly exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            context.go(_navigationItems[index].route);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: _navigationItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
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
