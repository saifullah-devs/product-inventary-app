import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = "An  error occurred"]);

  @override
  List<Object> get props => [message];
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = "An unexpected error occurred"]);
}

// General failures
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = "Server Error", this.statusCode]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = "Local Storage Error"]);
}

class UnselectedSourceFailure extends Failure {
  const UnselectedSourceFailure([super.message = "No data source selected"]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([
    super.message = "Authentication required for this source",
  ]);
}
