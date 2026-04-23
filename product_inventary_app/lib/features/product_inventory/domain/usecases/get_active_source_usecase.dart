import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecases/usecase.dart';
import '../repositories/product_repository.dart';

class GetActiveDataSourceUseCase implements UseCase<DataSourceType?, NoParams> {
  final ProductRepository repository;

  GetActiveDataSourceUseCase(this.repository);

  @override
  Future<Either<Failure, DataSourceType?>> call(NoParams params) async {
    return await repository.getActiveDataSource();
  }
}
