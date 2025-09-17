import 'package:flutter/material.dart';
import 'customer.dart';

/// Enhanced order model with comprehensive workflow management
class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final Customer? customer;
  final String? salesRepId;
  final String? assignedLocationId;
  
  // Order Details
  final List<OrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingCost;
  final double totalAmount;
  final String currency;
  
  // Status & Workflow
  final OrderStatus status;
  final OrderPriority priority;
  final PaymentStatus paymentStatus;
  final DeliveryStatus deliveryStatus;
  final List<OrderStatusHistory> statusHistory;
  
  // Dates & Timeline
  final DateTime orderDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final DateTime? dueDate;
  
  // Customer & Delivery Information
  final OrderAddress billingAddress;
  final OrderAddress deliveryAddress;
  final String? customerNotes;
  final String? internalNotes;
  
  // Payment Information
  final PaymentMethod paymentMethod;
  final List<OrderPayment> payments;
  final double paidAmount;
  final double remainingAmount;
  
  // Logistics & Fulfillment
  final String? courierService;
  final String? trackingNumber;
  final List<OrderFulfillment> fulfillments;
  
  // Production & Manufacturing
  final ProductionStatus productionStatus;
  final DateTime? productionStartDate;
  final DateTime? productionCompletionDate;
  final List<ProductionTask> productionTasks;
  
  // Tags & Categorization
  final List<String> tags;
  final OrderSource source;
  final String? referenceNumber;
  
  // System Fields
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customer,
    this.salesRepId,
    this.assignedLocationId,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.shippingCost,
    required this.totalAmount,
    this.currency = 'BDT',
    required this.status,
    this.priority = OrderPriority.normal,
    required this.paymentStatus,
    required this.deliveryStatus,
    this.statusHistory = const [],
    required this.orderDate,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.dueDate,
    required this.billingAddress,
    required this.deliveryAddress,
    this.customerNotes,
    this.internalNotes,
    required this.paymentMethod,
    this.payments = const [],
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.courierService,
    this.trackingNumber,
    this.fulfillments = const [],
    this.productionStatus = ProductionStatus.notStarted,
    this.productionStartDate,
    this.productionCompletionDate,
    this.productionTasks = const [],
    this.tags = const [],
    this.source = OrderSource.inStore,
    this.referenceNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  /// Get order status color for UI
  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case OrderStatus.confirmed:
        return const Color(0xFF42A5F5); // Blue
      case OrderStatus.processing:
        return const Color(0xFF26A69A); // Teal
      case OrderStatus.inProduction:
        return const Color(0xFF9C27B0); // Purple
      case OrderStatus.readyToShip:
        return const Color(0xFF66BB6A); // Green
      case OrderStatus.shipped:
        return const Color(0xFF29B6F6); // Light Blue
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50); // Success Green
      case OrderStatus.completed:
        return const Color(0xFF2E7D32); // Dark Green
      case OrderStatus.cancelled:
        return const Color(0xFFEF5350); // Red
      case OrderStatus.refunded:
        return const Color(0xFFFF7043); // Deep Orange
      case OrderStatus.onHold:
        return const Color(0xFF78909C); // Blue Grey
    }
  }

  /// Get order priority display name
  String get priorityDisplayName {
    switch (priority) {
      case OrderPriority.low:
        return 'Low';
      case OrderPriority.normal:
        return 'Normal';
      case OrderPriority.high:
        return 'High';
      case OrderPriority.urgent:
        return 'Urgent';
      case OrderPriority.critical:
        return 'Critical';
    }
  }

  /// Get payment status display name
  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.paid:
        return 'Fully Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  /// Check if order is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isCompleted;
  }

  /// Check if order is completed
  bool get isCompleted {
    return status == OrderStatus.completed || 
           status == OrderStatus.delivered ||
           status == OrderStatus.cancelled ||
           status == OrderStatus.refunded;
  }

  /// Check if order can be cancelled
  bool get canBeCancelled {
    return status != OrderStatus.cancelled &&
           status != OrderStatus.refunded &&
           status != OrderStatus.completed &&
           status != OrderStatus.delivered &&
           status != OrderStatus.shipped;
  }

  /// Check if order can be edited
  bool get canBeEdited {
    return status == OrderStatus.pending || 
           status == OrderStatus.confirmed;
  }

  /// Get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get order progress percentage
  double get progressPercentage {
    switch (status) {
      case OrderStatus.pending:
        return 0.1;
      case OrderStatus.confirmed:
        return 0.2;
      case OrderStatus.processing:
        return 0.4;
      case OrderStatus.inProduction:
        return 0.6;
      case OrderStatus.readyToShip:
        return 0.8;
      case OrderStatus.shipped:
        return 0.9;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Get next possible statuses for workflow
  List<OrderStatus> get nextPossibleStatuses {
    switch (status) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.processing, OrderStatus.onHold, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.inProduction, OrderStatus.readyToShip, OrderStatus.onHold];
      case OrderStatus.inProduction:
        return [OrderStatus.readyToShip, OrderStatus.processing];
      case OrderStatus.readyToShip:
        return [OrderStatus.shipped, OrderStatus.processing];
      case OrderStatus.shipped:
        return [OrderStatus.delivered, OrderStatus.readyToShip];
      case OrderStatus.delivered:
        return [OrderStatus.completed, OrderStatus.refunded];
      case OrderStatus.onHold:
        return [OrderStatus.processing, OrderStatus.cancelled];
      default:
        return [];
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      salesRepId: json['sales_rep_id'] as String?,
      assignedLocationId: json['assigned_location_id'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'BDT',
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => OrderStatus.pending,
      ),
      priority: OrderPriority.values.firstWhere(
        (p) => p.name == (json['priority'] as String? ?? 'normal'),
        orElse: () => OrderPriority.normal,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == (json['payment_status'] as String),
        orElse: () => PaymentStatus.pending,
      ),
      deliveryStatus: DeliveryStatus.values.firstWhere(
        (d) => d.name == (json['delivery_status'] as String),
        orElse: () => DeliveryStatus.pending,
      ),
      statusHistory: (json['status_history'] as List<dynamic>?)
          ?.map((item) => OrderStatusHistory.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      orderDate: DateTime.parse(json['order_date'] as String),
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.parse(json['estimated_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      billingAddress: OrderAddress.fromJson(json['billing_address'] as Map<String, dynamic>),
      deliveryAddress: OrderAddress.fromJson(json['delivery_address'] as Map<String, dynamic>),
      customerNotes: json['customer_notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == (json['payment_method'] as String),
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((item) => OrderPayment.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      courierService: json['courier_service'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      fulfillments: (json['fulfillments'] as List<dynamic>?)
          ?.map((item) => OrderFulfillment.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      productionStatus: ProductionStatus.values.firstWhere(
        (p) => p.name == (json['production_status'] as String? ?? 'not_started'),
        orElse: () => ProductionStatus.notStarted,
      ),
      productionStartDate: json['production_start_date'] != null
          ? DateTime.parse(json['production_start_date'] as String)
          : null,
      productionCompletionDate: json['production_completion_date'] != null
          ? DateTime.parse(json['production_completion_date'] as String)
          : null,
      productionTasks: (json['production_tasks'] as List<dynamic>?)
          ?.map((item) => ProductionTask.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      tags: List<String>.from(json['tags'] ?? []),
      source: OrderSource.values.firstWhere(
        (s) => s.name == (json['source'] as String? ?? 'in_store'),
        orElse: () => OrderSource.inStore,
      ),
      referenceNumber: json['reference_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'sales_rep_id': salesRepId,
      'assigned_location_id': assignedLocationId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'shipping_cost': shippingCost,
      'total_amount': totalAmount,
      'currency': currency,
      'status': status.name,
      'priority': priority.name,
      'payment_status': paymentStatus.name,
      'delivery_status': deliveryStatus.name,
      'status_history': statusHistory.map((item) => item.toJson()).toList(),
      'order_date': orderDate.toIso8601String(),
      'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String(),
      'actual_delivery_date': actualDeliveryDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'billing_address': billingAddress.toJson(),
      'delivery_address': deliveryAddress.toJson(),
      'customer_notes': customerNotes,
      'internal_notes': internalNotes,
      'payment_method': paymentMethod.name,
      'payments': payments.map((item) => item.toJson()).toList(),
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'courier_service': courierService,
      'tracking_number': trackingNumber,
      'fulfillments': fulfillments.map((item) => item.toJson()).toList(),
      'production_status': productionStatus.name,
      'production_start_date': productionStartDate?.toIso8601String(),
      'production_completion_date': productionCompletionDate?.toIso8601String(),
      'production_tasks': productionTasks.map((item) => item.toJson()).toList(),
      'tags': tags,
      'source': source.name,
      'reference_number': referenceNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    Customer? customer,
    String? salesRepId,
    String? assignedLocationId,
    List<OrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? shippingCost,
    double? totalAmount,
    String? currency,
    OrderStatus? status,
    OrderPriority? priority,
    PaymentStatus? paymentStatus,
    DeliveryStatus? deliveryStatus,
    List<OrderStatusHistory>? statusHistory,
    DateTime? orderDate,
    DateTime? estimatedDeliveryDate,
    DateTime? actualDeliveryDate,
    DateTime? dueDate,
    OrderAddress? billingAddress,
    OrderAddress? deliveryAddress,
    String? customerNotes,
    String? internalNotes,
    PaymentMethod? paymentMethod,
    List<OrderPayment>? payments,
    double? paidAmount,
    double? remainingAmount,
    String? courierService,
    String? trackingNumber,
    List<OrderFulfillment>? fulfillments,
    ProductionStatus? productionStatus,
    DateTime? productionStartDate,
    DateTime? productionCompletionDate,
    List<ProductionTask>? productionTasks,
    List<String>? tags,
    OrderSource? source,
    String? referenceNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      salesRepId: salesRepId ?? this.salesRepId,
      assignedLocationId: assignedLocationId ?? this.assignedLocationId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      orderDate: orderDate ?? this.orderDate,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      dueDate: dueDate ?? this.dueDate,
      billingAddress: billingAddress ?? this.billingAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerNotes: customerNotes ?? this.customerNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payments: payments ?? this.payments,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      courierService: courierService ?? this.courierService,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      fulfillments: fulfillments ?? this.fulfillments,
      productionStatus: productionStatus ?? this.productionStatus,
      productionStartDate: productionStartDate ?? this.productionStartDate,
      productionCompletionDate: productionCompletionDate ?? this.productionCompletionDate,
      productionTasks: productionTasks ?? this.productionTasks,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: ${status.name}, total: $totalAmount $currency)';
  }
}

/// Order item representing individual products within an order
class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? customizations;
  final String? notes;
  final Map<String, dynamic>? productMetadata;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.customizations,
    this.notes,
    this.productMetadata,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      customizations: json['customizations'] as String?,
      notes: json['notes'] as String?,
      productMetadata: json['product_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'customizations': customizations,
      'notes': notes,
      'product_metadata': productMetadata,
    };
  }
}

/// Order address for billing and delivery
class OrderAddress {
  final String fullName;
  final String phone;
  final String email;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final double? latitude;
  final double? longitude;

  const OrderAddress({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    this.country = 'Bangladesh',
    this.latitude,
    this.longitude,
  });

  String get displayAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, if (state != null) state!]);
    return parts.join(', ');
  }

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'Bangladesh',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Order status history for tracking changes
class OrderStatusHistory {
  final String id;
  final OrderStatus fromStatus;
  final OrderStatus toStatus;
  final String? reason;
  final String? notes;
  final DateTime timestamp;
  final String changedBy;

  const OrderStatusHistory({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    this.reason,
    this.notes,
    required this.timestamp,
    required this.changedBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as String,
      fromStatus: OrderStatus.values.firstWhere(
        (s) => s.name == (json['from_status'] as String),
      ),
      toStatus: OrderStatus.values.firstWhere(
        (s) => s.name == (json['to_status'] as String),
      ),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      changedBy: json['changed_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_status': fromStatus.name,
      'to_status': toStatus.name,
      'reason': reason,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'changed_by': changedBy,
    };
  }
}

/// Order payment record
class OrderPayment {
  final String id;
  final double amount;
  final PaymentMethod method;
  final String? transactionId;
  final String? reference;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? notes;

  const OrderPayment({
    required this.id,
    required this.amount,
    required this.method,
    this.transactionId,
    this.reference,
    required this.status,
    required this.paymentDate,
    this.notes,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == (json['method'] as String),
      ),
      transactionId: json['transaction_id'] as String?,
      reference: json['reference'] as String?,
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
      ),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'method': method.name,
      'transaction_id': transactionId,
      'reference': reference,
      'status': status.name,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }
}

/// Order fulfillment tracking
class OrderFulfillment {
  final String id;
  final List<String> itemIds;
  final String? warehouseId;
  final FulfillmentStatus status;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final String? trackingNumber;
  final String? courierService;

  const OrderFulfillment({
    required this.id,
    required this.itemIds,
    this.warehouseId,
    required this.status,
    this.shippedDate,
    this.deliveredDate,
    this.trackingNumber,
    this.courierService,
  });

  factory OrderFulfillment.fromJson(Map<String, dynamic> json) {
    return OrderFulfillment(
      id: json['id'] as String,
      itemIds: List<String>.from(json['item_ids'] ?? []),
      warehouseId: json['warehouse_id'] as String?,
      status: FulfillmentStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
      ),
      shippedDate: json['shipped_date'] != null
          ? DateTime.parse(json['shipped_date'] as String)
          : null,
      deliveredDate: json['delivered_date'] != null
          ? DateTime.parse(json['delivered_date'] as String)
          : null,
      trackingNumber: json['tracking_number'] as String?,
      courierService: json['courier_service'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_ids': itemIds,
      'warehouse_id': warehouseId,
      'status': status.name,
      'shipped_date': shippedDate?.toIso8601String(),
      'delivered_date': deliveredDate?.toIso8601String(),
      'tracking_number': trackingNumber,
      'courier_service': courierService,
    };
  }
}

/// Production task for manufacturing tracking
class ProductionTask {
  final String id;
  final String name;
  final String? description;
  final ProductionTaskStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedTo;
  final List<String> materials;

  const ProductionTask({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.materials = const [],
  });

  factory ProductionTask.fromJson(Map<String, dynamic> json) {
    return ProductionTask(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProductionTaskStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
      ),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      assignedTo: json['assigned_to'] as String?,
      materials: List<String>.from(json['materials'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'materials': materials,
    };
  }
}

/// Order status enumeration
enum OrderStatus {
  pending,
  confirmed,
  processing,
  inProduction,
  readyToShip,
  shipped,
  delivered,
  completed,
  cancelled,
  refunded,
  onHold,
}

/// Order priority levels
enum OrderPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

/// Payment status enumeration
enum PaymentStatus {
  pending,
  partial,
  paid,
  overdue,
  refunded,
}

/// Payment method enumeration
enum PaymentMethod {
  cashOnDelivery,
  bankTransfer,
  creditCard,
  debitCard,
  mobileBanking,
  digitalWallet,
  cash,
  check,
}

/// Delivery status enumeration
enum DeliveryStatus {
  pending,
  processing,
  shipped,
  outForDelivery,
  delivered,
  failed,
  returned,
}

/// Production status enumeration
enum ProductionStatus {
  notStarted,
  inProgress,
  completed,
  onHold,
  cancelled,
}

/// Fulfillment status enumeration
enum FulfillmentStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// Production task status enumeration
enum ProductionTaskStatus {
  pending,
  inProgress,
  completed,
  onHold,
  cancelled,
}

/// Order source enumeration
enum OrderSource {
  inStore,
  online,
  phone,
  email,
  whatsapp,
  facebook,
  salesRep,
}