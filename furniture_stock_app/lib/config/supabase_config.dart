class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://rcfhwkiusmupbasprqjr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZmh3a2l1c211cGJhc3BycWpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTczMTgsImV4cCI6MjA2OTczMzMxOH0.QyBcrMvBvc5E9bkN-oyTT9Uh86zZ-cPKcaUmSg-D_ZU';

  // Storage bucket name for product images
  static const String productImagesBucket = 'product-images';

  // Table names
  static const String profilesTable = 'profiles';
  static const String productsTable = 'products';
  static const String stockTable = 'stock';
  static const String stockMovementsTable = 'stock_movements';
  static const String productionBatchesTable = 'production_batches';
  static const String stockLocationsTable = 'stock_locations';
  static const String notificationsTable = 'notifications';

  // Default location IDs (these will be fetched from the database)
  static String factoryLocationId = '';
  static String showroomLocationId = '';
}
