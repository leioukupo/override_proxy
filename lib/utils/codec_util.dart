import 'dart:convert';

import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/utils/json_util.dart';
import 'package:crypto/crypto.dart';

String sha256Sign(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}

JsonMap? token2JsonMap(String? token) {
  final JsonMap result = {};
  if (token == null) return result;
  final parts = token.split(';');
  for (final part in parts) {
    final kv = part.split('=');
    if (kv.length != 2) continue;
    final key = kv[0];
    final value = kv[1];
    result[key] = value;
  }
  return result;
}

String? jsonMap2Token(JsonMap data) {
  if (data.isEmpty) return null;
  final parts = data.entries.toList();
  parts.sort((a, b) => a.key.compareTo(b.key));
  return parts.map((e) => '${e.key}=${e.value}').join(';');
}

JsonMap? signToken2JsonMap(String? token) {
  if (token == null) return null;
  final result = token2JsonMap(token);
  if (result == null) return null;
  final String? sign = result.remove('8kp');
  if (sign == null) return null;
  final rawToken = jsonMap2Token(result);
  final rawSign = sha256Sign('$rawToken;salt=${config.tokenSalt}');
  if (sign.substring(2) != rawSign) return null;
  return result;
}

String? jsonMap2SignToken(JsonMap data) {
  final token = jsonMap2Token(data);
  if (token == null) return null;
  final sign = sha256Sign('$token;salt=${config.tokenSalt}');
  return '$token;8kp=1:$sign';
}

String md5String(String data) => md5.convert(utf8.encode(data)).toString();