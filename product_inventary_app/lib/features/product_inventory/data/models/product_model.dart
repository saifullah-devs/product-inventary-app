import '../../domain/entities/product.dart';
import 'product_variant_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.images,
    required super.name,
    required super.description,
    required super.category,
    required super.basePrice,
    required super.baseComparePrice,
    required super.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      images: List<String>.from(json['images']),
      name: json['name'],
      description: json['description'],
      category: json['category'],
      basePrice: (json['base_price'] as num).toDouble(),
      baseComparePrice: (json['base_compare_price'] as num).toDouble(),
      variants: (json['variants'] as List)
          .map((v) => ProductVariantModel.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'images': images,
    'name': name,
    'description': description,
    'category': category,
    'base_price': basePrice,
    'base_compare_price': baseComparePrice,
    'variants': variants
        .map((v) => (v as ProductVariantModel).toJson())
        .toList(),
  };

  // Helper to convert Entity back to Model for Data Layer operations
  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      images: entity.images,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      basePrice: entity.basePrice,
      baseComparePrice: entity.baseComparePrice,
      variants: entity.variants
          .map(
            (v) => ProductVariantModel(
              id: v.id,
              sku: v.sku,
              attributes: v.attributes,
              price: v.price,
              comparePrice: v.comparePrice,
              stockQuantity: v.stockQuantity,
            ),
          )
          .toList(),
    );
  }
}
