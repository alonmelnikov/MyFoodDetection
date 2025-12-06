import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../enums/network_errors.dart';
import '../models/result.dart';

/// Protocol (interface) for making HTTP API calls.
abstract class ApiService {
  Future<Result<Map<String, dynamic>, NetworkError?>> get(
    Uri uri, {
    Map<String, String>? headers,
  });

  Future<Result<Map<String, dynamic>, NetworkError?>> post(
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });
}

class HttpApiService implements ApiService {
  HttpApiService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  @override
  Future<Result<Map<String, dynamic>, NetworkError>> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>? ??
            <String, dynamic>{};
        return Result<Map<String, dynamic>, NetworkError>.success(json);
      }

      return Result<Map<String, dynamic>, NetworkError>.failure(
        _mapStatusCodeToError(response.statusCode),
      );
    } on SocketException {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.noInternet,
      );
    } on TimeoutException {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.timeout,
      );
    } catch (_) {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.unknown,
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>, NetworkError>> post(
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      final response = await _client
          .post(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>? ??
            <String, dynamic>{};
        return Result<Map<String, dynamic>, NetworkError>.success(json);
      }

      return Result<Map<String, dynamic>, NetworkError>.failure(
        _mapStatusCodeToError(response.statusCode),
      );
    } on SocketException {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.noInternet,
      );
    } on TimeoutException {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.timeout,
      );
    } catch (_) {
      return Result<Map<String, dynamic>, NetworkError>.failure(
        NetworkError.unknown,
      );
    }
  }

  NetworkError _mapStatusCodeToError(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return NetworkError.unauthorized;
    }
    if (statusCode == 404) {
      return NetworkError.notFound;
    }
    if (statusCode >= 500) {
      return NetworkError.serverError;
    }
    return NetworkError.badResponse;
  }
}
