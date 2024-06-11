import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/auth_middleware.dart';
import 'package:copilot_proxy/middleware/body_parser_middleware.dart';

export 'package:copilot_proxy/routes/api_v3_meta.dart';
export 'package:copilot_proxy/routes/api_v3_user.dart';
export 'package:copilot_proxy/routes/copilot_internal_v2_token.dart';
export 'package:copilot_proxy/routes/github_upload_token.dart';
export 'package:copilot_proxy/routes/header_upload_token.dart';
export 'package:copilot_proxy/routes/json_save.dart';
export 'package:copilot_proxy/routes/login_device.dart';
export 'package:copilot_proxy/routes/login_oauth_access_token.dart';
export 'package:copilot_proxy/routes/models.dart';
export 'package:copilot_proxy/routes/ping.dart';
export 'package:copilot_proxy/routes/telemetry.dart';
export 'package:copilot_proxy/routes/user_info.dart';

///RestHandler is a function that handles a request and returns a Future<void>.
typedef RestHandler = Future<void> Function(Context context);
typedef PathHandlerMap = Map<String, (bool, RestHandler)>;
typedef MethodHandlerMap = Map<String, PathHandlerMap>;

final MethodHandlerMap methodHandlerMap = {};

void _addHandler(
  String method,
  String path, {
  required RestHandler handler,
  CheckAuth? checkAuth,
  bool ignoreBodyParser = false,
}) {
  final pathHandlerMap = methodHandlerMap.putIfAbsent(method, () => {});
  final auth = checkAuth != null;
  if (auth) addCheckAuth(path, checkAuth);
  pathHandlerMap[path] = (auth, handler);
  if (ignoreBodyParser) ignoreParseBody(path);
}

void get(
  String path, {
  required RestHandler handler,
  CheckAuth? auth,
  bool ignoreBodyParser = false,
}) {
  _addHandler(
    'get',
    path,
    handler: handler,
    checkAuth: auth,
    ignoreBodyParser: ignoreBodyParser,
  );
}

void post(
  String path, {
  required RestHandler handler,
  CheckAuth? auth,
  bool ignoreBodyParser = false,
}) {
  _addHandler(
    'post',
    path,
    handler: handler,
    checkAuth: auth,
    ignoreBodyParser: ignoreBodyParser,
  );
}

void put(
  String path, {
  required RestHandler handler,
  CheckAuth? auth,
  bool ignoreBodyParser = false,
}) {
  _addHandler(
    'put',
    path,
    handler: handler,
    checkAuth: auth,
    ignoreBodyParser: ignoreBodyParser,
  );
}

void delete(
  String path, {
  required RestHandler handler,
  CheckAuth? auth,
  bool ignoreBodyParser = false,
}) {
  _addHandler(
    'delete',
    path,
    handler: handler,
    checkAuth: auth,
    ignoreBodyParser: ignoreBodyParser,
  );
}

void patch(
  String path, {
  required RestHandler handler,
  CheckAuth? auth,
  bool ignoreBodyParser = false,
}) {
  _addHandler(
    'patch',
    path,
    handler: handler,
    checkAuth: auth,
    ignoreBodyParser: ignoreBodyParser,
  );
}
