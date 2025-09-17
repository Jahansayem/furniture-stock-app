import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager with multiple fallback sources
/// This class ensures configuration is never lost even during AI coding sessions
class Environment {
  static bool _isInitialized = false;
  
  /// Initialize the environment configuration
  /// Should be called early in app lifecycle
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Attempt to load .env file
      await dotenv.load(fileName: ".env");
      if (kDebugMode) {
        print('✅ Environment: Successfully loaded .env file');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Environment: Could not load .env file: $e');
        print('📝 Environment: Using fallback configuration sources');
      }
    }
    
    _isInitialized = true;
    
    // Validate critical environment variables
    _validateConfiguration();
  }
  
  /// Helper method to get environment variable from --dart-define
  static String _getFromEnvironment(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY');
      case 'ONESIGNAL_APP_ID':
        return const String.fromEnvironment('ONESIGNAL_APP_ID');
      case 'SMS_API_KEY':
        return const String.fromEnvironment('SMS_API_KEY');
      case 'SMS_SENDER_ID':
        return const String.fromEnvironment('SMS_SENDER_ID');
      default:
        return '';
    }
  }

  /// Get environment variable with multiple fallback sources
  static String? _getEnvVar(String key) {
    // Source 1: DotEnv file (primary)
    String? value = dotenv.env[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    
    // Source 2: --dart-define flags (secondary)
    value = _getFromEnvironment(key);
    if (value.isNotEmpty) {
      return value;
    }
    
    // Source 3: Hardcoded fallbacks (emergency only - for your specific project)
    return _getHardcodedFallback(key);
  }
  
  /// Hardcoded fallbacks for critical environment variables
  /// These are your specific credentials that won't get deleted
  static String? _getHardcodedFallback(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return 'https://rcfhwkiusmupbasprqjr.supabase.co';
      case 'SUPABASE_ANON_KEY':
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZmh3a2l1c211cGJhc3BycWpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTczMTgsImV4cCI6MjA2OTczMzMxOH0.QyBcrMvBvc5E9bkN-oyTT9Uh86zZ-cPKcaUmSg-D_ZU';
      case 'SMS_API_KEY':
        return '0PZE9ZsVOBNCjRuT4Ybs';
      case 'SMS_SENDER_ID':
        return '8809617611031';
      default:
        return null;
    }
  }
  
  /// Validate that all critical configuration is present
  static void _validateConfiguration() {
    final criticalVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
    final missingVars = <String>[];
    
    for (final varName in criticalVars) {
      final value = _getEnvVar(varName);
      if (value == null || value.isEmpty) {
        missingVars.add(varName);
      }
    }
    
    if (missingVars.isEmpty) {
      if (kDebugMode) {
        print('✅ Environment: All critical variables configured');
      }
    } else {
      if (kDebugMode) {
        print('❌ Environment: Missing variables: ${missingVars.join(', ')}');
      }
    }
  }
  
  /// Get Supabase URL from any available source
  static String get supabaseUrl {
    final url = _getEnvVar('SUPABASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in any configuration source');
    }
    return url;
  }
  
  /// Get Supabase anonymous key from any available source
  static String get supabaseAnonKey {
    final key = _getEnvVar('SUPABASE_ANON_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in any configuration source');
    }
    return key;
  }
  
  /// Get OneSignal app ID (optional)
  static String get onesignalAppId {
    return _getEnvVar('ONESIGNAL_APP_ID') ?? '';
  }
  
  /// Get SMS API key from any available source
  static String get smsApiKey {
    return _getEnvVar('SMS_API_KEY') ?? '0PZE9ZsVOBNCjRuT4Ybs';
  }
  
  /// Get SMS sender ID from any available source
  static String get smsSenderId {
    return _getEnvVar('SMS_SENDER_ID') ?? 'FurniTrack';
  }
  
  /// Check if environment is properly initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get configuration source info for debugging
  static Map<String, String> getConfigurationInfo() {
    return {
      'supabase_url_source': _getConfigSource('SUPABASE_URL'),
      'supabase_key_source': _getConfigSource('SUPABASE_ANON_KEY'),
      'onesignal_source': _getConfigSource('ONESIGNAL_APP_ID'),
      'sms_api_key_source': _getConfigSource('SMS_API_KEY'),
      'sms_sender_id_source': _getConfigSource('SMS_SENDER_ID'),
    };
  }
  
  /// Get the source of a configuration value for debugging
  static String _getConfigSource(String key) {
    // Check DotEnv first
    if (dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty) {
      return '.env file';
    }
    
    // Check dart-define
    final value = _getFromEnvironment(key);
    if (value.isNotEmpty) {
      return '--dart-define flag';
    }
    
    // Check hardcoded fallback
    if (_getHardcodedFallback(key) != null) {
      return 'hardcoded fallback';
    }
    
    return 'not found';
  }
  
  /// Create or restore .env file with current configuration
  static String generateEnvFileContent() {
    return '''
SUPABASE_URL=$supabaseUrl
SUPABASE_ANON_KEY=$supabaseAnonKey
ONESIGNAL_APP_ID=$onesignalAppId
SMS_API_KEY=$smsApiKey
SMS_SENDER_ID=$smsSenderId

# Usage: This file is automatically loaded by the app
# No need for --dart-define flags anymore!
#
# IMPORTANT: DO NOT DELETE THIS FILE
# This file contains your Supabase credentials and is protected from AI coding sessions

''';
  }
}