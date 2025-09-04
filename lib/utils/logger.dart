import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _appName = 'FurniTrack';

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _appName,
        level: 800, // Info level
        time: DateTime.now(),
      );
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _appName,
        level: 900, // Warning level
        time: DateTime.now(),
      );
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _appName,
        level: 1000, // Error level
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _appName,
        level: 700, // Debug level
        time: DateTime.now(),
      );
    }
  }
}