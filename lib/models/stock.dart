class Stock {
  final String id;
  final String productId;
  final String locationId;
  final int quantity;
  final DateTime updatedAt;

  Stock({
    required this.id,
    required this.productId,
    required this.locationId,
    required this.quantity,
    required this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      locationId: json['location_id'] as String,
      quantity: json['quantity'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'location_id': locationId,
      'quantity': quantity,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StockLocation {
  final String id;
  final String locationName;
  final String locationType;
  final DateTime createdAt;

  StockLocation({
    required this.id,
    required this.locationName,
    required this.locationType,
    required this.createdAt,
  });

  factory StockLocation.fromJson(Map<String, dynamic> json) {
    return StockLocation(
      id: json['id'] as String,
      locationName: json['location_name'] as String,
      locationType: json['location_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': locationName,
      'location_type': locationType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StockMovement {
  final String id;
  final String productId;
  final String? fromLocationId;
  final String? toLocationId;
  final int quantity;
  final String movementType;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  StockMovement({
    required this.id,
    required this.productId,
    this.fromLocationId,
    this.toLocationId,
    required this.quantity,
    required this.movementType,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      fromLocationId: json['from_location_id'] as String?,
      toLocationId: json['to_location_id'] as String?,
      quantity: json['quantity'] as int,
      movementType: json['movement_type'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'quantity': quantity,
      'movement_type': movementType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

