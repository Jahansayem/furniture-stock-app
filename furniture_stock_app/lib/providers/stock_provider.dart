import 'package:flutter/material.dart';

class StockProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TODO: Implement stock management functionality
  // - Track stock levels
  // - Move stock between locations
  // - Update stock quantities
  // - Generate stock reports
}

