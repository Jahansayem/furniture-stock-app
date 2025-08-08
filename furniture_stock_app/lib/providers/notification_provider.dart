import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // TODO: Implement notification functionality
  // - Show low stock alerts
  // - Handle push notifications
  // - Mark notifications as read
  // - Fetch notifications from Supabase
}

