import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/header_manager.dart';
import 'package:copilot_proxy/token_manager.dart';
import 'package:copilot_proxy/tokens/token_type.dart';
import 'package:copilot_proxy/utils/utils.dart';

const _updateDuration = Duration(hours: 1);
const modelPath = '/models';

DateTime? _lastDataTime;
String _cacheData = jsonEncode({
  'data': [
    {
      'capabilities': {'family': 'gpt-3.5-turbo', 'object': 'model_capabilities', 'type': 'chat'},
      'id': 'gpt-3.5-turbo',
      'name': 'GPT 3.5 Turbo',
      'object': 'model',
      'version': 'gpt-3.5-turbo-0613'
    },
    {
      'capabilities': {'family': 'gpt-3.5-turbo', 'object': 'model_capabilities', 'type': 'chat'},
      'id': 'gpt-3.5-turbo-0613',
      'name': 'GPT 3.5 Turbo (2023-06-13)',
      'object': 'model',
      'version': 'gpt-3.5-turbo-0613'
    },
    {
      'capabilities': {'family': 'gpt-4', 'object': 'model_capabilities', 'type': 'chat'},
      'id': 'gpt-4',
      'name': 'GPT 4',
      'object': 'model',
      'version': 'gpt-4-0613'
    },
    {
      'capabilities': {'family': 'gpt-4', 'object': 'model_capabilities', 'type': 'chat'},
      'id': 'gpt-4-0613',
      'name': 'GPT 4 (2023-06-13)',
      'object': 'model',
      'version': 'gpt-4-0613'
    },
    {
      'capabilities': {'family': 'text-embedding-ada-002', 'object': 'model_capabilities', 'type': 'embeddings'},
      'id': 'text-embedding-ada-002',
      'name': 'Embedding V2 Ada',
      'object': 'model',
      'version': 'text-embedding-ada-002'
    },
    {
      'capabilities': {'family': 'text-embedding-ada-002', 'object': 'model_capabilities', 'type': 'embeddings'},
      'id': 'text-embedding-ada-002-index',
      'name': 'Embedding V2 Ada (Index)',
      'object': 'model',
      'version': 'text-embedding-ada-002'
    },
    {
      'capabilities': {'family': 'text-embedding-3-small', 'object': 'model_capabilities', 'type': 'embeddings'},
      'id': 'text-embedding-3-small',
      'name': 'Embedding V3 small',
      'object': 'model',
      'version': 'text-embedding-3-small'
    },
    {
      'capabilities': {'family': 'text-embedding-3-small', 'object': 'model_capabilities', 'type': 'embeddings'},
      'id': 'text-embedding-3-small-inference',
      'name': 'Embedding V3 small (Inference)',
      'object': 'model',
      'version': 'text-embedding-3-small'
    }
  ],
  'object': 'list'
});

Future<void> getModels(Context context) async {
  await _updateCacheAndResp(context);
  context.ok();
  context.response.headers.contentType = ContentType.json;
  context.write(_cacheData);
}

Future<void> _updateCacheAndResp(Context context) async {
  final now = DateTime.now();
  final username = context['username'];
  if (username == null) return;
  if (_lastDataTime != null && now.difference(_lastDataTime!) < _updateDuration) return;
  await TokenManager.instance.useChatTokenData(
    username,
    context,
    (token) async {
      if (token == null || context.isTokenDataWrong(token)) return;
      if (token.type != TokenType.copilot) return;
      final chatUrl = token.chatUrl;
      if (chatUrl == null) return;
      final modelUrl = chatUrl.resolve(modelPath);
      final request = await token.client.postUrl(modelUrl);
      final headers = HeaderManager.instance.getHeaders(modelPath);
      request.setHeaders({
        ...headers,
        HttpHeaders.authorizationHeader: ['Bearer ${token.requestToken}'],
      });
      final resp = await request.close();
      final data = await utf8.decoder.bind(resp).join();
      if (resp.statusCode != HttpStatus.ok) return token.setExpiry(now);
      _cacheData = data;
      _lastDataTime = now;
    },
  );
}
