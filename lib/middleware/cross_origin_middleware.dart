//This file contains the cross-origin middleware.
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';

Future<void> crossOriginMiddleware(Context context, Next next) async {
  context.response.headers.set(
    HttpHeaders.accessControlAllowOriginHeader,
    '*',
  );
  context.response.headers.set(
    HttpHeaders.accessControlAllowMethodsHeader,
    'GET, POST, PUT, DELETE, OPTIONS',
  );
  context.response.headers.set(
    HttpHeaders.accessControlAllowHeadersHeader,
    'Content-Type',
  );
  if (context.method == 'options') {
    context.noContent();
    return;
  }
  await next();
}
