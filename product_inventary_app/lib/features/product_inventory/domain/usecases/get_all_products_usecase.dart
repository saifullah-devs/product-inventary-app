import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetAllProductsUseCase
    implements UseCase<List<Product>, PaginationParams> {
  final ProductRepository repository;

  GetAllProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(PaginationParams params) async {
    return await repository.getAllProducts(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class PaginationParams {
  final int limit;
  final int offset;

  PaginationParams({required this.limit, required this.offset});
}
