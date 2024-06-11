//This file contains the Config class and related methods.
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/json_util.dart';

class Config {
  final String listenIp;
  final int listenPort;
  final List<TokenData> targetList;
  final String local;
  final String tokenSalt;
  final String adminPassword;
  final int copilotDebounce;
  final String? defaultBaseUrl;
  final String? apiBaseUrl;
  final String? originTrackerBaseUrl;
  final String? proxyBaseUrl;
  final String? telemetryBaseUrl;
  String? configFilePath;

  Config({
    required this.listenIp,
    required this.listenPort,
    required this.targetList,
    required this.local,
    required this.tokenSalt,
    required this.adminPassword,
    required this.copilotDebounce,
    required this.defaultBaseUrl,
    this.apiBaseUrl,
    this.originTrackerBaseUrl,
    this.proxyBaseUrl,
    this.telemetryBaseUrl,
  });

  factory Config.fromJson(JsonMap configMap) {
    final JsonList targetList = configMap['targetList'] ?? [];
    return Config(
      listenIp: configMap['listenIp'] ?? '0.0.0.0',
      listenPort: configMap['listenPort'] ?? 8080,
      targetList: targetList.map((e) => newTokenDataFromJson(e)).toList(),
      local: configMap['local'] ?? 'zh_CN',
      tokenSalt: configMap['tokenSalt'] ?? 'default_salt',
      adminPassword: configMap['adminPassword'] ?? 'default_admin_password',
      copilotDebounce: configMap['copilotDebounce'] ?? 1000,
      defaultBaseUrl: configMap['defaultBaseUrl'],
      apiBaseUrl: configMap['apiBaseUrl'],
      originTrackerBaseUrl: configMap['originTrackerBaseUrl'],
      proxyBaseUrl: configMap['proxyBaseUrl'],
      telemetryBaseUrl: configMap['telemetryBaseUrl'],
    );
  }
}