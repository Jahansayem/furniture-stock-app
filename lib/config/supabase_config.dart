class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://rcfhwkiusmupbasprqjr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZmh3a2l1c211cGJhc3BycWpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTczMTgsImV4cCI6MjA2OTczMzMxOH0.QyBcrMvBvc5E9bkN-oyTT9Uh86zZ-cPKcaUmSg-D_ZU';

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
