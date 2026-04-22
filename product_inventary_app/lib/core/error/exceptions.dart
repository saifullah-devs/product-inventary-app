class CacheException implements Exception {}

class UnselectedSourceException implements Exception {}

class ServerException implements Exception {
  final String message;
  ServerException({this.message = "A server error occurred"});
}
