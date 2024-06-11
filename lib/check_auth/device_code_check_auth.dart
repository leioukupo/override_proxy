import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';

final Map<String, String> _userCodeDeviceCodes = {};

(String, String) generateUserCode(String clientId) {
  final deviceCode = uuid.v4();
  String gen() {
    return List.generate(6, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  var userCode = gen();
  while (_userCodeDeviceCodes.containsKey(userCode)) {
    userCode = gen();
  }

  _userCodeDeviceCodes[userCode] = deviceCode;
  return (userCode, deviceCode);
}

final Map<String, String> _deviceCodeUsernameMap = {};

bool checkUserCode(String? userCode) {
  return _userCodeDeviceCodes.containsKey(userCode);
}

bool checkDeviceCode(String? deviceCode) {
  return _deviceCodeUsernameMap.containsKey(deviceCode);
}

void allowDeviceCode(String userCode, String username) {
  final deviceCode = _userCodeDeviceCodes.remove(userCode);
  if (deviceCode == null) return;
  _deviceCodeUsernameMap[deviceCode] = username;
}

String removeDeviceCode(String deviceCode) {
  return _deviceCodeUsernameMap.remove(deviceCode)!;
}

Future<void> deviceCodeCheckAuth(
  String? _,
  Context context,
  Next next,
) async {
  if (!checkDeviceCode(context['device_code'])) {
    context.ok();
    context.json({
      'error': 'authorization_pending',
      'error_description': 'The authorization request is still pending.',
      'error_uri': 'https://docs.github.com/developers/apps/authorizing-oauth-apps#error-codes-for-the-device-flow',
    });
    return;
  }
  context.auth = true;
  await next();
}
