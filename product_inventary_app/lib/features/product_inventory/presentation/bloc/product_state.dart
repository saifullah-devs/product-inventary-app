part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  final DataSourceType? activeSource;

  const ProductState({this.activeSource});

  @override
  List<Object?> get props => [activeSource];
}

class ProductInitial extends ProductState {}

class SourceSelectionRequired extends ProductState {}

class ProductLoading extends ProductState {
  const ProductLoading({super.activeSource});
}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;
  final bool isFetchingMore;

  const ProductsLoaded({
    required this.products,
    required this.hasReachedMax,
    required DataSourceType activeSource,
    this.isFetchingMore = false,
  }) : super(activeSource: activeSource);

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    DataSourceType? activeSource,
    bool? isFetchingMore,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      activeSource: activeSource ?? this.activeSource!,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [
    products,
    hasReachedMax,
    activeSource,
    isFetchingMore,
  ];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message, {super.activeSource});

  @override
  List<Object?> get props => [message, activeSource];
}

class ProductDetailLoaded extends ProductState {
  final Product product;
  const ProductDetailLoaded(this.product, {super.activeSource});

  @override
  List<Object?> get props => [product, activeSource];
}

class TransferInProgress extends ProductState {
  const TransferInProgress({super.activeSource});
}

class TransferSuccess extends ProductState {
  const TransferSuccess({super.activeSource});
}
