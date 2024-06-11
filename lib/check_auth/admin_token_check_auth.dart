import 'dart:convert';

import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';

final _basicToken = base64Encode(utf8.encode('admin:${config.adminPassword}'));

Future<void> adminTokenCheckAuth(
  String? token,
  Context context,
  Next next,
) async {
  if (_basicToken != token) return;
  context.auth = true;
  await next();
}
