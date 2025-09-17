import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // BulkSMSBD Configuration
  static const String _baseUrl = 'http://bulksmsbd.net/api/smsapi';
  
  // API credentials from documentation
  static const String _apiKey = '0PZE9ZsVOBNCjRuT4Ybs';
  static const String _senderId = '8809617611031';
  
  // SMS Templates
  static const String _orderConfirmationTemplate = 
      'Dear {customerName}, your order #{orderId} for {productName} (Qty: {quantity}) has been received. Total: ৳{amount}. Thank you for choosing us!';
  
  static const String _courierDispatchTemplate = 
      'Dear {customerName}, your order #{orderId} has been dispatched via courier. Expected delivery: 3-4 working days. Tracking: {trackingCode}. Thank you!';

  static const String _orderCancellationTemplate = 
      'দুঃখিত {customerName}, আপনার সোফা ({amount} টাকার) অর্ডারটি বাতিল হলো। বিস্তারিত জানতে যোগাযোগ করুন: 01798139179, 01707346634 - আধুনিক ফার্নিচার।';

  // Bengali SMS Templates for specific business requirements
  static const String _bengaliOrderReceiveSMSTemplate = 
      'আধুনিক ফার্নিচার: {customerName}, আপনার সোফা অর্ডারটি রিসিভ হয়েছে। বুকিংয়ের আগে কল করা হবে। যোগাযোগ: 01798139179, 01707346634।';
      
  static const String _bengaliCourierDispatchSMSTemplate = 
      'আধুনিক ফার্নিচার: প্রিয় {customerName}, আপনার ৳{amount} টাকার সোফার অর্ডারটি স্টেডফাস্ট কুরিয়ারে বুকিং দেওয়া হয়েছে। ট্র্যাকিং আইডি: {trackingId}। আপনার পার্সেলটি নিকটস্থ অফিসে পৌঁছালে কুরিয়ারের প্রতিনিধি আপনাকে প্রোডাক্টটি নিয়ে যাওয়ার জন্য কল করবেন। যোগাযোগ: 01798139179, 01707346634।';
      
  static const String _bengaliOrderCancellationSMSTemplate = 
      'আধুনিক ফার্নিচার:\nহ্যালো {customerName}, আপনার সোফা অর্ডারটি কুরিয়ারে বুকিং এর জন্য প্রস্তুত ! আমরা কনফার্মেশনের জন্য কল দিয়েছিলাম, কিন্তু সম্ভবত আপনি ব্যস্ত ছিলেন। অনুগ্রহ করে আমাদের কল করে অর্ডারটি নিশ্চিত করুন,অন্যথায় অর্ডারটি হোল্ডে থাকবে।\nধন্যবাদ। যোগাযোগ করুন: 01798139179, 01707346634';

  /// Send order confirmation SMS
  Future<bool> sendOrderConfirmationSMS({
    required String customerName,
    required String customerPhone,
    required String orderId,
    required String productName,
    required int quantity,
    required double amount,
  }) async {
    try {
      AppLogger.info('Sending order confirmation SMS to: $customerPhone');
      
      final message = _orderConfirmationTemplate
          .replaceAll('{customerName}', customerName)
          .replaceAll('{orderId}', orderId)
          .replaceAll('{productName}', productName)
          .replaceAll('{quantity}', quantity.toString())
          .replaceAll('{amount}', amount.toStringAsFixed(2));
      
      return await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'order_confirmation',
      );
    } catch (e) {
      AppLogger.error('Failed to send order confirmation SMS', error: e);
      return false;
    }
  }

  /// Send courier dispatch SMS
  Future<bool> sendCourierDispatchSMS({
    required String customerName,
    required String customerPhone,
    required String orderId,
    required String trackingCode,
  }) async {
    try {
      AppLogger.info('Sending courier dispatch SMS to: $customerPhone');
      
      final message = _courierDispatchTemplate
          .replaceAll('{customerName}', customerName)
          .replaceAll('{orderId}', orderId)
          .replaceAll('{trackingCode}', trackingCode);
      
      return await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'courier_dispatch',
      );
    } catch (e) {
      AppLogger.error('Failed to send courier dispatch SMS', error: e);
      return false;
    }
  }

  /// Send order cancellation SMS
  Future<bool> sendOrderCancellationSMS({
    required String customerName,
    required String customerPhone,
    required String orderId,
    required String productName,
    required double amount,
  }) async {
    try {
      AppLogger.info('Sending order cancellation SMS to: $customerPhone');
      
      final message = _orderCancellationTemplate
          .replaceAll('{customerName}', customerName)
          .replaceAll('{amount}', amount.toStringAsFixed(0));
      
      return await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'order_cancellation',
      );
    } catch (e) {
      AppLogger.error('Failed to send order cancellation SMS', error: e);
      return false;
    }
  }

  /// Send custom SMS message
  Future<bool> sendCustomSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      AppLogger.info('Sending custom SMS to: $phoneNumber');
      
      return await _sendSMS(
        phoneNumber: phoneNumber,
        message: message,
        messageType: 'custom',
      );
    } catch (e) {
      AppLogger.error('Failed to send custom SMS', error: e);
      return false;
    }
  }

  /// Send Bengali order receive SMS (when new order is created)
  Future<bool> sendBengaliOrderReceiveSMS({
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      AppLogger.info('Sending Bengali order receive SMS to: $customerPhone');
      
      final message = _bengaliOrderReceiveSMSTemplate
          .replaceAll('{customerName}', customerName);
      
      return await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'bengali_order_receive',
      );
    } catch (e) {
      AppLogger.error('Failed to send Bengali order receive SMS', error: e);
      return false;
    }
  }

  /// Send Bengali courier dispatch SMS (when order sent to Steadfast)
  Future<bool> sendBengaliCourierDispatchSMS({
    required String customerName,
    required String customerPhone,
    required double amount,
    required String trackingId,
  }) async {
    try {
      AppLogger.info('Sending Bengali courier dispatch SMS to: $customerPhone');
      
      final message = _bengaliCourierDispatchSMSTemplate
          .replaceAll('{customerName}', customerName)
          .replaceAll('{amount}', amount.toStringAsFixed(0))
          .replaceAll('{trackingId}', trackingId);
      
      return await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'bengali_courier_dispatch',
      );
    } catch (e) {
      AppLogger.error('Failed to send Bengali courier dispatch SMS', error: e);
      return false;
    }
  }

  /// Send Bengali order cancellation/warning SMS with 16-hour rate limiting
  Future<bool> sendBengaliOrderCancellationSMS({
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      AppLogger.info('Sending Bengali order cancellation SMS to: $customerPhone');
      
      // Check rate limiting for warning SMS (16 hours)
      final canSend = await _checkSMSRateLimit(
        phoneNumber: customerPhone,
        messageType: 'bengali_order_cancellation',
        rateLimitHours: 16,
      );
      
      if (!canSend) {
        AppLogger.warning('Rate limit exceeded: Warning SMS already sent to $customerPhone within last 16 hours');
        return false;
      }
      
      final message = _bengaliOrderCancellationSMSTemplate
          .replaceAll('{customerName}', customerName);
      
      final success = await _sendSMS(
        phoneNumber: customerPhone,
        message: message,
        messageType: 'bengali_order_cancellation',
      );
      
      // Record SMS in history if successfully sent
      if (success) {
        await _recordSMSHistory(
          phoneNumber: customerPhone,
          messageType: 'bengali_order_cancellation',
          messageContent: message,
        );
      }
      
      return success;
    } catch (e) {
      AppLogger.error('Failed to send Bengali order cancellation SMS', error: e);
      return false;
    }
  }

  /// Core SMS sending method
  Future<bool> _sendSMS({
    required String phoneNumber,
    required String message,
    required String messageType,
  }) async {
    try {
      // Validate phone number
      final validatedPhone = _validateAndFormatPhoneNumber(phoneNumber);
      if (validatedPhone == null) {
        AppLogger.error('Invalid phone number format: $phoneNumber');
        return false;
      }

      // If offline, queue the SMS for later processing
      if (!_connectivity.isOnline) {
        AppLogger.warning('Offline: Queueing SMS for later delivery');
        await _queueOfflineSMS(
          phoneNumber: validatedPhone,
          message: message,
          messageType: messageType,
        );
        return true; // Return true for queued SMS
      }

      // Build URL with query parameters (BulkSMSBD API format)
      // URI.replace automatically handles URL encoding for special characters
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'api_key': _apiKey,
          'type': 'text',
          'number': validatedPhone,
          'senderid': _senderId,
          'message': message, // Uri.replace automatically URL encodes this
        },
      );

      AppLogger.info('SMS API URL: $uri');

      // Make API call using GET method as per BulkSMSBD documentation
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('SMS request timeout'),
      );

      AppLogger.info('BulkSMSBD API Response: ${response.statusCode}');
      AppLogger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        AppLogger.debug('SMS API Response Body: $responseBody');
        
        try {
          // Try to parse as JSON first
          final responseData = json.decode(responseBody);
          final code = responseData['response_code'] ?? responseData['status'] ?? responseData['code'];
          
          return _handleSMSResponseCode(code, validatedPhone, responseBody);
        } catch (e) {
          // If JSON parsing fails, try to extract code from text response
          final codeMatch = RegExp(r'\b(\d{3,4})\b').firstMatch(responseBody);
          if (codeMatch != null) {
            final code = int.tryParse(codeMatch.group(1)!);
            return _handleSMSResponseCode(code, validatedPhone, responseBody);
          } else {
            // Fallback: check for success indicators in response text
            final responseText = responseBody.toLowerCase();
            if (responseText.contains('202') || 
                responseText.contains('success') || 
                responseText.contains('submitted')) {
              AppLogger.info('SMS sent successfully (text response): $responseBody');
              return true;
            } else {
              AppLogger.error('SMS failed (text response): $responseBody');
              return false;
            }
          }
        }
      } else {
        AppLogger.error('SMS API HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception in _sendSMS', error: e);
      
      // Queue for retry if it's a network issue
      if (e.toString().contains('timeout') || e.toString().contains('network')) {
        AppLogger.warning('Network issue: Queueing SMS for retry');
        await _queueOfflineSMS(
          phoneNumber: phoneNumber,
          message: message,
          messageType: messageType,
        );
      }
      
      return false;
    }
  }

  /// Handle BulkSMSBD response codes based on official documentation
  bool _handleSMSResponseCode(dynamic code, String phoneNumber, String responseBody) {
    final responseCode = code is String ? int.tryParse(code) : code as int?;
    
    switch (responseCode) {
      case 202:
        AppLogger.info('✅ SMS sent successfully to $phoneNumber (Code: 202)');
        return true;
        
      case 1001:
        AppLogger.error('❌ SMS failed - Invalid Number: $phoneNumber (Code: 1001)');
        return false;
        
      case 1002:
        AppLogger.error('❌ SMS failed - Sender ID not correct/disabled (Code: 1002)');
        return false;
        
      case 1003:
        AppLogger.error('❌ SMS failed - Required fields missing/Contact Administrator (Code: 1003)');
        return false;
        
      case 1005:
        AppLogger.error('❌ SMS failed - Internal Error (Code: 1005)');
        return false;
        
      case 1006:
        AppLogger.error('❌ SMS failed - Balance Validity Not Available (Code: 1006)');
        return false;
        
      case 1007:
        AppLogger.error('❌ SMS failed - Balance Insufficient (Code: 1007)');
        return false;
        
      case 1011:
        AppLogger.error('❌ SMS failed - User ID not found (Code: 1011)');
        return false;
        
      case 1012:
        AppLogger.error('❌ SMS failed - Masking SMS must be sent in Bengali (Code: 1012)');
        return false;
        
      case 1013:
        AppLogger.error('❌ SMS failed - Sender ID has no gateway by API key (Code: 1013)');
        return false;
        
      case 1014:
        AppLogger.error('❌ SMS failed - Sender Type Name not found (Code: 1014)');
        return false;
        
      case 1015:
        AppLogger.error('❌ SMS failed - Sender ID has no valid gateway (Code: 1015)');
        return false;
        
      case 1016:
        AppLogger.error('❌ SMS failed - Sender Type active price info not found (Code: 1016)');
        return false;
        
      case 1017:
        AppLogger.error('❌ SMS failed - Sender Type price info not found (Code: 1017)');
        return false;
        
      case 1018:
        AppLogger.error('❌ SMS failed - Account is disabled (Code: 1018)');
        return false;
        
      case 1019:
        AppLogger.error('❌ SMS failed - Account price is disabled (Code: 1019)');
        return false;
        
      case 1020:
        AppLogger.error('❌ SMS failed - Parent account not found (Code: 1020)');
        return false;
        
      case 1021:
        AppLogger.error('❌ SMS failed - Parent active price not found (Code: 1021)');
        return false;
        
      case 1031:
        AppLogger.error('❌ SMS failed - Account not verified, contact administrator (Code: 1031)');
        return false;
        
      case 1032:
        AppLogger.error('❌ SMS failed - IP not whitelisted (Code: 1032)');
        return false;
        
      default:
        AppLogger.warning('⚠️ SMS response - Unknown code: $responseCode, Response: $responseBody');
        return false;
    }
  }

  /// Validate and format phone number for Bangladesh
  String? _validateAndFormatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Handle different formats
    if (digits.length == 11 && digits.startsWith('01')) {
      // Convert 01XXXXXXXXX to 8801XXXXXXXXX
      return '88$digits';
    } else if (digits.length == 13 && digits.startsWith('880')) {
      // Already in correct format 8801XXXXXXXXX
      return digits;
    } else if (digits.length == 10) {
      // Handle 1XXXXXXXXX format (without leading 0)
      return '8801$digits';
    }
    
    // Invalid format
    AppLogger.error('Invalid phone number format: $phoneNumber (digits: $digits)');
    return null;
  }

  /// Queue SMS for offline processing
  Future<void> _queueOfflineSMS({
    required String phoneNumber,
    required String message,
    required String messageType,
  }) async {
    try {
      final smsData = {
        'phone_number': phoneNumber,
        'message': message,
        'message_type': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await SyncService.addPendingAction(
        'send_sms',
        smsData,
      );
      
      AppLogger.info('SMS queued for offline processing');
    } catch (e) {
      AppLogger.error('Failed to queue offline SMS', error: e);
    }
  }

  /// Process pending SMS messages when online
  Future<void> processPendingSMS() async {
    try {
      if (!_connectivity.isOnline) return;
      
      AppLogger.info('Processing pending SMS messages...');
      // This would be called by SyncService when connectivity is restored
      // Implementation would retrieve pending SMS and send them
    } catch (e) {
      AppLogger.error('Failed to process pending SMS messages', error: e);
    }
  }

  /// Test SMS service connectivity
  Future<bool> testSMSService() async {
    try {
      AppLogger.info('Testing SMS service connectivity...');
      
      if (!_connectivity.isOnline) {
        AppLogger.warning('Cannot test SMS service: offline');
        return false;
      }

      // Send a simple test to validate API connection using GET method
      final testUri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'api_key': _apiKey,
          'type': 'text',
          'number': '8801700000000', // Test number
          'senderid': _senderId,
          'message': 'Test message from FurniTrack',
        },
      );

      AppLogger.info('SMS test URL: $testUri');
      
      final testResponse = await http.get(testUri).timeout(const Duration(seconds: 10));

      AppLogger.info('SMS test response: ${testResponse.statusCode}');
      AppLogger.debug('SMS test response body: ${testResponse.body}');
      
      if (testResponse.statusCode == 200) {
        try {
          final responseData = json.decode(testResponse.body);
          // Check for success response code 202
          if (responseData['response_code'] == 202 || responseData['response_code'] == '202') {
            AppLogger.info('SMS test successful - API is working');
            return true;
          } else {
            AppLogger.warning('SMS test returned non-success code: ${responseData['response_code']}');
            return false;
          }
        } catch (e) {
          // If JSON parsing fails, check for success indicators
          if (testResponse.body.contains('202') || testResponse.body.toLowerCase().contains('success')) {
            AppLogger.info('SMS test successful (text response)');
            return true;
          } else {
            AppLogger.warning('SMS test failed (text response): ${testResponse.body}');
            return false;
          }
        }
      } else {
        AppLogger.error('SMS test failed with HTTP ${testResponse.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.error('SMS service test failed', error: e);
      return false;
    }
  }

  /// Get SMS service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'api_key_configured': _apiKey.isNotEmpty,
      'api_key': _apiKey, // Show actual key for debugging
      'sender_id': _senderId,
      'base_url': _baseUrl,
      'is_online': _connectivity.isOnline,
      'service_active': _apiKey.isNotEmpty && _connectivity.isOnline,
      'expected_format': 'GET request with URL parameters',
    };
  }

  /// Check if SMS can be sent based on rate limiting rules
  Future<bool> _checkSMSRateLimit({
    required String phoneNumber,
    required String messageType,
    required int rateLimitHours,
  }) async {
    try {
      final validatedPhone = _validateAndFormatPhoneNumber(phoneNumber);
      if (validatedPhone == null) return false;

      final cutoffTime = DateTime.now().subtract(Duration(hours: rateLimitHours));
      
      final response = await _supabase
          .from('sms_history')
          .select('id')
          .eq('phone_number', validatedPhone)
          .eq('message_type', messageType)
          .gte('sent_at', cutoffTime.toIso8601String())
          .limit(1);

      // If no records found, SMS can be sent
      return (response as List).isEmpty;
    } catch (e) {
      AppLogger.error('Error checking SMS rate limit', error: e);
      // If error occurs, allow SMS to be sent (fail-safe approach)
      return true;
    }
  }

  /// Record SMS in history table
  Future<void> _recordSMSHistory({
    required String phoneNumber,
    required String messageType,
    required String messageContent,
    int? responseCode,
  }) async {
    try {
      final validatedPhone = _validateAndFormatPhoneNumber(phoneNumber);
      if (validatedPhone == null) return;

      await _supabase.from('sms_history').insert({
        'phone_number': validatedPhone,
        'message_type': messageType,
        'message_content': messageContent,
        'response_code': responseCode,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
      
      AppLogger.debug('SMS history recorded for $validatedPhone');
    } catch (e) {
      AppLogger.error('Error recording SMS history', error: e);
      // Don't fail SMS sending if history recording fails
    }
  }

  /// Get SMS history for a phone number
  Future<List<Map<String, dynamic>>> getSMSHistory({
    required String phoneNumber,
    String? messageType,
    int? limitHours,
  }) async {
    try {
      final validatedPhone = _validateAndFormatPhoneNumber(phoneNumber);
      if (validatedPhone == null) return [];

      var query = _supabase
          .from('sms_history')
          .select('*')
          .eq('phone_number', validatedPhone);

      if (messageType != null) {
        query = query.eq('message_type', messageType);
      }

      if (limitHours != null) {
        final cutoffTime = DateTime.now().subtract(Duration(hours: limitHours));
        query = query.gte('sent_at', cutoffTime.toIso8601String());
      }

      final response = await query.order('sent_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Error fetching SMS history', error: e);
      return [];
    }
  }

  /// Check when the last warning SMS was sent to a number
  Future<DateTime?> getLastWarningSMSTime(String phoneNumber) async {
    try {
      final validatedPhone = _validateAndFormatPhoneNumber(phoneNumber);
      if (validatedPhone == null) return null;

      final response = await _supabase
          .from('sms_history')
          .select('sent_at')
          .eq('phone_number', validatedPhone)
          .eq('message_type', 'bengali_order_cancellation')
          .order('sent_at', ascending: false)
          .limit(1);

      if ((response as List).isNotEmpty) {
        return DateTime.parse(response.first['sent_at']);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching last warning SMS time', error: e);
      return null;
    }
  }

  /// Clean up old SMS history (optional maintenance method)
  Future<void> cleanupOldSMSHistory({int retentionDays = 30}) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: retentionDays));
      
      await _supabase
          .from('sms_history')
          .delete()
          .lt('sent_at', cutoffTime.toIso8601String());
      
      AppLogger.info('Cleaned up SMS history older than $retentionDays days');
    } catch (e) {
      AppLogger.error('Error cleaning up SMS history', error: e);
    }
  }
}

/// SMS response model for structured handling
class SmsResponse {
  final bool success;
  final String message;
  final String? messageId;

  SmsResponse({
    required this.success,
    required this.message,
    this.messageId,
  });

  factory SmsResponse.fromJson(Map<String, dynamic> json) {
    return SmsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageId: json['message_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'message_id': messageId,
    };
  }
}