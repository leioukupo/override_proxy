import 'dart:async';

import 'package:copilot_proxy/copilot_proxy.dart' as copilot_proxy;
import 'package:copilot_proxy/utils/log_util.dart';

Future<void> main(List<String> args) async {
  await runZonedGuarded(
    () => copilot_proxy.main(args),
    logError,
  );
}
