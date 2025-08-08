import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: const Center(
        child: Text('Add Product Screen - Coming Soon'),
      ),
    );
  }
}

