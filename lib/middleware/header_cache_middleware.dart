import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/header_manager.dart';
import 'package:copilot_proxy/middleware/middleware.dart';

Future<void> headerCacheMiddleware(Context context, Next next) async {
  final username = context['username'];
  if (username == null) return await next();
  HeaderManager.instance.addHeaders(username, context.path, context.headers);
  await next();
}
