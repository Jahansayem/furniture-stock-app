class Product {
  final String id;
  final String productName;
  final String productType;
  final double price;
  final String? imageUrl;
  final String? description;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  Product({
    required this.id,
    required this.productName,
    required this.productType,
    required this.price,
    this.imageUrl,
    this.description,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      productType: json['product_type'] as String,
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      lowStockThreshold: json['low_stock_threshold'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_type': productType,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Product copyWith({
    String? id,
    String? productName,
    String? productType,
    double? price,
    String? imageUrl,
    String? description,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
