import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String id;
  final String sku;
  final Map<String, String> attributes;
  final double price;
  final double comparePrice;
  final int stockQuantity;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.attributes,
    required this.price,
    required this.comparePrice,
    required this.stockQuantity,
  });

  @override
  List<Object?> get props => [
    id,
    sku,
    attributes,
    price,
    comparePrice,
    stockQuantity,
  ];
}
