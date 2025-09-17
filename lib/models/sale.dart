class Sale {
  final String id;
  final String productId;
  final String productName;
  final String locationId;
  final String locationName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String saleType; // 'online_cod', 'offline'
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String soldBy; // user ID who made the sale
  final String soldByName; // user name for display
  final DateTime saleDate;
  final String status; // 'pending', 'completed', 'cancelled'
  final String? notes;
  final String? cancelReason; // Reason for cancellation if status is 'cancelled'
  
  // Courier-related fields for online COD orders
  final String? deliveryType; // 'point_delivery' or 'home_delivery'
  final String? recipientPhone; // 11-digit phone for courier
  final String? recipientName; // Recipient name for courier
  final String? recipientAddress; // Full delivery address
  final double? codAmount; // Cash on delivery amount
  final String? courierNotes; // Notes for courier
  final String? consignmentId; // Steadfast consignment ID
  final String? trackingCode; // Courier tracking code
  final String? parcelId; // Parcel ID for tracking
  final String? courierStatus; // Delivery status from courier
  final DateTime? courierCreatedAt; // When courier order was created
  final DateTime? deliveryDate; // Actual delivery date
  final double? saleLatitude; // GPS coordinates of sale
  final double? saleLongitude; // GPS coordinates of sale
  final String? saleAddress; // Address where sale was made
  final double? discount; // Discount amount applied
  final String? paymentStatus; // Payment status
  final DateTime? paymentDate; // When payment was made

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.locationId,
    required this.locationName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleType,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.soldBy,
    required this.soldByName,
    required this.saleDate,
    required this.status,
    this.notes,
    this.cancelReason,
    // Courier fields
    this.deliveryType,
    this.recipientPhone,
    this.recipientName,
    this.recipientAddress,
    this.codAmount,
    this.courierNotes,
    this.consignmentId,
    this.trackingCode,
    this.parcelId,
    this.courierStatus,
    this.courierCreatedAt,
    this.deliveryDate,
    this.saleLatitude,
    this.saleLongitude,
    this.saleAddress,
    this.discount,
    this.paymentStatus,
    this.paymentDate,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      locationId: json['location_id'] ?? '',
      locationName: json['location_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      saleType: json['sale_type'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'],
      customerAddress: json['customer_address'],
      soldBy: json['sold_by'] ?? '',
      soldByName: json['sold_by_name'] ?? '',
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      cancelReason: json['cancel_reason'],
      // Courier fields
      deliveryType: json['delivery_type'],
      recipientPhone: json['recipient_phone'],
      recipientName: json['recipient_name'],
      recipientAddress: json['recipient_address'],
      codAmount: json['cod_amount']?.toDouble(),
      courierNotes: json['courier_notes'],
      consignmentId: json['consignment_id'],
      trackingCode: json['tracking_code'],
      parcelId: json['parcel_id'],
      courierStatus: json['courier_status'],
      courierCreatedAt: json['courier_created_at'] != null
          ? DateTime.parse(json['courier_created_at'])
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      saleLatitude: json['sale_latitude']?.toDouble(),
      saleLongitude: json['sale_longitude']?.toDouble(),
      saleAddress: json['sale_address'],
      discount: json['discount']?.toDouble(),
      paymentStatus: json['payment_status'],
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'location_id': locationId,
      'location_name': locationName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'sale_type': saleType,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'sold_by': soldBy,
      'sold_by_name': soldByName,
      'sale_date': saleDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'cancel_reason': cancelReason,
      // Courier fields
      'delivery_type': deliveryType,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'recipient_address': recipientAddress,
      'cod_amount': codAmount,
      'courier_notes': courierNotes,
      'consignment_id': consignmentId,
      'tracking_code': trackingCode,
      'courier_status': courierStatus,
      'courier_created_at': courierCreatedAt?.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'sale_latitude': saleLatitude,
      'sale_longitude': saleLongitude,
      'sale_address': saleAddress,
      'discount': discount,
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }

  // Helper methods for courier functionality
  bool get hasCourierOrder => consignmentId != null && consignmentId!.isNotEmpty;
  
  bool get isOnlineCOD => saleType == 'online_cod';
  
  bool get isDelivered => courierStatus?.toLowerCase() == 'delivered';
  
  bool get isPendingDelivery => hasCourierOrder && !isDelivered;
  
  String get deliveryStatusDisplay {
    if (!isOnlineCOD) return 'N/A';
    if (consignmentId == null || consignmentId!.isEmpty) return 'Pending Courier';
    if (consignmentId == 'PENDING_OFFLINE') return 'Queued (Offline)';
    return courierStatus ?? 'In Transit';
  }
}
