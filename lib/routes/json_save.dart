import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/header_manager.dart';

Future<void> postJsonSave(Context context) async {
  await HeaderManager.instance.saveHeaders();
  context.noContent();
}
