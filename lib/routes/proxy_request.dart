import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/routes/routes.dart';
import 'package:copilot_proxy/token_manager.dart';
import 'package:copilot_proxy/tokens/tokens.dart';

RestHandler proxyRequest(RequestType type) {
  return (Context context) {
    final String username = context['username'];

    final Future<T?> Function<T>(
      String? username,
      Context context,
      Future<T> Function(TokenData? tokenData) callback,
    ) useTokenData;

    final Uri? Function(
      TokenData? tokenData,
    ) getUri;

    switch (type) {
      case RequestType.codex:
        useTokenData = TokenManager.instance.useCodexTokenData;
        getUri = (t) => t?.codexUrl;
      case RequestType.chat:
        useTokenData = TokenManager.instance.useChatTokenData;
        getUri = (t) => t?.chatUrl;
    }

    return useTokenData(
      username,
      context,
      (token) async {
        if (context.isTokenDataWrong(token)) return;
        await token!.request(context, getUri(token), type);
      },
    );
  };
}
