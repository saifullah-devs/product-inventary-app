import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.comparePrice,
    required super.stockQuantity,
    required super.sku,
    required super.category,
    required super.imageUrl,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      comparePrice: json['compare_price'] != null
          ? (json['compare_price'] as num).toDouble()
          : null,
      stockQuantity: json['stock_quantity'] as int,
      sku: json['sku'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'compare_price': comparePrice,
      'stock_quantity': stockQuantity,
      'sku': sku,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      comparePrice: entity.comparePrice,
      stockQuantity: entity.stockQuantity,
      sku: entity.sku,
      category: entity.category,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
    );
  }
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? comparePrice,
    int? stockQuantity,
    String? sku,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      comparePrice: comparePrice ?? this.comparePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
