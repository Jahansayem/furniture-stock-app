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
    };
  }
}
