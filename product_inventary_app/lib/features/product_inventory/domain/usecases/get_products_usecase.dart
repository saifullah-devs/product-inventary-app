import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecase/usecase.dart';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductUseCase implements UseCase<Product, String> {
  final ProductRepository repository;

  GetProductUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(String id) async {
    return await repository.getProduct(id);
  }
}
