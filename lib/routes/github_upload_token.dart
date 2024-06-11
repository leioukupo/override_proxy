import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/token_manager.dart';
import 'package:copilot_proxy/tokens/tokens.dart';

Future<void> postGithubUploadToken(Context context) async {
  TokenManager.instance.addTokenData(TokenData.fromGHU(context['githubToken']));
  context.noContent();
}
