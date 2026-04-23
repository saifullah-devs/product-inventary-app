part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

// Initialization & Source Management
class CheckInitialSourceEvent extends ProductEvent {}

class SelectSourceEvent extends ProductEvent {
  final DataSourceType type;
  const SelectSourceEvent(this.type);

  @override
  List<Object?> get props => [type];
}

// CRUD Events
class LoadAllProductsEvent extends ProductEvent {
  final bool isRefresh; // Tells the BLoC to reset the offset to 0
  const LoadAllProductsEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class GetProductDetailEvent extends ProductEvent {
  final String id;
  const GetProductDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class AddProductEvent extends ProductEvent {
  final Product product;
  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductEvent extends ProductEvent {
  final Product product;
  const UpdateProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductEvent {
  final String id;
  const DeleteProductEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteProductsByIdEvent extends ProductEvent {
  final List<String> ids;
  const DeleteProductsByIdEvent(this.ids);

  @override
  List<Object?> get props => [ids];
}

// Migration Event
class TransferDataEvent extends ProductEvent {
  final List<String> productIds; // Added missing field
  final DataSourceType from;
  final DataSourceType to;

  const TransferDataEvent({
    required this.productIds,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [productIds, from, to];
}
