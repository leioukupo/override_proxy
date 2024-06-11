//This file contains the logging middleware.
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/utils/utils.dart';

Future<void> loggingMiddleware(Context context, Next next) async {
  final start = DateTime.now();
  final prefix = [
    '$start [${context.method}] ${context.path}',
    'requestedUri: ${context.request.requestedUri}',
    'headers: ${jsonPretty(context.request.headers.toFullMap())}',
  ];
  try {
    await next();
  } finally {
    log(prefix[0]);
    log(prefix[1], false);
    log(prefix[2], false);
    final end = DateTime.now();
    final time = end.difference(start).inMilliseconds;
    final clientIP = context['cf-connecting-ip'] ?? context['x-forwarded-for'];
    if (clientIP != null) log('clientIp: $clientIP');
    if (context.hasData) log('context: $context');
    log('code: ${context.response.statusCode}, cost: ${time}ms\n');
    if (context.auth) await _bindIPToUser(context['username'], clientIP);
  }
}

Future<void> _bindIPToUser(String? username, String? clientIP) async {
  if (username == null || clientIP == null) return;
  final user = await getUser(username);
  if (user == null) return;
  final tempIPs = user['ips'] as JsonList? ?? [];
  final Set<String> ips = {};
  for (final ip in tempIPs) {
    if (ip == null) continue;
    ips.add(ip);
  }
  ips.add(clientIP);
  await saveUser(username, {'ips': ips.toList()});
}

String? getClientIdByCopilotToken(String? copilotToken) {
  if (copilotToken == null) return null;
  final parts = copilotToken.split(';');
  for (final part in parts) {
    final kv = part.split('=');
    if (kv.length != 2) continue;
    final key = kv[0];
    final value = kv[1];
    if (key == 'cid') return value;
  }
  return null;
}
