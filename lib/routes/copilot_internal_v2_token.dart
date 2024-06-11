//This file contains the handler for the /copilot_internal/v2/token route.
import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/codec_util.dart';

Future<void> getCopilotInternalV2Token(Context context) async {
  final trackingId = uuid.v4();
  final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1800;
  final sku = 'copilot_for_business_seat';
  final username = context['username'];
  final copilotToken = jsonMap2SignToken({
    'tid': trackingId,
    'exp': expiresAt,
    'sku': sku,
    'st': 'dotcom',
    'chat': 1,
    'u': '$username',
  });
  context.ok();
  context.json({
    'annotations_enabled': false,
    'chat_enabled': true,
    'chat_jetbrains_enabled': false,
    'code_quote_enabled': true,
    'codesearch': false,
    'copilot_ide_agent_chat_gpt4_small_prompt': false,
    'copilotignore_enabled': false,
    if (config.defaultBaseUrl != null)
      'endpoints': {
        'api': config.apiBaseUrl ?? config.defaultBaseUrl,
        'origin-tracker': config.originTrackerBaseUrl ?? config.defaultBaseUrl,
        'proxy': config.proxyBaseUrl ?? config.defaultBaseUrl,
        'telemetry': config.telemetryBaseUrl ?? config.defaultBaseUrl,
      },
    'expires_at': expiresAt,
    'individual': true,
    'nes_enabled': false,
    'prompt_8k': true,
    'public_suggestions': 'disabled',
    'refresh_in': 1500,
    'sku': sku,
    'snippy_load_test_enabled': false,
    'telemetry': 'disabled',
    'token': copilotToken,
    'tracking_id': trackingId,
    'intellij_editor_fetcher': false,
    'vsc_electron_fetcher': false,
    'vs_editor_fetcher': false,
    'vsc_panel_v2': false,
  });
}
