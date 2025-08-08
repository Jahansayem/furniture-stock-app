import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TODO: Implement product management functionality
  // - Add products
  // - Update products
  // - Delete products
  // - Fetch products from Supabase
}

