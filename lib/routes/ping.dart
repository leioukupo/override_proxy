import 'package:copilot_proxy/context.dart';

Future<void> getPing(Context context) async {
  context.ok();
  context.write('OK');
}
