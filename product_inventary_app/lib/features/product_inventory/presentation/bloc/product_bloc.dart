import 'package:equatable/equatable.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/usecase/usecase.dart';
import '../../domain/entities/product.dart';

import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_active_source_usecase.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/set_active_source_usecase.dart';
import '../../domain/usecases/transfer_product_data_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProductsUseCase getAllProducts;
  final GetProductUseCase getProduct;
  final CreateProductUseCase createProduct;
  final UpdateProductUseCase updateProduct;
  final DeleteProductUseCase deleteProduct;
  final SetActiveSourceUseCase setActiveSource;
  final GetActiveSourceUseCase getActiveSource;
  final TransferProductDataUseCase transferProductData;

  ProductBloc({
    required this.getAllProducts,
    required this.getProduct,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.setActiveSource,
    required this.getActiveSource,
    required this.transferProductData,
  }) : super(ProductInitial()) {
    on<CheckInitialSourceEvent>((event, emit) async {
      final result = await getActiveSource(NoParams());
      result.fold((failure) => emit(SourceSelectionRequired()), (source) {
        if (source == null) {
          emit(SourceSelectionRequired());
        } else {
          add(LoadAllProductsEvent());
        }
      });
    });

    on<SelectSourceEvent>((event, emit) async {
      // Conditional Authentication Rule
      if (event.type == DataSourceType.rest) {
        // Logic: Check if token exists in AppPreferences/AuthService
        // If not, emit(AuthRequiredState(event.type)); return;
      }

      await setActiveSource(event.type);
      add(LoadAllProductsEvent());
    });

    on<LoadAllProductsEvent>((event, emit) async {
      emit(ProductLoading());
      final sourceResult = await getActiveSource(NoParams());
      final productsResult = await getAllProducts(NoParams());

      sourceResult.fold((f) => emit(ProductError(f.message)), (source) {
        productsResult.fold(
          (f) => emit(ProductError(f.message)),
          (products) => emit(ProductsLoaded(products, source!)),
        );
      });
    });

    on<AddProductEvent>((event, emit) async {
      final result = await createProduct(event.product);
      result.fold(
        (f) => emit(ProductError(f.message)),
        (_) => add(LoadAllProductsEvent()),
      );
    });

    on<DeleteProductEvent>((event, emit) async {
      final result = await deleteProduct(event.id);
      result.fold(
        (f) => emit(ProductError(f.message)),
        (_) => add(LoadAllProductsEvent()),
      );
    });

    on<TransferDataEvent>((event, emit) async {
      emit(TransferInProgress());
      final result = await transferProductData(
        TransferParams(from: event.from, to: event.to),
      );
      result.fold(
        (f) => emit(ProductError(f.message)),
        (_) => emit(TransferSuccess()),
      );
    });

    // updateProduct logic follows same pattern as create/delete
  }
}
