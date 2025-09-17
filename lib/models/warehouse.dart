import 'package:hive/hive.dart';

part 'warehouse.g.dart';

@HiveType(typeId: 10)
class Warehouse {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String code;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final double? latitude;

  @HiveField(5)
  final double? longitude;

  @HiveField(6)
  final WarehouseType type;

  @HiveField(7)
  final String managerId;

  @HiveField(8)
  final String? managerName;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final String? description;

  @HiveField(13)
  final double? capacity; // in square meters

  @HiveField(14)
  final String? contactPhone;

  @HiveField(15)
  final String? contactEmail;

  Warehouse({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    this.latitude,
    this.longitude,
    required this.type,
    required this.managerId,
    this.managerName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.capacity,
    this.contactPhone,
    this.contactEmail,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      type: WarehouseType.fromString(json['type'] as String),
      managerId: json['manager_id'] as String,
      managerName: json['manager_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      capacity: json['capacity'] as double?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.value,
      'manager_id': managerId,
      'manager_name': managerName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
      'capacity': capacity,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
    };
  }

  Warehouse copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
    WarehouseType? type,
    String? managerId,
    String? managerName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    double? capacity,
    String? contactPhone,
    String? contactEmail,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
    );
  }

  String get displayName => '$name ($code)';

  bool get hasLocation => latitude != null && longitude != null;

  String get typeDisplayName => type.displayName;
}

@HiveType(typeId: 11)
enum WarehouseType {
  @HiveField(0)
  factory('factory', 'Factory', 'Manufacturing facility'),

  @HiveField(1)
  showroom('showroom', 'Showroom', 'Customer display area'),

  @HiveField(2)
  storage('storage', 'Storage', 'General storage facility'),

  @HiveField(3)
  distribution('distribution', 'Distribution', 'Distribution center'),

  @HiveField(4)
  retail('retail', 'Retail', 'Retail store');

  const WarehouseType(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static WarehouseType fromString(String value) {
    return WarehouseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WarehouseType.storage,
    );
  }
}

@HiveType(typeId: 12)
class StockTransfer {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String fromWarehouseId;

  @HiveField(4)
  final String fromWarehouseName;

  @HiveField(5)
  final String toWarehouseId;

  @HiveField(6)
  final String toWarehouseName;

  @HiveField(7)
  final int quantity;

  @HiveField(8)
  final TransferStatus status;

  @HiveField(9)
  final String initiatedBy;

  @HiveField(10)
  final String? approvedBy;

  @HiveField(11)
  final String? completedBy;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime? approvedAt;

  @HiveField(14)
  final DateTime? completedAt;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final String? rejectionReason;

  StockTransfer({
    required this.id,
    required this.productId,
    required this.productName,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.quantity,
    this.status = TransferStatus.pending,
    required this.initiatedBy,
    this.approvedBy,
    this.completedBy,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    this.notes,
    this.rejectionReason,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      fromWarehouseId: json['from_warehouse_id'] as String,
      fromWarehouseName: json['from_warehouse_name'] as String,
      toWarehouseId: json['to_warehouse_id'] as String,
      toWarehouseName: json['to_warehouse_name'] as String,
      quantity: json['quantity'] as int,
      status: TransferStatus.fromString(json['status'] as String),
      initiatedBy: json['initiated_by'] as String,
      approvedBy: json['approved_by'] as String?,
      completedBy: json['completed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null 
        ? DateTime.parse(json['approved_at'] as String) 
        : null,
      completedAt: json['completed_at'] != null 
        ? DateTime.parse(json['completed_at'] as String) 
        : null,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'from_warehouse_id': fromWarehouseId,
      'from_warehouse_name': fromWarehouseName,
      'to_warehouse_id': toWarehouseId,
      'to_warehouse_name': toWarehouseName,
      'quantity': quantity,
      'status': status.value,
      'initiated_by': initiatedBy,
      'approved_by': approvedBy,
      'completed_by': completedBy,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'rejection_reason': rejectionReason,
    };
  }

  String get statusDisplayName => status.displayName;
  
  bool get canBeApproved => status == TransferStatus.pending;
  bool get canBeCompleted => status == TransferStatus.approved;
  bool get canBeCancelled => status == TransferStatus.pending || status == TransferStatus.approved;
}

@HiveType(typeId: 13)
enum TransferStatus {
  @HiveField(0)
  pending('pending', 'Pending Approval'),

  @HiveField(1)
  approved('approved', 'Approved'),

  @HiveField(2)
  inProgress('in_progress', 'In Progress'),

  @HiveField(3)
  completed('completed', 'Completed'),

  @HiveField(4)
  cancelled('cancelled', 'Cancelled'),

  @HiveField(5)
  rejected('rejected', 'Rejected');

  const TransferStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static TransferStatus fromString(String value) {
    return TransferStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransferStatus.pending,
    );
  }
}