import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/safe_http_response.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/utils.dart';

class Context {
  final HttpRequest request;
  final SafeHttpResponse response;
  final String method;
  final String path;
  final JsonMap query;
  final HeaderMap headers;

  final JsonMap _data = {};

  Context(this.request)
      : response = SafeHttpResponse(request.response),
        method = request.method.toLowerCase(),
        path = request.uri.path,
        query = request.uri.queryParameters,
        headers = request.headers.toFullMap();

  dynamic operator [](String key) {
    final value = _data[key];
    if (value != null) return value;
    final json = _data['json'];
    if (json is Map) {
      final jsonValue = json[key];
      if (jsonValue != null) return jsonValue;
    }
    final queryValue = query[key];
    if (queryValue != null) return queryValue;
    final headerMapValue = headers[key]?.firstOrNull;
    if (headerMapValue != null) return headerMapValue;
    final headerValue = request.headers.value(key);
    return headerValue;
  }

  void operator []=(String key, dynamic value) => _data[key] = value;

  bool get hasData => _data.isNotEmpty;

  void _log(Object? object) {
    if (object is String) {
      log('resp: $object');
    } else {
      log('resp: ${jsonPretty(object)}');
    }
  }

  void write(Object? object) {
    _log(object);
    response.write(object);
  }

  void writeln([Object? object = ""]) {
    _log(object);
    response.writeln(object);
  }

  set statusCode(int code) => response.statusCode = code;

  void ok() => statusCode = HttpStatus.ok;

  void internalServerError() => statusCode = HttpStatus.internalServerError;

  void noContent() => statusCode = HttpStatus.noContent;

  void json(dynamic data) {
    response.headers.contentType = ContentType.json;
    write(jsonEncode(data));
  }

  bool isTokenDataWrong(TokenData? token) {
    if (token != null) return false;
    log('token is null');
    internalServerError();
    return true;
  }

  bool? _auth;

  bool get auth => _auth ?? false;

  set auth(bool value) => _auth = value;

  @override
  String toString() {
    return jsonPretty({
      if (query.isNotEmpty) 'query': query,
      'auth': auth,
      if (_data.isNotEmpty) 'data': _data,
    });
  }

  String toLimitString([int length = 100]) {
    final str = toString();
    return str.length <= length ? str : str.substring(0, length);
  }
}
