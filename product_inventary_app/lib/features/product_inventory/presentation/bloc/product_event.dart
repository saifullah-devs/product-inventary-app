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
}

// CRUD Events
class LoadAllProductsEvent extends ProductEvent {}

class AddProductEvent extends ProductEvent {
  final Product product;
  const AddProductEvent(this.product);
}

class UpdateProductEvent extends ProductEvent {
  final Product product;
  const UpdateProductEvent(this.product);
}

class DeleteProductEvent extends ProductEvent {
  final String id;
  const DeleteProductEvent(this.id);
}

// Migration Event
class TransferDataEvent extends ProductEvent {
  final DataSourceType from;
  final DataSourceType to;
  const TransferDataEvent({required this.from, required this.to});
}
