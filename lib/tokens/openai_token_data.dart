import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/json_util.dart';
import 'package:copilot_proxy/utils/network_util.dart';

class OpenAiTokenData extends TokenData {
  OpenAiTokenData({
    required super.authToken,
    required super.type,
    super.authUrl,
    super.httpProxyAddr,
    super.codexUrl,
    super.chatUrl,
    super.priority = 0,
    super.modelMap,
    super.concurrency,
  });

  @override
  Future<bool> refreshRequestToken() async {
    requestToken = authToken;
    return true;
  }

  @override
  Future<void> request(Context context, Uri? uri, RequestType type) async {
    final JsonMap? body = context['json'];
    if (body == null) {
      context.statusCode = HttpStatus.badRequest;
      return;
    }
    final request = await client.postUrl(uri!);
    switch (type) {
      case RequestType.codex:
        _codexRequest(body, request);
        break;
      case RequestType.chat:
        _chatRequest(body, request);
        break;
    }
    final resp = await request.close();
    final statusCode = resp.statusCode;
    context.statusCode = statusCode;
    context.response.headers.contentType = resp.headers.contentType;
    await context.response.addStream(resp);
    if (statusCode == HttpStatus.ok) return;
    invalidated();
  }

  void _chatRequest(JsonMap body, HttpClientRequest request) {
    if (!body.containsKey('function_call')) {
      final JsonList messages = body['messages'];
      final JsonMap message = messages.last;
      if (!message['content'].contains('Respond in the following locale')) {
        message['content'] += 'Respond in the following locale: ${config.local}.';
      }
      body.remove('intent');
      body.remove('intent_threshold');
      body.remove('intent_content');
      final model = body['model'];
      body['model'] = modelMap[model] ?? model;
      request.setHeaders({
        HttpHeaders.authorizationHeader: ['Bearer $requestToken'],
        HttpHeaders.contentTypeHeader: [ContentType.json.toString()],
      });
      request.send(jsonEncode(body));
    }
  }

  void _codexRequest(JsonMap body, HttpClientRequest request) {
    body.remove('extra');
    body.remove('nwo');
    final model = body['model'];
    body['model'] = modelMap[model] ?? model;
    request.setHeaders({
      HttpHeaders.authorizationHeader: ['Bearer $requestToken'],
      HttpHeaders.contentTypeHeader: [ContentType.json.toString()],
    });
    request.send(jsonEncode(body));
  }
}
