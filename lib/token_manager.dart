//This file contains the TokenManager class and related methods.
import 'dart:async';

import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/utils.dart';

class HttpProxy {
  final String addr;
  int useCount = 0;

  HttpProxy(this.addr);
}

class TokenManager {
  TokenManager._();

  static final TokenManager instance = TokenManager._();

  factory TokenManager() => instance;

  final List<TokenData> _codexTokens = [];

  final List<TokenData> _chatTokens = [];

  Future<void> loadTokenData() async {
    await _loadTokenDataByDB();
    await _loadTokenDataByConfig();
  }

  Future<void> _loadTokenDataByDB() async {
    final tokenList = await getAllTokenData();
    for (final tokenMap in tokenList) {
      addTokenData(newTokenDataFromJson(tokenMap));
    }
  }

  Future<void> _loadTokenDataByConfig() async {
    final targetList = config.targetList;
    final codexTokenMap = Map<String, TokenData>.fromIterable(_codexTokens, key: (e) => e.hash);
    final chatTokenMap = Map<String, TokenData>.fromIterable(_chatTokens, key: (e) => e.hash);
    for (final tokenData in targetList) {
      final hash = tokenData.hash;
      final codexToken = codexTokenMap.remove(hash);
      final chatToken = chatTokenMap.remove(hash);
      _codexTokens.remove(codexToken);
      _chatTokens.remove(chatToken);
      tokenData.requestToken = codexToken?.requestToken ?? chatToken?.requestToken;
      addTokenData(tokenData);
    }
  }

  void addTokenData(TokenData tokenData) {
    if (tokenData.codexUrl != null) _codexTokens.add(tokenData);
    if (tokenData.chatUrl != null) _chatTokens.add(tokenData);
  }

  Future<TokenData?> _findCommonTokenData(List<TokenData> tokens) async {
    final now = DateTime.now();
    final busyTokens = <TokenData?>[];
    final availableTokens = <TokenData?>[];
    for (final tokenData in tokens) {
      //token is invalid
      if (tokenData.isInvalidated) continue;
      //token is busy
      if (tokenData.isBusy) {
        busyTokens.add(tokenData);
        continue;
      }
      if (!tokenData.isExpiry(now) && tokenData.requestToken != null) {
        availableTokens.add(tokenData);
        continue;
      }
      //token is expiry or copilotToken not exists
      tokenData.lock();
      final result = await tokenData.refreshRequestToken();
      tokenData.unlock();
      if (!result) continue;
      await saveTokenData(tokenData);
      availableTokens.add(tokenData);
    }
    if (availableTokens.isNotEmpty) return availableTokens.best;
    if (busyTokens.isNotEmpty) return busyTokens.best;
    return null;
  }

  Future<TokenData?> _findTokenData(List<TokenData> tokens) async {
    final futures = <Future<TokenData?>>[];
    for (final type in TokenType.values) {
      futures.add(_findCommonTokenData(tokens.where((e) => e.type == type).toList()));
    }
    final results = await Future.wait(futures);
    return results.best;
  }

  Future<T?> _useTokenData<T>(
    String? username,
    Context context,
    List<TokenData> tokens,
    Future<T> Function(TokenData? tokenData) callback,
  ) async {
    final tempTokens = List.of(tokens);
    for (final token in tempTokens) {
      if (!token.isInvalidated) continue;
      tokens.remove(token);
      await removeTokenData(token);
    }

    final completer = Completer<T?>();

    Future<void> useToken(TokenData? token) async {
      try {
        final result = await callback(token);
        completer.complete(result);
      } catch (e, s) {
        logError(e, s, 'useToken');
        context.internalServerError();
        completer.complete(null);
      }
    }

    TokenDebouncer.run(username, () async {
      final tokenData = await _findTokenData(tokens);
      //没有可用token
      if (tokenData == null) return useToken(null);
      //等待token解锁
      while (tokenData.isBusy) {
        await tokenData.wait();
      }
      //锁token
      tokenData.lock();
      //统一减少使用次数
      if (tokenData.useCount > 100000) {
        final minUseCount = tokens.minUse.useCount;
        for (var e in tokens) {
          e.decreaseUseCount(minUseCount);
        }
      }
      await useToken(tokenData);
      //解锁token
      tokenData.unlock();
    });

    return completer.future;
  }

  Future<T?> useCodexTokenData<T>(
    String? username,
    Context context,
    Future<T> Function(TokenData? tokenData) callback,
  ) {
    return _useTokenData(username, context, _codexTokens, callback);
  }

  Future<T?> useChatTokenData<T>(
    String? username,
    Context context,
    Future<T> Function(TokenData? tokenData) callback,
  ) {
    return _useTokenData(username, context, _chatTokens, callback);
  }

  Future<void> closeClient() async {
    for (final token in _chatTokens + _codexTokens) {
      token.client.close(force: true);
    }
  }
}

class TokenDebouncer {
  static final _usernameDebouncerMap = <String, TokenDebouncer>{};
  static final duration = Duration(milliseconds: config.copilotDebounce);
  Timer? _timer;

  static void run(String? username, Future<void> Function() action) {
    final debouncer = _usernameDebouncerMap[username ?? ''] ??= TokenDebouncer();
    debouncer._timer?.cancel();
    debouncer._timer = Timer(duration, () async {
      await action();
      _usernameDebouncerMap.remove(username);
    });
  }
}
