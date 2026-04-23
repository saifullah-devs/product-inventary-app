import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecases/usecase.dart';
import '../repositories/product_repository.dart';

class TransferDataUseCase implements UseCase<void, TransferDataParams> {
  final ProductRepository repository;

  TransferDataUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransferDataParams params) async {
    return await repository.transferData(
      productIds: params.productIds,
      from: params.from,
      to: params.to,
    );
  }
}

class TransferDataParams {
  final List<String> productIds;
  final DataSourceType from;
  final DataSourceType to;

  TransferDataParams({
    required this.productIds,
    required this.from,
    required this.to,
  });
}
