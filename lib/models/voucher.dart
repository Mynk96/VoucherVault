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
  List<String> tags; // New field for tags (comma-separated in DB)
  bool isFavorite; // New field for favorites
  DateTime? lastUsedDate; // New field for last used date

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
    this.tags = const [],
    this.isFavorite = false,
    this.lastUsedDate,
  }) : createdDate = createdDate ?? DateTime.now();

  // Convert Voucher to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
      'tags': tags.isNotEmpty ? tags.join(',') : null,
      'is_favorite': isFavorite ? 1 : 0,
      'last_used_date': lastUsedDate != null 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(lastUsedDate!) 
          : null,
    };
  }

  // Create Voucher from Map (for database retrieve)
  factory Voucher.fromMap(Map<String, dynamic> map) {
    // Parse tags from comma-separated string
    List<String> parseTags(String? tagsString) {
      if (tagsString == null || tagsString.isEmpty) return [];
      return tagsString.split(',').map((tag) => tag.trim()).toList();
    }
    
    // Parse dates with null-safety
    DateTime? parseDate(String? dateString, {required DateFormat format}) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return format.parse(dateString);
      } catch (e) {
        print('Error parsing date: $dateString - $e');
        return null;
      }
    }
    
    return Voucher(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      store: map['store'] as String? ?? '',
      discountAmount: map['discount_amount'] is double 
          ? map['discount_amount'] 
          : (map['discount_amount'] is int 
              ? (map['discount_amount'] as int).toDouble() 
              : 0.0),
      discountType: map['discount_type'] as String? ?? 'percentage',
      createdDate: parseDate(
        map['created_date'] as String?, 
        format: DateFormat('yyyy-MM-dd HH:mm:ss')
      ) ?? DateTime.now(),
      expiryDate: parseDate(
        map['expiry_date'] as String?, 
        format: DateFormat('yyyy-MM-dd')
      ) ?? DateTime.now().add(const Duration(days: 30)),
      categoryId: map['category_id'] as int?,
      imageUrl: map['image_url'] as String? ?? '',
      isUsed: map['is_used'] == null ? false : (map['is_used'] as int) == 1,
      tags: parseTags(map['tags'] as String?),
      isFavorite: map['is_favorite'] == null ? false : (map['is_favorite'] as int) == 1,
      lastUsedDate: parseDate(
        map['last_used_date'] as String?, 
        format: DateFormat('yyyy-MM-dd HH:mm:ss')
      ),
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
    List<String>? tags,
    bool? isFavorite,
    DateTime? lastUsedDate,
    bool clearLastUsedDate = false,
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
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedDate: clearLastUsedDate ? null : (lastUsedDate ?? this.lastUsedDate),
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
  
  String? get formattedLastUsedDate => 
      lastUsedDate != null ? DateFormat('MMM dd, yyyy').format(lastUsedDate!) : null;
  
  String get formattedDiscount {
    if (discountType == 'percentage') {
      return '${discountAmount.toStringAsFixed(0)}%';
    } else {
      return '\$${discountAmount.toStringAsFixed(2)}';
    }
  }
  
  // Helper methods for tags
  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags = [...tags, tag];
    }
  }
  
  void removeTag(String tag) {
    tags = tags.where((t) => t != tag).toList();
  }
  
  bool hasTag(String tag) {
    return tags.contains(tag);
  }
  
  // Mark voucher as used
  Voucher markAsUsed() {
    return copyWith(
      isUsed: true, 
      lastUsedDate: DateTime.now(),
    );
  }
  
  // Toggle favorite status
  Voucher toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }
  
  // Time-based status getters
  bool get isAboutToExpire => !isExpired && daysUntilExpiry <= 7;
  
  String get statusDescription {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    if (isAboutToExpire) return 'Expiring Soon';
    return 'Active';
  }
  
  // For debug purposes
  @override
  String toString() {
    return 'Voucher{id: $id, code: $code, store: $store, expires: $formattedExpiryDate, '
        'used: $isUsed, favorite: $isFavorite}';
  }
}
