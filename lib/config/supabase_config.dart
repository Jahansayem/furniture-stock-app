import 'environment.dart';

class SupabaseConfig {
  // AI-Coding-Resistant Configuration System
  // This now uses Environment class with multiple fallback sources:
  // 1. .env file (primary)
  // 2. --dart-define flags (secondary) 
  // 3. Hardcoded fallbacks (emergency)
  static String get supabaseUrl => Environment.supabaseUrl;
  static String get supabaseAnonKey => Environment.supabaseAnonKey;

  // Storage bucket name for product images
  static const String productImagesBucket = 'product-images';

  // Table names
  static const String productsTable = 'products';
  static const String stockLevelsTable = 'stock_levels';
  static const String stockLocationsTable = 'stock_locations';
  static const String stockMovementsTable = 'stock_movements';
  static const String profilesTable = 'user_profiles';
  static const String notificationsTable = 'notifications';
  static const String productionBatchesTable = 'production_batches';
  static const String salesTable = 'sales';
}
