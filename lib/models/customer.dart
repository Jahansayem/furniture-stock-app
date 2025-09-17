import 'package:flutter/material.dart';

/// Enhanced customer model for comprehensive customer management
class Customer {
  final String id;
  final String customerCode;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? area;
  final String? postalCode;
  final CustomerType customerType;
  
  // Financial Management
  final double creditLimit;
  final double currentBalance;
  final String paymentTerms;
  
  // Preferences
  final String? preferredDeliveryTime;
  final String? specialInstructions;
  final String? notes;
  final List<String> tags;
  
  // Relationship Management
  final String? source;
  final String? referredById;
  final String? assignedSalesRepId;
  
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.area,
    this.postalCode,
    this.customerType = CustomerType.individual,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.paymentTerms = 'cash_on_delivery',
    this.preferredDeliveryTime,
    this.specialInstructions,
    this.notes,
    this.tags = const [],
    this.source,
    this.referredById,
    this.assignedSalesRepId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display address for customer
  String get displayAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (area != null) parts.add(area!);
    if (city != null) parts.add(city!);
    return parts.join(', ');
  }

  /// Check if customer has outstanding balance
  bool get hasOutstandingBalance => currentBalance > 0;

  /// Check if customer is over credit limit
  bool get isOverCreditLimit => currentBalance > creditLimit;

  /// Get customer type display name
  String get customerTypeDisplayName {
    switch (customerType) {
      case CustomerType.individual:
        return 'Individual';
      case CustomerType.business:
        return 'Business';
      case CustomerType.wholesale:
        return 'Wholesale';
      case CustomerType.vip:
        return 'VIP';
    }
  }

  /// Get customer type color for UI
  Color get customerTypeColor {
    switch (customerType) {
      case CustomerType.individual:
        return const Color(0xFF2196F3); // Blue
      case CustomerType.business:
        return const Color(0xFF00A859); // Green
      case CustomerType.wholesale:
        return const Color(0xFF9C27B0); // Purple
      case CustomerType.vip:
        return const Color(0xFFFF8C00); // Orange
    }
  }

  /// Get initials for avatar
  String get initials {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      customerCode: json['customer_code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      latitude: json['location']?['coordinates']?[1]?.toDouble(),
      longitude: json['location']?['coordinates']?[0]?.toDouble(),
      city: json['city'] as String?,
      area: json['area'] as String?,
      postalCode: json['postal_code'] as String?,
      customerType: CustomerType.values.firstWhere(
        (type) => type.name == (json['customer_type'] as String? ?? 'individual'),
        orElse: () => CustomerType.individual,
      ),
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      paymentTerms: json['payment_terms'] as String? ?? 'cash_on_delivery',
      preferredDeliveryTime: json['preferred_delivery_time'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      notes: json['notes'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      source: json['source'] as String?,
      referredById: json['referred_by'] as String?,
      assignedSalesRepId: json['assigned_sales_rep'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_code': customerCode,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'location': (latitude != null && longitude != null) 
          ? 'POINT($longitude $latitude)'
          : null,
      'city': city,
      'area': area,
      'postal_code': postalCode,
      'customer_type': customerType.name,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'payment_terms': paymentTerms,
      'preferred_delivery_time': preferredDeliveryTime,
      'special_instructions': specialInstructions,
      'notes': notes,
      'tags': tags,
      'source': source,
      'referred_by': referredById,
      'assigned_sales_rep': assignedSalesRepId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? customerCode,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? area,
    String? postalCode,
    CustomerType? customerType,
    double? creditLimit,
    double? currentBalance,
    String? paymentTerms,
    String? preferredDeliveryTime,
    String? specialInstructions,
    String? notes,
    List<String>? tags,
    String? source,
    String? referredById,
    String? assignedSalesRepId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      area: area ?? this.area,
      postalCode: postalCode ?? this.postalCode,
      customerType: customerType ?? this.customerType,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      preferredDeliveryTime: preferredDeliveryTime ?? this.preferredDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      referredById: referredById ?? this.referredById,
      assignedSalesRepId: assignedSalesRepId ?? this.assignedSalesRepId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, type: ${customerType.name})';
  }
}

/// Customer types for different business segments
enum CustomerType {
  individual,
  business, 
  wholesale,
  vip,
}

/// Customer analytics data
class CustomerAnalytics {
  final String customerId;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastOrderDate;
  final DateTime? firstOrderDate;
  final List<String> favoriteCategories;
  final int loyaltyPoints;
  final LoyaltyTier loyaltyTier;
  final ChurnRisk churnRisk;
  final double lifetimeValue;
  final DateTime updatedAt;

  const CustomerAnalytics({
    required this.customerId,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.averageOrderValue = 0,
    this.lastOrderDate,
    this.firstOrderDate,
    this.favoriteCategories = const [],
    this.loyaltyPoints = 0,
    this.loyaltyTier = LoyaltyTier.bronze,
    this.churnRisk = ChurnRisk.low,
    this.lifetimeValue = 0,
    required this.updatedAt,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      customerId: json['customer_id'] as String,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0,
      lastOrderDate: json['last_order_date'] != null 
          ? DateTime.parse(json['last_order_date'] as String)
          : null,
      firstOrderDate: json['first_order_date'] != null
          ? DateTime.parse(json['first_order_date'] as String)
          : null,
      favoriteCategories: List<String>.from(json['favorite_categories'] ?? []),
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      loyaltyTier: LoyaltyTier.values.firstWhere(
        (tier) => tier.name == (json['loyalty_tier'] as String? ?? 'bronze'),
        orElse: () => LoyaltyTier.bronze,
      ),
      churnRisk: ChurnRisk.values.firstWhere(
        (risk) => risk.name == (json['churn_risk'] as String? ?? 'low'),
        orElse: () => ChurnRisk.low,
      ),
      lifetimeValue: (json['lifetime_value'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'average_order_value': averageOrderValue,
      'last_order_date': lastOrderDate?.toIso8601String(),
      'first_order_date': firstOrderDate?.toIso8601String(),
      'favorite_categories': favoriteCategories,
      'loyalty_points': loyaltyPoints,
      'loyalty_tier': loyaltyTier.name,
      'churn_risk': churnRisk.name,
      'lifetime_value': lifetimeValue,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum,
}

enum ChurnRisk {
  low,
  medium,
  high,
}