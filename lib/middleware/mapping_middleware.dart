//This file contains the mapping middleware.
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/routes/routes.dart';

Future<void> mappingMiddleware(Context context, Next _) async {
  final pathHandlerMap = methodHandlerMap[context.method];
  if (pathHandlerMap == null) {
    context.statusCode = HttpStatus.methodNotAllowed;
    return;
  }
  final record = pathHandlerMap[context.path];
  if (record == null) {
    context.statusCode = HttpStatus.notFound;
    return;
  }
  final (auth, handler) = record;
  if (auth && !context.auth) {
    context.statusCode = HttpStatus.unauthorized;
    return;
  }
  await handler(context);
}
