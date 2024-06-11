//This file contains the body parser middleware.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/utils/log_util.dart';

Future<void> bodyParserMiddleware(Context context, Next next) async {
  try {
    if (!_parseMethods.contains(context.method)) return;
    if (_ignorePaths.contains(context.path)) return;
    final body = await utf8.decoder.bind(context.request).join();
    if (body.isEmpty) return;
    context['body'] = body;
    final header = context.headers[HttpHeaders.contentTypeHeader];
    final contentType = header?.firstOrNull?.toLowerCase();
    final isJsonType = contentType?.contains('json') ?? false;
    if (isJsonType) context['json'] = jsonDecode(body);
  } catch (e, s) {
    logError(e, s, 'bodyParserMiddleware');
  } finally {
    await next();
  }
}

final _parseMethods = <String>{'post', 'put'};

final _ignorePaths = <String>{};

///Ignore body parser for the specified path.
///ignored paths will not parse the request body.need process request body manually.
void ignoreParseBody(String path) => _ignorePaths.add(path);
