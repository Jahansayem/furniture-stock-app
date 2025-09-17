import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class DeliveryAnalyticsService {
  static final DeliveryAnalyticsService _instance = DeliveryAnalyticsService._internal();
  factory DeliveryAnalyticsService() => _instance;
  DeliveryAnalyticsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get estimated delivery days for a specific area based on historical data
  Future<int> getEstimatedDeliveryDays(String deliveryArea) async {
    try {
      // Extract area components for matching
      final areaKeywords = _extractAreaKeywords(deliveryArea);

      // Query historical delivery data for the area
      final response = await _supabase
          .from('sales')
          .select('sale_date, updated_at, recipient_address, customer_address, courier_status')
          .eq('courier_status', 'delivered')
          .gte('sale_date', DateTime.now().subtract(const Duration(days: 180)).toIso8601String()) // Last 6 months
          .order('sale_date', ascending: false);

      final deliveries = response as List<dynamic>;

      if (deliveries.isEmpty) {
        AppLogger.info('No historical delivery data found, using default estimate');
        return _getDefaultDeliveryDays(deliveryArea);
      }

      // Filter deliveries by area and calculate delivery times
      final areaDeliveries = <Duration>[];

      for (final delivery in deliveries) {
        final address = delivery['recipient_address'] ?? delivery['customer_address'] ?? '';

        if (_isAddressMatch(address, areaKeywords)) {
          final saleDate = DateTime.parse(delivery['sale_date']);
          final deliveryDate = DateTime.parse(delivery['updated_at']);
          final deliveryTime = deliveryDate.difference(saleDate);

          // Only include reasonable delivery times (1-30 days)
          if (deliveryTime.inDays >= 1 && deliveryTime.inDays <= 30) {
            areaDeliveries.add(deliveryTime);
          }
        }
      }

      if (areaDeliveries.isEmpty) {
        AppLogger.info('No matching area deliveries found, using default estimate');
        return _getDefaultDeliveryDays(deliveryArea);
      }

      // Calculate average delivery time
      final totalDays = areaDeliveries.fold<int>(0, (sum, duration) => sum + duration.inDays);
      final averageDays = (totalDays / areaDeliveries.length).round();

      // Add buffer for safety (10% more time)
      final estimatedDays = (averageDays * 1.1).round();

      AppLogger.info('Calculated delivery estimate for area: $estimatedDays days (from ${areaDeliveries.length} historical deliveries)');

      return estimatedDays.clamp(1, 15); // Minimum 1 day, maximum 15 days

    } catch (e) {
      AppLogger.error('Error calculating delivery estimate', error: e);
      return _getDefaultDeliveryDays(deliveryArea);
    }
  }

  /// Get delivery statistics for an area
  Future<Map<String, dynamic>> getAreaDeliveryStats(String deliveryArea) async {
    try {
      final areaKeywords = _extractAreaKeywords(deliveryArea);

      final response = await _supabase
          .from('sales')
          .select('sale_date, updated_at, recipient_address, customer_address, courier_status')
          .eq('courier_status', 'delivered')
          .gte('sale_date', DateTime.now().subtract(const Duration(days: 180)).toIso8601String())
          .order('sale_date', ascending: false);

      final deliveries = response as List<dynamic>;
      final areaDeliveries = <Duration>[];

      for (final delivery in deliveries) {
        final address = delivery['recipient_address'] ?? delivery['customer_address'] ?? '';

        if (_isAddressMatch(address, areaKeywords)) {
          final saleDate = DateTime.parse(delivery['sale_date']);
          final deliveryDate = DateTime.parse(delivery['updated_at']);
          final deliveryTime = deliveryDate.difference(saleDate);

          if (deliveryTime.inDays >= 1 && deliveryTime.inDays <= 30) {
            areaDeliveries.add(deliveryTime);
          }
        }
      }

      if (areaDeliveries.isEmpty) {
        return {
          'averageDays': _getDefaultDeliveryDays(deliveryArea),
          'minDays': _getDefaultDeliveryDays(deliveryArea),
          'maxDays': _getDefaultDeliveryDays(deliveryArea),
          'totalDeliveries': 0,
          'confidence': 'low',
        };
      }

      final days = areaDeliveries.map((d) => d.inDays).toList()..sort();

      return {
        'averageDays': (days.fold<int>(0, (a, b) => a + b) / days.length).round(),
        'minDays': days.first,
        'maxDays': days.last,
        'medianDays': days[days.length ~/ 2],
        'totalDeliveries': areaDeliveries.length,
        'confidence': areaDeliveries.length >= 10 ? 'high' : areaDeliveries.length >= 5 ? 'medium' : 'low',
      };

    } catch (e) {
      AppLogger.error('Error getting area delivery stats', error: e);
      return {
        'averageDays': _getDefaultDeliveryDays(deliveryArea),
        'minDays': _getDefaultDeliveryDays(deliveryArea),
        'maxDays': _getDefaultDeliveryDays(deliveryArea),
        'totalDeliveries': 0,
        'confidence': 'low',
      };
    }
  }

  /// Extract keywords from address for matching
  List<String> _extractAreaKeywords(String address) {
    if (address.isEmpty) return [];

    final normalized = address.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    final words = normalized.split(' ').where((word) => word.length >= 3).toList();

    // Common area identifiers in Bangladesh
    final areaKeywords = <String>[];
    for (final word in words) {
      // Skip common words that don't identify areas
      if (!_isCommonWord(word)) {
        areaKeywords.add(word);
      }
    }

    return areaKeywords;
  }

  /// Check if address matches area keywords
  bool _isAddressMatch(String address, List<String> keywords) {
    if (keywords.isEmpty || address.isEmpty) return false;

    final normalizedAddress = address.toLowerCase();

    // Count matching keywords
    int matches = 0;
    for (final keyword in keywords) {
      if (normalizedAddress.contains(keyword)) {
        matches++;
      }
    }

    // Require at least 1 keyword match for small keyword lists,
    // or 60% match for larger keyword lists
    final requiredMatches = keywords.length <= 2 ? 1 : (keywords.length * 0.6).ceil();

    return matches >= requiredMatches;
  }

  /// Check if word is a common word that shouldn't be used for area matching
  bool _isCommonWord(String word) {
    const commonWords = {
      'road', 'street', 'lane', 'avenue', 'house', 'building', 'apartment',
      'flat', 'floor', 'block', 'sector', 'area', 'para', 'goli', 'market',
      'bazar', 'bazaar', 'hospital', 'school', 'college', 'university',
      'mosque', 'masjid', 'temple', 'church', 'park', 'ground', 'field',
      'near', 'beside', 'opposite', 'behind', 'front', 'back', 'side',
      'dhaka', 'bangladesh', 'chittagong', 'sylhet', 'rajshahi', 'khulna',
      'baridhara', 'gulshan', 'dhanmondi', 'uttara', 'banani', 'mohammadpur'
    };

    return commonWords.contains(word);
  }

  /// Get default delivery days based on area type
  int _getDefaultDeliveryDays(String deliveryArea) {
    final area = deliveryArea.toLowerCase();

    // Dhaka city areas - faster delivery
    if (area.contains('dhaka') || area.contains('gulshan') || area.contains('dhanmondi') ||
        area.contains('uttara') || area.contains('banani') || area.contains('mohammadpur') ||
        area.contains('mirpur') || area.contains('pallabi') || area.contains('tejgaon')) {
      return 2; // 2 days for Dhaka city
    }

    // Major cities
    if (area.contains('chittagong') || area.contains('sylhet') || area.contains('rajshahi') ||
        area.contains('khulna') || area.contains('comilla') || area.contains('narayanganj')) {
      return 3; // 3 days for major cities
    }

    // District headquarters
    if (area.contains('sadar') || area.contains('pourashava') || area.contains('municipality')) {
      return 4; // 4 days for district headquarters
    }

    // Rural/remote areas
    return 5; // 5 days for rural areas
  }

  /// Get delivery reliability score for an area (0-100)
  Future<int> getAreaReliabilityScore(String deliveryArea) async {
    try {
      final stats = await getAreaDeliveryStats(deliveryArea);
      final totalDeliveries = stats['totalDeliveries'] as int;
      final confidence = stats['confidence'] as String;

      if (totalDeliveries == 0) return 50; // Medium confidence for new areas

      // Base score on historical data confidence
      int baseScore = 50;
      switch (confidence) {
        case 'high':
          baseScore = 85;
          break;
        case 'medium':
          baseScore = 70;
          break;
        case 'low':
          baseScore = 55;
          break;
      }

      // Adjust based on delivery consistency
      final minDays = stats['minDays'] as int;
      final maxDays = stats['maxDays'] as int;

      final variation = maxDays - minDays;
      if (variation <= 2) {
        baseScore += 10; // Very consistent delivery times
      } else if (variation <= 4) {
        baseScore += 5; // Moderately consistent
      } else if (variation >= 8) {
        baseScore -= 10; // Inconsistent delivery times
      }

      return baseScore.clamp(0, 100);

    } catch (e) {
      AppLogger.error('Error calculating reliability score', error: e);
      return 50; // Default medium reliability
    }
  }
}