import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/utils/utils.dart';

Future<void> copilotTokenCheckAuth(
  String? copilotToken,
  Context context,
  Next next,
) async {
  final data = signToken2JsonMap(copilotToken);
  if (data == null) return;
  final username = data['u'];
  if (username == null) return;
  final expiresAt = int.tryParse(data['exp']);
  if (expiresAt == null) return;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (now > expiresAt) return;
  context['username'] = username;
  context.auth = true;
  await next();
}