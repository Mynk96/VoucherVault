class Category {
  int? id;
  String name;
  String color; // Stored as hex string
  int iconCodePoint;
  String iconFontFamily;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
  });

  // Convert Category to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
    };
  }

  // Create Category from Map (for database retrieve)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as String,
      iconCodePoint: map['icon_code_point'] as int,
      iconFontFamily: map['icon_font_family'] as String,
    );
  }

  // Clone with new properties
  Category copyWith({
    int? id,
    String? name,
    String? color,
    int? iconCodePoint,
    String? iconFontFamily,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
    );
  }
}

// Default categories for initial app setup
final List<Category> defaultCategories = [
  Category(
    name: 'Food & Drink',
    color: '#FF5722',
    iconCodePoint: 0xe25a, // restaurant icon
  ),
  Category(
    name: 'Shopping',
    color: '#4CAF50',
    iconCodePoint: 0xe59c, // shopping_bag icon
  ),
  Category(
    name: 'Travel',
    color: '#2196F3',
    iconCodePoint: 0xe570, // flight icon
  ),
  Category(
    name: 'Entertainment',
    color: '#9C27B0',
    iconCodePoint: 0xe40f, // movie icon
  ),
  Category(
    name: 'Other',
    color: '#607D8B',
    iconCodePoint: 0xe3e3, // more_horiz icon
  ),
];
