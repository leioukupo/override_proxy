import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/extension.dart';
import 'package:copilot_proxy/header_manager.dart';
import 'package:copilot_proxy/tokens/lock.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/utils.dart';

class TokenData {
  final Uri? authUrl;
  final String authToken;
  final TokenType type;
  final String? httpProxyAddr;
  final Uri? codexUrl;
  final Uri? chatUrl;
  final int priority;

  late final Map<String, String> modelMap;
  late final Lock _lock;

  String? requestToken;
  DateTime? _expiry;
  int _invalidatedCount = 0;
  int _useCount = 0;

  final client = HttpClient();

  TokenData({
    required this.authToken,
    required this.type,
    this.authUrl,
    this.httpProxyAddr,
    this.codexUrl,
    this.chatUrl,
    this.priority = 0,
    Map<String, String>? modelMap,
    int concurrency = 1,
  }) {
    final proxyAddr = httpProxyAddr;
    if (proxyAddr != null) setHttpProxy(proxyAddr);
    this.modelMap = modelMap ?? {};
    _lock = Lock(concurrency);
  }

  String get hash {
    return md5String('$type$authToken$codexUrl$chatUrl');
  }

  void setHttpProxy(String httpProxyAddr) {
    final proxy = 'PROXY $httpProxyAddr';
    client.findProxy = (uri) => proxy;
  }

  void invalidated() => _invalidatedCount++;

  bool get isInvalidated => _invalidatedCount >= 3;

  bool isExpiry(DateTime now) {
    final time = _expiry;
    return time != null && now.isAfter(time);
  }

  ///设置过期
  void setExpiry(DateTime now) => _expiry = now;

  int get useCount => _useCount;

  //减少useCount
  void decreaseUseCount(int value) => _useCount -= value;

  void lock() {
    _useCount++;
    _lock.lock();
  }

  void unlock() => _lock.unlock();

  Future<void> wait() => _lock.wait();

  bool get isBusy => _lock.isBusy;

  Future<bool> refreshRequestToken() async {
    try {
      final request = await client.getUrl(authUrl!);
      final headers = HeaderManager.instance.getHeaders(authUrl!.path);
      final customHeaders = {
        ...headers,
        HttpHeaders.authorizationHeader: ['token $authToken'],
      };
      request.setHeaders(customHeaders);
      final resp = await request.close();
      if (resp.statusCode != HttpStatus.ok) throw 'refreshCopilot: fail';
      final bodyJson = jsonDecode(await resp.getBody());
      final token = bodyJson['token'];
      final expiryAt = bodyJson['expires_at'];
      requestToken = token;
      _useCount = 0;
      _invalidatedCount = 0;
      log('refreshCopilot: ok');
      if (expiryAt == null) return true;
      _expiry = DateTime.fromMillisecondsSinceEpoch(expiryAt * 1000);
    } catch (e, s) {
      logError(e, s, 'refreshRequestToken');
      invalidated();
      return false;
    }
    return true;
  }

  Future<void> request(Context context, Uri? uri, RequestType type) async {
    final String? body = context['body'];
    if (body == null) {
      context.statusCode = HttpStatus.badRequest;
      return;
    }
    final request = await client.postUrl(uri!);
    final headers = HeaderManager.instance.getHeaders(uri.path);
    request.setHeaders({
      ...headers,
      HttpHeaders.authorizationHeader: ['Bearer $requestToken'],
    });
    request.send(body);
    final resp = await request.close();
    final statusCode = resp.statusCode;
    context.statusCode = statusCode;
    resp.headers.forEach((k, v) => context.response.headers.set(k, v));
    await context.response.addStream(resp);
    if (statusCode == HttpStatus.ok) return;
    setExpiry(DateTime.now());
  }

  factory TokenData.fromGHU(githubToken) {
    return TokenData(
      authUrl: Uri.parse('https://api.github.com/copilot_internal/v2/token'),
      authToken: githubToken,
      type: TokenType.copilot,
      codexUrl: Uri.parse('https://copilot-proxy.githubusercontent.com/v1/engines/copilot-codex/completions'),
      chatUrl: Uri.parse('https://api.githubcopilot.com/chat/completions'),
    );
  }

  JsonMap toJson() {
    return {
      'authUrl': authUrl.toString(),
      'authToken': authToken,
      'type': tokenTypeToString(type),
      'httpProxyAddr': httpProxyAddr,
      'codexUrl': codexUrl.toString(),
      'chatUrl': chatUrl.toString(),
      'priority': priority,
      'modelMap': modelMap,
      'concurrency': _lock.concurrency,
      'expiry': _expiry?.toIso8601String(),
      'requestToken': requestToken,
      'invalidatedCount': _invalidatedCount,
      'useCount': _useCount,
    };
  }
}

extension ExNullTokenDataList on List<TokenData?> {
  TokenData? get best {
    if (every((e) => e == null)) return null;
    return reduce((a, b) {
      if (a == null) return b;
      if (b == null) return a;
      if (!(a.isBusy ^ b.isBusy)) return a.isBusy ? b : a;
      if (a.priority != b.priority) return a.priority > b.priority ? b : a;
      return a._useCount > b._useCount ? b : a;
    });
  }
}

extension ExTokenDataList on List<TokenData> {
  TokenData get minUse => minBy((e) => e._useCount);
}

TokenData newTokenDataFromJson(JsonMap tokenMap) {
  final String? codexUrlString = tokenMap['codexUrl'];
  final String? chatUrlString = tokenMap['chatUrl'];
  final authUrl = Uri.parse(tokenMap['authUrl']);
  final authToken = tokenMap['authToken'];
  final type = tokenTypeFromString(tokenMap['type'] ?? 'copilot');
  final httpProxyAddr = tokenMap['httpProxyAddr'];
  final codexUrl = codexUrlString == null ? null : Uri.parse(codexUrlString);
  final chatUrl = chatUrlString == null ? null : Uri.parse(chatUrlString);
  final priority = tokenMap['priority'] ?? 0;
  final JsonMap? modelJsonMap = tokenMap['modelMap'];
  final modelMap = modelJsonMap?.cast<String, String>();
  final concurrency = tokenMap['concurrency'] ?? 1;
  final tokenData = switch (type) {
    TokenType.copilot => TokenData(
        authUrl: authUrl,
        authToken: authToken,
        type: type,
        httpProxyAddr: httpProxyAddr,
        codexUrl: codexUrl,
        chatUrl: chatUrl,
        priority: priority,
        modelMap: modelMap,
        concurrency: concurrency,
      ),
    TokenType.openai => OpenAiTokenData(
        authUrl: authUrl,
        authToken: authToken,
        type: type,
        httpProxyAddr: httpProxyAddr,
        codexUrl: codexUrl,
        chatUrl: chatUrl,
        priority: priority,
        modelMap: modelMap,
        concurrency: concurrency,
      ),
  };
  tokenData.requestToken = tokenMap['requestToken'];
  tokenData._invalidatedCount = tokenMap['invalidatedCount'] ?? 0;
  tokenData._useCount = tokenMap['useCount'] ?? 0;
  tokenData._expiry = DateTime.tryParse(tokenMap['expiry'] ?? '');
  return tokenData;
}
