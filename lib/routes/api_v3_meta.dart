//This file contains the handler for the /api/v3/meta route.
import 'package:copilot_proxy/context.dart';

Future<void> getApiV3Meta(Context context) async {
  context.ok();
  context.json({});
}
