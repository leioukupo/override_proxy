//This file contains the handler for the /api/v3/user route.
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/utils.dart';

Future<void> getApiV3User(Context context) async {
  final username = context['username'];
  final userInfo = await getUser(username);
  context.ok();
  context.json(userInfo);
}
