import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../error/exceptions.dart';

class NetworkClient {
  final http.Client _client;
  static const String myApiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  NetworkClient(this._client);

  Future<dynamic> request({
    required String path,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final Uri uri = Uri.parse(path).replace(
      queryParameters: queryParameters?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );

    final Map<String, String> requestHeaders = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      'X-API-KEY': myApiKey,
      ...?headers,
    };

    try {
      final http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception("Method $method not supported");
      }

      return _handleResponse(response);
    } on SocketException {
      throw ServerException(message: "No Internet Connection");
    } on http.ClientException {
      throw ServerException(message: "Network Request Failed");
    }
  }

  dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    switch (statusCode) {
      case 400:
        throw ServerException(message: "Bad Request");
      case 401:
        throw ServerException(message: "Unauthorized - Please Login");
      case 403:
        throw ServerException(message: "Forbidden Access");
      case 404:
        throw ServerException(message: "Resource Not Found");
      case 500:
        throw ServerException(message: "Internal Server Error");
      default:
        throw ServerException(
          message: "Error $statusCode: ${response.reasonPhrase}",
        );
    }
  }
}
