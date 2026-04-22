part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class SourceSelectionRequired extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final DataSourceType activeSource;
  const ProductsLoaded(this.products, this.activeSource);
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}

class AuthRequiredState extends ProductState {
  final DataSourceType pendingSource;
  const AuthRequiredState(this.pendingSource);
}

class TransferInProgress extends ProductState {}

class TransferSuccess extends ProductState {}
