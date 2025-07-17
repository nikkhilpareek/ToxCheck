class Product {
  final String? productName;
  final String? ingredientsText;
  final List<String>? additivesTags;
  final List<String>? allergensTags;
  final List<String>? nutritionGradesTags;
  final int? novaGroup;
  final List<String>? categoriesTags;
  final String? imageUrl;
  final String? barcode;
  final String? brands;
  final String? quantity;

  Product({
    this.productName,
    this.ingredientsText,
    this.additivesTags,
    this.allergensTags,
    this.nutritionGradesTags,
    this.novaGroup,
    this.categoriesTags,
    this.imageUrl,
    this.barcode,
    this.brands,
    this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['product_name'],
      ingredientsText: json['ingredients_text'],
      additivesTags: _parseList(json['additives_tags']),
      allergensTags: _parseList(json['allergens_tags']),
      nutritionGradesTags: _parseList(json['nutrition_grades_tags']),
      novaGroup: json['nova_group'],
      categoriesTags: _parseList(json['categories_tags']),
      imageUrl: json['image_url'],
      barcode: json['code'],
      brands: json['brands'],
      quantity: json['quantity'],
    );
  }

  static List<String>? _parseList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'ingredients_text': ingredientsText,
      'additives_tags': additivesTags,
      'allergens_tags': allergensTags,
      'nutrition_grades_tags': nutritionGradesTags,
      'nova_group': novaGroup,
      'categories_tags': categoriesTags,
      'image_url': imageUrl,
      'code': barcode,
      'brands': brands,
      'quantity': quantity,
    };
  }

  // Helper methods
  String get displayName => productName ?? 'Unknown Product';
  
  bool get hasAdditives => additivesTags?.isNotEmpty ?? false;
  
  bool get hasAllergens => allergensTags?.isNotEmpty ?? false;
  
  String get nutritionGrade {
    if (nutritionGradesTags?.isNotEmpty ?? false) {
      final grade = nutritionGradesTags!.first;
      return grade.replaceAll('en:', '').toUpperCase();
    }
    return 'N/A';
  }
}
