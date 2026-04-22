import 'package:equatable/equatable.dart';
import 'product_variant.dart';

class Product extends Equatable {
  final String id;
  final List<String> images;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final double baseComparePrice;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.images,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.baseComparePrice,
    required this.variants,
  });

  String get priceRange {
    if (variants.isEmpty) return "$basePrice";
    final prices = variants.map((v) => v.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    return minPrice == maxPrice ? "$minPrice" : "$minPrice - $maxPrice";
  }

  @override
  List<Object?> get props => [
    id,
    images,
    name,
    description,
    category,
    basePrice,
    baseComparePrice,
    variants,
  ];
}
