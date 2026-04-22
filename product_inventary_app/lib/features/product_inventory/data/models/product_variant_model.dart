import '../../domain/entities/product_variant.dart';

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({
    required super.id,
    required super.sku,
    required super.attributes,
    required super.price,
    required super.comparePrice,
    required super.stockQuantity,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'],
      sku: json['sku'],
      attributes: Map<String, String>.from(json['attributes']),
      price: (json['price'] as num).toDouble(),
      comparePrice: (json['compare_price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'attributes': attributes,
    'price': price,
    'compare_price': comparePrice,
    'stock_quantity': stockQuantity,
  };
}
