import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Listen for auth state changes instead of polling
    authProvider.addListener(_onAuthStateChanged);
    
    // If already loaded, navigate immediately
    if (!authProvider.isLoading) {
      _navigateBasedOnAuthState(authProvider);
    }
  }

  void _onAuthStateChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only navigate when loading is complete
    if (!authProvider.isLoading && mounted) {
      _navigateBasedOnAuthState(authProvider);
    }
  }

  void _navigateBasedOnAuthState(AuthProvider authProvider) {
    // Remove listener to prevent memory leaks
    authProvider.removeListener(_onAuthStateChanged);
    
    if (mounted) {
      if (authProvider.isAuthenticated) {
        context.go('/orders');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    // Clean up listener in case it wasn't removed
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_onAuthStateChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chair,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Furniture Stock Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}