// This file contains the main function and HTTP server initialization.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:copilot_proxy/check_auth/check_auth.dart';
import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/config.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/extension.dart';
import 'package:copilot_proxy/header_manager.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/routes/proxy_request.dart';
import 'package:copilot_proxy/routes/routes.dart';
import 'package:copilot_proxy/token_manager.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/utils.dart';

Future<void> main(List<String> args) async {
  final configFilePath = parseArguments(args);
  await initializeConfig(configFilePath);
  await loadAllData();
  //listen signal to stop server
  final serverStopCompleter = Completer<void>();
  final allRequestsCompletedCompleter = Completer<void>();
  var isServerStopping = false;
  var activeRequestCount = 0;

  void stopServer(_) {
    isServerStopping = true;
    serverStopCompleter.complete();
  }

  final sigintListen = ProcessSignal.sigint.watch().listen(stopServer);
  final sigtermListen = Platform.isWindows ? null : ProcessSignal.sigterm.watch().listen(stopServer);
  final stdinListen = utf8.decoder.bind(stdin).listen((e) {
    e = e.trim();
    if (e == 'exit') stopServer(e);
  });
  //start server
  final httpServer = await HttpServer.bind(config.listenIp, config.listenPort);
  setupMiddleware();
  setupRoutes();
  //start server listen
  final httpServerListen = httpServer.listen((request) async {
    if (isServerStopping) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      return;
    }
    activeRequestCount++;
    await handleRequest(request);
    activeRequestCount--;
    if (!isServerStopping) return;
    if (activeRequestCount == 0) allRequestsCompletedCompleter.complete();
  });
  log('server start: ${httpServer.address.host}:${httpServer.port}');
  //stop server
  await serverStopCompleter.future;
  await stdinListen.cancel();
  await sigintListen.cancel();
  await sigtermListen?.cancel();
  await httpServerListen.cancel();
  if (activeRequestCount != 0) await allRequestsCompletedCompleter.future;
  await httpServer.close();
  await HeaderManager.instance.saveHeaders();
  await saveDB();
  await TokenManager.instance.closeClient();
  log('server stop');
  exit(0);
}

Future<void> handleRequest(HttpRequest request) async {
  final context = Context(request);
  final response = context.response;
  try {
    await runMiddleware(context, 0);
  } catch (e, s) {
    logError(e, s, 'handleRequest');
    response.statusCode = HttpStatus.internalServerError;
  } finally {
    await response.close();
  }
}

void setupRoutes() {
  //login
  //生成userCode和deviceCode绑定
  post(
    '/login/device/code',
    handler: postLoginDeviceCode,
  );
  get(
    '/login/device',
    handler: getLoginDevice,
  );
  post(
    '/login/oauth/access_token',
    handler: postLoginOauthAccessToken,
    auth: deviceCodeCheckAuth,
  );
  get(
    '/api/v3/user',
    handler: getApiV3User,
    auth: accessTokenCheckAuth,
  );
  get(
    '/user',
    handler: getApiV3User,
    auth: accessTokenCheckAuth,
  );
  get(
    '/api/v3/meta',
    handler: getApiV3Meta,
    auth: accessTokenCheckAuth,
  );
  get(
    '/copilot_internal/v2/token',
    handler: getCopilotInternalV2Token,
    auth: accessTokenCheckAuth,
  );
  get(
    '/_ping',
    handler: getPing,
  );
  //completions
  post(
    '/v1/engines/copilot-codex/completions',
    handler: proxyRequest(RequestType.codex),
    auth: copilotTokenCheckAuth,
  );
  post(
    '/chat/completions',
    handler: proxyRequest(RequestType.chat),
    auth: copilotTokenCheckAuth,
  );
  get(
    modelPath,
    handler: getModels,
    auth: copilotTokenCheckAuth,
  );
  //telemetry
  post(
    '/telemetry',
    handler: postTelemetry,
    ignoreBodyParser: true,
  );
  //admin
  //清空header提供者
  delete(
    '/header/upload_token',
    handler: deleteHeaderUploadToken,
    auth: adminTokenCheckAuth,
  );
  //上传ghu
  post(
    '/github/upload_token',
    handler: postGithubUploadToken,
    auth: adminTokenCheckAuth,
  );
  //保存数据
  post(
    '/json/save',
    handler: postJsonSave,
    auth: adminTokenCheckAuth,
  );
  //添加账号密码
  post(
    '/user/add',
    handler: postUserInfo,
    auth: adminTokenCheckAuth,
  );
}

void setupMiddleware() {
  use(crossOriginMiddleware);
  use(bodyParserMiddleware);
  use(loggingMiddleware);
  use(authMiddleware);
  use(headerCacheMiddleware);
  use(mappingMiddleware);
}

Future<void> loadAllData() async {
  await loadDB();
  await HeaderManager.instance.loadHeaders();
  await TokenManager.instance.loadTokenData();
}

Future<void> initializeConfig(String configFilePath) async {
  final configFile = File(configFilePath);
  if (!configFile.existsSync()) throw '$configFilePath not found';
  final configMap = jsonDecode(await configFile.readAsString());
  config = Config.fromJson(configMap);
  config.configFilePath = configFilePath;
}

String parseArguments(List<String> args) {
  final argParser = ArgParser();
  argParser.addOption(
    'config-file',
    abbr: 'c',
    help: 'config json file',
  );
  argParser.addFlag(
    'no-log',
    help: 'disable log',
    defaultsTo: false,
  );
  final argResult = argParser.parse(args);
  noLog = argResult['no-log'] as bool;
  return argResult.getString(
    'config-file',
    'CONFIG_FILE',
    './config.json',
  );
}
