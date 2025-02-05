import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:getresponsemobilesdk_flutter/logger.dart';

enum HttpMethod {
  get,
  post,
  delete,
}

class APIHelpers {
  APIHelpers._privateConstructor();
  static final APIHelpers _instance = APIHelpers._privateConstructor();

  factory APIHelpers() {
    return _instance;
  }

  String createJWTToken({required String secret, required String applicationId, required String installationUUID}) {
    final now = DateTime.now();
    final iat = now.subtract(const Duration(seconds: 2)).toIso8601String();
    final exp = now.add(const Duration(seconds: 18)).toIso8601String();
    final jwt = JWT(
      {
        'iss': applicationId,
        'iat': iat,
        'exp': exp,
        'aud': installationUUID,
      },
    );
    return jwt.sign(SecretKey(secret));
  }

  Future<void> _baseApiCall(
      {required HttpMethod httpMethod, required String apiEndpoint, Map<String, String?>? jsonData, required String token}) async {
    final client = HttpClient();
    HttpClientRequest request;
    switch (httpMethod) {
      case HttpMethod.get:
        request = await client.getUrl(Uri.https(apiEndpoint, "", jsonData));
        break;
      case HttpMethod.post:
        request = await client.postUrl(Uri.parse(apiEndpoint));
        break;
      case HttpMethod.delete:
        request = await client.deleteUrl(Uri.parse(apiEndpoint));
        break;
    }
    request.headers.set('X-Sdk-Version', '1.0');
    request.headers.set('Accept', 'application/json');
    request.headers.set('X-Sdk-Platform', 'Flutter');
    request.headers.set('Authorization', 'Bearer $token');
    if (httpMethod == HttpMethod.post || httpMethod == HttpMethod.delete) {
      request.write(json.encode(jsonData));
    }
    try {
      final response = await request.close();
      await _handleResponse(response: response);
    } finally {
      client.close();
    }
  }

  Future<void> _handleResponse({required HttpClientResponse response}) async {
    if (response.statusCode >= 400) {
      Logger.logMessage("Response error: ${response.statusCode}, message: ${await response.transform(utf8.decoder).join()}");
    } else {
    Logger.logMessage("Response status code: ${response.statusCode}");
    }
  }

  Future<void> get({required String apiEndpoint, Map<String, String?>? jsonData, required String token}) async =>
      _baseApiCall(httpMethod: HttpMethod.get, apiEndpoint: apiEndpoint, jsonData: jsonData, token: token);

  Future<void> post({required String apiEndpoint, Map<String, String?>? jsonData, required String token}) async =>
      _baseApiCall(httpMethod: HttpMethod.post, apiEndpoint: apiEndpoint, jsonData: jsonData, token: token);

  Future<void> delete({required String apiEndpoint, Map<String, String?>? jsonData, required String token}) async =>
      _baseApiCall(httpMethod: HttpMethod.delete, apiEndpoint: apiEndpoint, jsonData: jsonData, token: token);

  Future<void> callUrl({required String apiEndpoint}) async {
    final client = HttpClient();
    try {
      final url = Uri.parse(apiEndpoint);
      final request = await client.getUrl(url);
      final response = await request.close();
      await _handleResponse(response: response);
    } finally {
      client.close();
    }
  }
}
