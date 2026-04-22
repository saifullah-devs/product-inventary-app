import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import 'package:product_inventary_app/core/usecase/usecase.dart';

import '../repositories/product_repository.dart';

class TransferProductDataUseCase implements UseCase<void, TransferParams> {
  final ProductRepository repository;
  TransferProductDataUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransferParams params) async {
    return await repository.transferData(from: params.from, to: params.to);
  }
}

class TransferParams extends Equatable {
  final DataSourceType from;
  final DataSourceType to;

  const TransferParams({required this.from, required this.to});

  @override
  List<Object?> get props => [from, to];
}
