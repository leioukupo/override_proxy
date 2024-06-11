import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/header_manager.dart';

Future<void> deleteHeaderUploadToken(Context context) async {
  clearUpdateHeaderProviderUsernames();
  context.noContent();
}
