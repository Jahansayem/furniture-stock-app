import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: const Center(
        child: Text('Reports Screen - Coming Soon'),
      ),
    );
  }
}

