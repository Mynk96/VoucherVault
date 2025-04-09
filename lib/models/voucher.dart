import 'package:intl/intl.dart';

class Voucher {
  int? id;
  String code;
  String description;
  String store;
  double discountAmount;
  String discountType; // percentage, fixed, etc.
  DateTime createdDate;
  DateTime expiryDate;
  int? categoryId;
  String imageUrl; // For screenshot or image of the voucher
  bool isUsed;

  Voucher({
    this.id,
    required this.code,
    required this.description,
    required this.store,
    this.discountAmount = 0.0,
    this.discountType = 'percentage',
    DateTime? createdDate,
    required this.expiryDate,
    this.categoryId,
    this.imageUrl = '',
    this.isUsed = false,
  }) : createdDate = createdDate ?? DateTime.now();

  // Convert Voucher to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'store': store,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'created_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdDate),
      'expiry_date': DateFormat('yyyy-MM-dd').format(expiryDate),
      'category_id': categoryId,
      'image_url': imageUrl,
      'is_used': isUsed ? 1 : 0,
    };
  }

  // Create Voucher from Map (for database retrieve)
  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] as int,
      code: map['code'] as String,
      description: map['description'] as String,
      store: map['store'] as String,
      discountAmount: map['discount_amount'] as double,
      discountType: map['discount_type'] as String,
      createdDate: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['created_date'] as String),
      expiryDate: DateFormat('yyyy-MM-dd').parse(map['expiry_date'] as String),
      categoryId: map['category_id'] as int?,
      imageUrl: map['image_url'] as String,
      isUsed: (map['is_used'] as int) == 1,
    );
  }

  // Clone with new properties
  Voucher copyWith({
    int? id,
    String? code,
    String? description,
    String? store,
    double? discountAmount,
    String? discountType,
    DateTime? createdDate,
    DateTime? expiryDate,
    int? categoryId,
    String? imageUrl,
    bool? isUsed,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      store: store ?? this.store,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      createdDate: createdDate ?? this.createdDate,
      expiryDate: expiryDate ?? this.expiryDate,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  // Check if voucher is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  // Calculate days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  // Format for display
  String get formattedExpiryDate => DateFormat('MMM dd, yyyy').format(expiryDate);
  
  String get formattedCreatedDate => DateFormat('MMM dd, yyyy').format(createdDate);
  
  String get formattedDiscount {
    if (discountType == 'percentage') {
      return '${discountAmount.toStringAsFixed(0)}%';
    } else {
      return '\$${discountAmount.toStringAsFixed(2)}';
    }
  }
}
