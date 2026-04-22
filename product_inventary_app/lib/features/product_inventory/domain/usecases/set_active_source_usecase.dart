import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecase/usecase.dart';

import '../repositories/product_repository.dart';

class SetActiveSourceUseCase implements UseCase<void, DataSourceType> {
  final ProductRepository repository;
  SetActiveSourceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DataSourceType type) async {
    return await repository.setActiveDataSource(type);
  }
}
