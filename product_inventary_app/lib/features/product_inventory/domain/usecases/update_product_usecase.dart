import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecase/usecase.dart';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase implements UseCase<void, Product> {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Product product) async {
    return await repository.updateProduct(product);
  }
}
