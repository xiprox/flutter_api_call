library api_call;

export 'resource.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:universal_io/io.dart';

import 'resource.dart';
import 'types.dart';

enum HttpMethod { get, post, put, delete, patch }

/// Allows limited access to an [ApiCall] instance.
class ApiCallHandler<T> {
  final ApiCall<T> _call;

  ApiCallHandler(ApiCall<T> call) : _call = call;

  Future<Resource<T>> execute({bool json = true}) {
    return _call.execute(json: json);
  }

  Stream<Resource<T>> watch({bool json = true}) {
    return _call.watch(json: json);
  }
}

/// A helper class to neatly create an http call.
class ApiCall<T> {
  final Dio dio;

  ApiCall(this.dio);

  late HttpMethod _method;
  late String _endpoint;
  Map<String, dynamic> _params = {};
  Map<String, String> _headers = {};
  dynamic _body;
  ResponseParseFunction<T>? _parser;

  ApiCall<T> get(String endpoint) {
    _method = HttpMethod.get;
    _endpoint = endpoint;
    return this;
  }

  ApiCall<T> post(String endpoint) {
    _method = HttpMethod.post;
    _endpoint = endpoint;
    return this;
  }

  ApiCall<T> put(String endpoint) {
    _method = HttpMethod.put;
    _endpoint = endpoint;
    return this;
  }

  ApiCall<T> patch(String endpoint) {
    _method = HttpMethod.patch;
    _endpoint = endpoint;
    return this;
  }

  ApiCall<T> delete(String endpoint) {
    _method = HttpMethod.delete;
    _endpoint = endpoint;
    return this;
  }

  /// Request parameters.
  ///
  /// Feel free to pass null headers as they will be cleaned up.
  ApiCall<T> params(Map<String, dynamic> params) {
    _params = params;
    _params.removeWhere((key, value) => value == null);
    return this;
  }

  /// Request headers.
  ///
  /// Feel free to pass null headers as they will be cleaned up.
  ApiCall<T> headers(Map<String, String?> headers) {
    headers.removeWhere((key, value) => value == null);
    _headers = Map<String, String>.from(headers);
    return this;
  }

  /// Request body.
  ///
  /// Feel free to pass null params as they will be cleaned up.
  ApiCall<T> bodyJson(Json body) {
    body.removeWhere((key, value) => value == null);
    _body = body;
    return this;
  }

  /// Request body.
  ///
  /// Feel free to pass null params as they will be cleaned up.
  ApiCall<T> body(String body) {
    _body = body;
    return this;
  }

  ApiCall<T> parseWith(ResponseParseFunction<T> parseFunction) {
    _parser = parseFunction;
    return this;
  }

  /// Combines all parts and executes the http request, then returns a [Future].
  Future<Resource<T>> execute({bool json = true}) async {
    Response? response;

    final options = Options(
      headers: _headers,
      responseType: json ? ResponseType.json : ResponseType.plain,
      contentType: (json ? ContentType.json : ContentType.text).value,
    );

    try {
      switch (_method) {
        case HttpMethod.get:
          response = await dio.get(
            _endpoint,
            options: options,
            queryParameters: _params,
          );
          break;
        case HttpMethod.post:
          response = await dio.post(
            _endpoint,
            options: options,
            data: _body,
            queryParameters: _params,
          );
          break;
        case HttpMethod.put:
          response = await dio.put(
            _endpoint,
            options: options,
            data: _body,
            queryParameters: _params,
          );
          break;
        case HttpMethod.delete:
          response = await dio.delete(
            _endpoint,
            options: options,
            queryParameters: _params,
          );
          break;
        case HttpMethod.patch:
          response = await dio.patch(
            _endpoint,
            options: options,
            data: _body,
            queryParameters: _params,
          );
          break;
      }
    } catch (e, s) {
      if (e is DioError) {
        final errorResponse = e.response;
        if (errorResponse?.data == null) {
          return Resource<T>.exceptionWithStack(Exception(e.error), s);
        } else {
          if (errorResponse?.data?['error'] != null) {
            if (errorResponse?.data['error'] is String) {
              return Resource<T>.error(errorResponse?.data?['error'] ?? '?');
            }
            return Resource<T>.error(
              errorResponse?.data?['error']?['message'] ?? '?',
            );
          }
        }
      } else {
        return Resource<T>.exceptionWithStack(Exception(e), s);
      }
    }

    if (response?.data != null) {
      if (_parser != null) {
        return Resource<T>.success(_parser!(response!.data!));
      } else {
        return Resource<T>.success(response!.data! as T);
      }
    } else {
      return Resource<T>.empty();
    }
  }

  Stream<Resource<T>> watch({bool json = true}) async* {
    yield Resource<T>.loading();
    yield await execute(json: json);
  }

  ApiCallHandler<T> handler() => ApiCallHandler<T>(this);
}
