//This file contains the authentication middleware.
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';

Future<void> authMiddleware(Context context, Next next) async {
  final header = context.headers[HttpHeaders.authorizationHeader];
  final token = header?.firstOrNull?.split(' ').lastOrNull;
  if (token != null && token.isNotEmpty) context['token'] = token;
  final checkAuth = _pathCheckAuthMap[context.path];
  if (checkAuth == null) return await next();
  context.statusCode = HttpStatus.unauthorized;
  await checkAuth(token, context, next);
}

typedef CheckAuth = Future<void> Function(
  String? token,
  Context context,
  Next next,
);

final _pathCheckAuthMap = <String, CheckAuth>{};

void addCheckAuth(String path, CheckAuth checkAuth) {
  _pathCheckAuthMap[path] = checkAuth;
}
