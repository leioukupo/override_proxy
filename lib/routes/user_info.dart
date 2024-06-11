import 'dart:io';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/db_util.dart';

Future<void> postUserInfo(Context context) async {
  final String? username = context['username'];
  final String? password = context['password'];
  if (username == null || username.isEmpty || password == null || password.isEmpty) {
    context.statusCode = HttpStatus.badRequest;
    return;
  }
  final userJson = await addUser(username, password);
  context.ok();
  context.json(userJson);
}
