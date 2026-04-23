import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecases/usecase.dart';
import '../repositories/product_repository.dart';

class DeleteProductsByIdUseCase implements UseCase<void, List<String>> {
  final ProductRepository repository;

  DeleteProductsByIdUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(List<String> ids) async {
    return await repository.deleteProductsbyID(ids);
  }
}
