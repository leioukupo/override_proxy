//This file contains the handler for the /login/oauth/access_token route.
import 'package:copilot_proxy/check_auth/check_auth.dart';
import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/codec_util.dart';

Future<void> postLoginOauthAccessToken(Context context) async {
  final username = removeDeviceCode(context['device_code']);
  final accessToken = jsonMap2SignToken({
    't': uuid.v4(),
    'u': username,
  })!;
  addAccessToken(accessToken, username);
  context.ok();
  context.json({
    'access_token': accessToken,
    'scope': 'user:email',
    'token_type': 'bearer',
  });
}
