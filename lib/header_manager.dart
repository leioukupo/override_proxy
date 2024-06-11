import 'package:copilot_proxy/utils/utils.dart';

//用于收集指定设备的请求头
final _updateHeaderProviderUsernames = <String>{};

bool _isUpdateHeaderProvider(String username) {
  return _updateHeaderProviderUsernames.contains(username);
}

void clearUpdateHeaderProviderUsernames() {
  _updateHeaderProviderUsernames.clear();
}

final _allowedHeaders = {
  'accept',
  'accept-encoding',
  'annotations-enabled',
  'code-quote-enabled',
  'content-type',
  'copilot-integration-id',
  'openai-intent',
  'openai-organization',
  'editor-plugin-version',
  'editor-version',
  'user-agent',
  'vscode-machineid',
  'vscode-sessionid',
  'x-github-api-version',
};

class HeaderManager {
  HeaderManager._();

  static final instance = HeaderManager._();

  factory HeaderManager() => instance;

  final Map<String, HeaderMap> _headerBindings = {};

  void addHeaders(String username, String path, HeaderMap headers) {
    if (!(_isUpdateHeaderProvider(username) || _isFirstVscodeHeader(headers, username))) return;
    final copy = Map.of(headers);
    final HeaderMap map = {};
    for (final name in _allowedHeaders) {
      final values = copy.remove(name);
      if (values == null) continue;
      map[name] = values;
    }
    for (final name in blockedHeaders) {
      copy.remove(name);
    }
    if (copy.isNotEmpty) log('remaining headers: ${jsonPretty(copy)}');
    _headerBindings[path] = map;
  }

  HeaderMap getHeaders(String path) {
    return _headerBindings[path] ?? {};
  }

  void removeHeaders(String path) {
    _headerBindings.remove(path);
  }

  Future<void> saveHeaders() => saveJson('header.json', _headerBindings);

  Future<void> loadHeaders() async {
    final pathHeaderMap = await loadJson('header.json');
    if (pathHeaderMap == null || pathHeaderMap is! JsonMap) return;
    for (final entry in pathHeaderMap.entries) {
      HeaderMap headerMap = {};
      JsonMap value = entry.value;
      value.forEach((k, v) => headerMap[k] = v.cast<String>());
      _headerBindings[entry.key] = headerMap;
    }
  }

  bool _isFirstVscodeHeader(Map<String, List<String>> headers, String username) {
    if (_updateHeaderProviderUsernames.isNotEmpty) return false;
    final editorVersion = headers['editor-version']?.firstOrNull;
    if (editorVersion == null || !editorVersion.contains('vscode')) {
      return false;
    }
    _updateHeaderProviderUsernames.add(username);
    return true;
  }
}
