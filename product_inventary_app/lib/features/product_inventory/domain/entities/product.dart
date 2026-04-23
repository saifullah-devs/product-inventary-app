import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? comparePrice; // Nullable: Only exists if there's a discount/RRP
  final int stockQuantity;
  final String sku; // Stock Keeping Unit (e.g., "TSHIRT-BLK-M")
  final String category;
  final String imageUrl; // Single image representation
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.comparePrice,
    required this.stockQuantity,
    required this.sku,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    comparePrice,
    stockQuantity,
    sku,
    category,
    imageUrl,
    createdAt,
  ];
}
