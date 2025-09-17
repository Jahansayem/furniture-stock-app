import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

class WebhookHandler {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Handle Steadfast webhook notifications
  static Future<Map<String, dynamic>> handleSteadfastWebhook(
    Map<String, dynamic> webhookData
  ) async {
    try {
      AppLogger.info('Received Steadfast webhook: ${jsonEncode(webhookData)}');
      
      final notificationType = webhookData['notification_type'];
      
      switch (notificationType) {
        case 'delivery_status':
          return await _handleDeliveryStatusUpdate(webhookData);
        case 'tracking_update':
          return await _handleTrackingUpdate(webhookData);
        default:
          AppLogger.warning('Unknown webhook notification type: $notificationType');
          return {
            'status': 'error',
            'message': 'Unknown notification type'
          };
      }
    } catch (e) {
      AppLogger.error('Error handling Steadfast webhook', error: e);
      return {
        'status': 'error',
        'message': 'Webhook processing failed: ${e.toString()}'
      };
    }
  }

  /// Handle delivery status updates
  static Future<Map<String, dynamic>> _handleDeliveryStatusUpdate(
    Map<String, dynamic> webhookData
  ) async {
    try {
      final consignmentId = webhookData['consignment_id']?.toString();
      final invoice = webhookData['invoice']?.toString();
      final status = webhookData['status']?.toString();
      final trackingMessage = webhookData['tracking_message']?.toString();
      final updatedAt = webhookData['updated_at']?.toString();
      final deliveryCharge = webhookData['delivery_charge'];
      
      if (consignmentId == null) {
        return {
          'status': 'error',
          'message': 'Missing consignment_id'
        };
      }

      AppLogger.info('Updating delivery status for consignment $consignmentId to $status');

      // Update the sale record in database
      final updateData = <String, dynamic>{
        'courier_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add delivery date if delivered
      if (status == 'delivered') {
        updateData['delivery_date'] = updatedAt ?? DateTime.now().toIso8601String();
      }

      // Add delivery charge if provided
      if (deliveryCharge != null) {
        updateData['delivery_charge'] = deliveryCharge;
      }

      // Update by consignment_id
      final result = await _supabase
          .from(SupabaseConfig.salesTable)
          .update(updateData)
          .eq('consignment_id', consignmentId);

      AppLogger.info('Updated sale record for consignment $consignmentId');

      return {
        'status': 'success',
        'message': 'Delivery status updated successfully'
      };
    } catch (e) {
      AppLogger.error('Error handling delivery status update', error: e);
      return {
        'status': 'error',
        'message': 'Failed to update delivery status: ${e.toString()}'
      };
    }
  }

  /// Handle tracking updates
  static Future<Map<String, dynamic>> _handleTrackingUpdate(
    Map<String, dynamic> webhookData
  ) async {
    try {
      final consignmentId = webhookData['consignment_id']?.toString();
      final trackingMessage = webhookData['tracking_message']?.toString();
      final updatedAt = webhookData['updated_at']?.toString();

      if (consignmentId == null) {
        return {
          'status': 'error',
          'message': 'Missing consignment_id'
        };
      }

      AppLogger.info('Tracking update for consignment $consignmentId: $trackingMessage');

      // For tracking updates, we can log them or store in a tracking history table
      // For now, just log the update
      AppLogger.info('Tracking message: $trackingMessage');

      return {
        'status': 'success',
        'message': 'Tracking update received successfully'
      };
    } catch (e) {
      AppLogger.error('Error handling tracking update', error: e);
      return {
        'status': 'error',
        'message': 'Failed to process tracking update: ${e.toString()}'
      };
    }
  }

  /// Validate webhook authenticity (if Steadfast provides signature)
  static bool validateWebhookSignature(
    Map<String, String> headers,
    String payload,
    String secretKey
  ) {
    // Implement signature validation if Steadfast provides it
    // This is a placeholder for now
    return true;
  }
}

/// Webhook data models for type safety
class SteadfastDeliveryWebhook {
  final String notificationType;
  final int consignmentId;
  final String invoice;
  final double codAmount;
  final String status;
  final double deliveryCharge;
  final String trackingMessage;
  final String updatedAt;

  SteadfastDeliveryWebhook({
    required this.notificationType,
    required this.consignmentId,
    required this.invoice,
    required this.codAmount,
    required this.status,
    required this.deliveryCharge,
    required this.trackingMessage,
    required this.updatedAt,
  });

  factory SteadfastDeliveryWebhook.fromJson(Map<String, dynamic> json) {
    return SteadfastDeliveryWebhook(
      notificationType: json['notification_type'] ?? '',
      consignmentId: json['consignment_id'] ?? 0,
      invoice: json['invoice'] ?? '',
      codAmount: (json['cod_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      trackingMessage: json['tracking_message'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class SteadfastTrackingWebhook {
  final String notificationType;
  final int consignmentId;
  final String invoice;
  final String trackingMessage;
  final String updatedAt;

  SteadfastTrackingWebhook({
    required this.notificationType,
    required this.consignmentId,
    required this.invoice,
    required this.trackingMessage,
    required this.updatedAt,
  });

  factory SteadfastTrackingWebhook.fromJson(Map<String, dynamic> json) {
    return SteadfastTrackingWebhook(
      notificationType: json['notification_type'] ?? '',
      consignmentId: json['consignment_id'] ?? 0,
      invoice: json['invoice'] ?? '',
      trackingMessage: json['tracking_message'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}