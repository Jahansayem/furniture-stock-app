import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class StockMovementScreen extends StatelessWidget {
  const StockMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Stock Movement'),
      ),
      body: const Center(
        child: Text('Stock Movement Screen - Coming Soon'),
      ),
    );
  }
}

