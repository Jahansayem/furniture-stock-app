import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:furniture_stock_app/main.dart';

void main() {
  testWidgets('App builds to Login screen (smoke test)', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase with dummy values to satisfy providers in tests.
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // If already initialized in prior tests, ignore.
    }

    // Build the app and allow routing to settle.
    await tester.pumpWidget(const FurnitureStockApp());
    await tester.pumpAndSettle();

    // Expect to see the Login screen primary action.
    expect(find.text('Sign In'), findsWidgets);
  });
}
