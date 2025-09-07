import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/steadfast_config.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/logger.dart';

class SteadFastService {
  static final SteadFastService _instance = SteadFastService._internal();
  factory SteadFastService() => _instance;
  SteadFastService._internal();

  final ConnectivityService _connectivity = ConnectivityService();

  /// Create a courier order with Steadfast API
  Future<SteadFastOrderResponse?> createOrder({
    required String invoice,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required double codAmount,
    String? notes,
  }) async {
    try {
      AppLogger.info('Creating Steadfast order for invoice: $invoice');

      // Validate input parameters
      if (!_validateOrderParams(
        invoice: invoice,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        recipientAddress: recipientAddress,
        codAmount: codAmount,
      )) {
        return null;
      }

      // If offline, queue the order for later processing
      if (!_connectivity.isOnline) {
        AppLogger.warning('Offline: Queueing Steadfast order for sync');
        await _queueOfflineOrder(
          invoice: invoice,
          recipientName: recipientName,
          recipientPhone: recipientPhone,
          recipientAddress: recipientAddress,
          codAmount: codAmount,
          notes: notes,
        );
        return SteadFastOrderResponse(
          success: true,
          consignmentId: 'PENDING_OFFLINE',
          message: 'Order queued for processing when online',
        );
      }

      // Prepare request payload
      final payload = {
        'invoice': invoice,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'recipient_address': recipientAddress,
        'cod_amount': codAmount,
        if (notes?.isNotEmpty == true) 'note': notes,
      };

      // Make API call
      final url = Uri.parse('${SteadFastConfig.baseUrl}${SteadFastConfig.createOrderEndpoint}');
      final response = await http.post(
        url,
        headers: SteadFastConfig.headers,
        body: json.encode(payload),
      );

      AppLogger.info('Steadfast API Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 200) {
          final consignmentId = responseData['consignment']['consignment_id']?.toString();
          
          if (consignmentId != null) {
            AppLogger.info('Steadfast order created successfully: $consignmentId');
            return SteadFastOrderResponse(
              success: true,
              consignmentId: consignmentId,
              trackingCode: responseData['consignment']['tracking_code']?.toString(),
              message: responseData['message'] ?? 'Order created successfully',
            );
          } else {
            AppLogger.error('Missing consignment_id in response');
            return SteadFastOrderResponse(
              success: false,
              message: 'Invalid response: missing consignment ID',
            );
          }
        } else {
          final message = responseData['message'] ?? 'Unknown error occurred';
          AppLogger.error('Steadfast API error: $message');
          return SteadFastOrderResponse(
            success: false,
            message: message,
          );
        }
      } else {
        AppLogger.error('Steadfast API HTTP error: ${response.statusCode} - ${response.body}');
        return SteadFastOrderResponse(
          success: false,
          message: 'API request failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Exception in createOrder', error: e);
      return SteadFastOrderResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Check delivery status by consignment ID
  Future<SteadFastStatusResponse?> checkStatus({
    String? consignmentId,
    String? invoice,
    String? trackingCode,
  }) async {
    try {
      if (consignmentId == null && invoice == null && trackingCode == null) {
        AppLogger.error('At least one identifier required for status check');
        return null;
      }

      if (!_connectivity.isOnline) {
        AppLogger.warning('Offline: Cannot check courier status');
        return SteadFastStatusResponse(
          success: false,
          message: 'Cannot check status while offline',
        );
      }

      String endpoint;
      if (consignmentId != null) {
        endpoint = '${SteadFastConfig.statusByCidEndpoint}/$consignmentId';
      } else if (invoice != null) {
        endpoint = '${SteadFastConfig.statusByInvoiceEndpoint}/$invoice';
      } else {
        endpoint = '${SteadFastConfig.statusByTrackingEndpoint}/$trackingCode';
      }

      final url = Uri.parse('${SteadFastConfig.baseUrl}$endpoint');
      final response = await http.get(url, headers: SteadFastConfig.headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        AppLogger.debug('SteadFast status response: ${response.body}');
        
        if (responseData['status'] == 200) {
          final delivery = responseData['delivery'];
          
          // Check if delivery object exists
          if (delivery != null) {
            return SteadFastStatusResponse(
              success: true,
              status: delivery['delivery_status']?.toString(),
              message: delivery['current_status']?.toString() ?? 'Status updated',
              deliveryDate: delivery['delivery_date']?.toString(),
              note: delivery['note']?.toString(),
            );
          } else {
            return SteadFastStatusResponse(
              success: false,
              message: 'No delivery information available',
            );
          }
        } else {
          AppLogger.error('SteadFast API returned non-success status: ${responseData['status']}');
          return SteadFastStatusResponse(
            success: false,
            message: responseData['message']?.toString() ?? 'API returned error status',
          );
        }
      } else {
        AppLogger.error('SteadFast API HTTP error: ${response.statusCode} - ${response.body}');
        return SteadFastStatusResponse(
          success: false,
          message: 'HTTP ${response.statusCode}: Failed to check status',
        );
      }

      return SteadFastStatusResponse(
        success: false,
        message: 'Failed to check status',
      );
    } catch (e) {
      AppLogger.error('Exception in checkStatus', error: e);
      return SteadFastStatusResponse(
        success: false,
        message: 'Error checking status: ${e.toString()}',
      );
    }
  }

  /// Check current account balance
  Future<SteadFastBalanceResponse?> getBalance() async {
    try {
      if (!_connectivity.isOnline) {
        AppLogger.warning('Offline: Cannot check balance');
        return null;
      }

      final url = Uri.parse('${SteadFastConfig.baseUrl}${SteadFastConfig.balanceEndpoint}');
      final response = await http.get(url, headers: SteadFastConfig.headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 200) {
          return SteadFastBalanceResponse(
            success: true,
            currentBalance: responseData['current_balance']?.toDouble() ?? 0.0,
            message: responseData['message'] ?? 'Balance retrieved successfully',
          );
        }
      }

      return SteadFastBalanceResponse(
        success: false,
        message: 'Failed to retrieve balance',
      );
    } catch (e) {
      AppLogger.error('Exception in getBalance', error: e);
      return SteadFastBalanceResponse(
        success: false,
        message: 'Error retrieving balance: ${e.toString()}',
      );
    }
  }

  /// Validate order parameters
  bool _validateOrderParams({
    required String invoice,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required double codAmount,
  }) {
    if (invoice.isEmpty) {
      AppLogger.error('Invoice cannot be empty');
      return false;
    }

    if (recipientName.isEmpty || recipientName.length > SteadFastConfig.maxRecipientNameLength) {
      AppLogger.error('Invalid recipient name: length must be 1-${SteadFastConfig.maxRecipientNameLength} characters');
      return false;
    }

    if (recipientPhone.length != SteadFastConfig.phoneNumberLength || !RegExp(r'^\d{11}$').hasMatch(recipientPhone)) {
      AppLogger.error('Invalid phone number: must be exactly ${SteadFastConfig.phoneNumberLength} digits');
      return false;
    }

    if (recipientAddress.isEmpty || recipientAddress.length > SteadFastConfig.maxAddressLength) {
      AppLogger.error('Invalid address: length must be 1-${SteadFastConfig.maxAddressLength} characters');
      return false;
    }

    if (codAmount < 0) {
      AppLogger.error('COD amount cannot be negative');
      return false;
    }

    return true;
  }

  /// Queue courier order for offline processing
  Future<void> _queueOfflineOrder({
    required String invoice,
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required double codAmount,
    String? notes,
  }) async {
    try {
      final orderData = {
        'invoice': invoice,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'recipient_address': recipientAddress,
        'cod_amount': codAmount,
        if (notes?.isNotEmpty == true) 'note': notes,
      };

      await SyncService.addPendingAction(
        'create_courier_order',
        orderData,
      );
    } catch (e) {
      AppLogger.error('Failed to queue offline courier order', error: e);
    }
  }

  /// Process pending courier orders when online
  Future<void> processPendingOrders() async {
    try {
      if (!_connectivity.isOnline) return;
      
      AppLogger.info('Processing pending courier orders...');
      // This would be called by SyncService when connectivity is restored
      // Implementation would retrieve pending courier orders and process them
    } catch (e) {
      AppLogger.error('Failed to process pending courier orders', error: e);
    }
  }
}

/// Response model for courier order creation
class SteadFastOrderResponse {
  final bool success;
  final String? consignmentId;
  final String? trackingCode;
  final String message;

  SteadFastOrderResponse({
    required this.success,
    this.consignmentId,
    this.trackingCode,
    required this.message,
  });

  factory SteadFastOrderResponse.fromJson(Map<String, dynamic> json) {
    return SteadFastOrderResponse(
      success: json['success'] ?? false,
      consignmentId: json['consignment_id']?.toString(),
      trackingCode: json['tracking_code']?.toString(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'consignment_id': consignmentId,
      'tracking_code': trackingCode,
      'message': message,
    };
  }
}

/// Response model for delivery status
class SteadFastStatusResponse {
  final bool success;
  final String? status;
  final String message;
  final String? deliveryDate;
  final String? note;

  SteadFastStatusResponse({
    required this.success,
    this.status,
    required this.message,
    this.deliveryDate,
    this.note,
  });

  factory SteadFastStatusResponse.fromJson(Map<String, dynamic> json) {
    return SteadFastStatusResponse(
      success: json['success'] ?? false,
      status: json['status']?.toString(),
      message: json['message'] ?? '',
      deliveryDate: json['delivery_date']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status,
      'message': message,
      'delivery_date': deliveryDate,
      'note': note,
    };
  }
}

/// Response model for balance inquiry
class SteadFastBalanceResponse {
  final bool success;
  final double currentBalance;
  final String message;

  SteadFastBalanceResponse({
    required this.success,
    this.currentBalance = 0.0,
    required this.message,
  });

  factory SteadFastBalanceResponse.fromJson(Map<String, dynamic> json) {
    return SteadFastBalanceResponse(
      success: json['success'] ?? false,
      currentBalance: json['current_balance']?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'current_balance': currentBalance,
      'message': message,
    };
  }
}