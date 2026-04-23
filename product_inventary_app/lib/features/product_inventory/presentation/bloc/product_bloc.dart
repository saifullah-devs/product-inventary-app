import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/usecases/usecase.dart';
import '../../domain/entities/product.dart';

import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/get_active_source_usecase.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/set_active_source_usecase.dart';
import '../../domain/usecases/transfer_product_data_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/delete_products_by_id.dart';
import '../../domain/usecases/update_product_usecase.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProductsUseCase getAllProducts;
  final GetProductUseCase getProduct;
  final CreateProductUseCase createProduct;
  final UpdateProductUseCase updateProduct;
  final DeleteProductUseCase deleteProduct;
  final DeleteProductsByIdUseCase deleteProductsById;
  final SetActiveDataSourceUseCase setActiveSource;
  final GetActiveDataSourceUseCase getActiveSource;
  final TransferDataUseCase transferProductData;

  static const int _limit = 15;

  ProductBloc({
    required this.getAllProducts,
    required this.getProduct,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.deleteProductsById,
    required this.setActiveSource,
    required this.getActiveSource,
    required this.transferProductData,
  }) : super(ProductInitial()) {
    // HELPER: Grabs the active source from the current state or fetches it
    Future<DataSourceType?> _getCurrentSource() async {
      if (state.activeSource != null) return state.activeSource;
      final result = await getActiveSource(NoParams());
      return result.fold((l) => null, (r) => r);
    }

    on<CheckInitialSourceEvent>((event, emit) async {
      final result = await getActiveSource(NoParams());
      result.fold((failure) => emit(SourceSelectionRequired()), (source) {
        if (source == null) {
          emit(SourceSelectionRequired());
        } else {
          add(const LoadAllProductsEvent());
        }
      });
    });

    on<SelectSourceEvent>((event, emit) async {
      await setActiveSource(event.type);
      add(const LoadAllProductsEvent(isRefresh: true));
    });

    on<LoadAllProductsEvent>((event, emit) async {
      final currentState = state;
      int currentOffset = 0;
      List<Product> oldProducts = [];

      final currentSource = await _getCurrentSource();
      if (currentSource == null) {
        emit(const ProductError("No data source selected"));
        return;
      }

      if (currentState is ProductsLoaded && !event.isRefresh) {
        if (currentState.hasReachedMax || currentState.isFetchingMore) return;
        oldProducts = currentState.products;
        currentOffset = oldProducts.length;
        emit(currentState.copyWith(isFetchingMore: true));
      } else {
        emit(ProductLoading(activeSource: currentSource));
      }

      final productsResult = await getAllProducts(
        PaginationParams(limit: _limit, offset: currentOffset),
      );

      productsResult.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (newProducts) {
          emit(
            ProductsLoaded(
              products: event.isRefresh
                  ? newProducts
                  : oldProducts + newProducts,
              activeSource: currentSource,
              hasReachedMax: newProducts.length < _limit,
              isFetchingMore: false,
            ),
          );
        },
      );
    });

    on<GetProductDetailEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      emit(ProductLoading(activeSource: currentSource));

      final result = await getProduct(event.id);
      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (product) =>
            emit(ProductDetailLoaded(product, activeSource: currentSource)),
      );
    });

    on<AddProductEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      final result = await createProduct(event.product);
      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (_) => add(const LoadAllProductsEvent(isRefresh: true)),
      );
    });

    on<UpdateProductEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      final result = await updateProduct(event.product);
      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (_) => add(const LoadAllProductsEvent(isRefresh: true)),
      );
    });

    on<DeleteProductEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      final result = await deleteProduct(event.id);
      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (_) => add(const LoadAllProductsEvent(isRefresh: true)),
      );
    });

    on<DeleteProductsByIdEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      final result = await deleteProductsById(event.ids);
      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (_) => add(const LoadAllProductsEvent(isRefresh: true)),
      );
    });

    on<TransferDataEvent>((event, emit) async {
      final currentSource = await _getCurrentSource();
      emit(TransferInProgress(activeSource: currentSource));

      final result = await transferProductData(
        TransferDataParams(
          from: event.from,
          to: event.to,
          productIds: event.productIds,
        ),
      );

      result.fold(
        (f) => emit(ProductError(f.message, activeSource: currentSource)),
        (_) {
          emit(TransferSuccess(activeSource: currentSource));
          add(const LoadAllProductsEvent(isRefresh: true));
        },
      );
    });
  }
}
