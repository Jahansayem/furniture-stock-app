import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class StockOverviewScreen extends StatelessWidget {
  const StockOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Stock Overview'),
      ),
      body: const Center(
        child: Text('Stock Overview Screen - Coming Soon'),
      ),
    );
  }
}

