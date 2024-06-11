import 'package:copilot_proxy/context.dart';

export 'package:copilot_proxy/middleware/auth_middleware.dart';
export 'package:copilot_proxy/middleware/body_parser_middleware.dart';
export 'package:copilot_proxy/middleware/cross_origin_middleware.dart';
export 'package:copilot_proxy/middleware/header_cache_middleware.dart';
export 'package:copilot_proxy/middleware/logging_middleware.dart';
export 'package:copilot_proxy/middleware/mapping_middleware.dart';

typedef Next = Future<void> Function();
typedef Middleware = Future<void> Function(Context context, Next next);

final List<Middleware> _middlewares = [];

void use(Middleware middleware) => _middlewares.add(middleware);

Future<void> runMiddleware(Context context, int index) async {
  if (index >= _middlewares.length) return;
  await _middlewares[index](context, () => runMiddleware(context, index + 1));
}