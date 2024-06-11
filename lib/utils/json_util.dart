import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/common.dart';
import 'package:path/path.dart' as path;

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

final _jsonEncoder = JsonEncoder.withIndent('\t');

String jsonPretty(Object? object) => _jsonEncoder.convert(object);

final _parentDirPath = path.dirname(config.configFilePath!);

Future<void> saveJson(String fileName, dynamic data) async {
  final jsonFilePath = path.join(_parentDirPath, fileName);
  final jsonFile = File(jsonFilePath);
  await jsonFile.writeAsString(jsonPretty(data));
}

Future<dynamic> loadJson(String fileName) async {
  final jsonFilePath = path.join(_parentDirPath, fileName);
  final jsonFile = File(jsonFilePath);
  if (!jsonFile.existsSync()) return null;
  final source = await jsonFile.readAsString();
  if (source.isEmpty) return;
  return jsonDecode(source);
}

Future<void> deleteJson(String fileName) async {
  final jsonFilePath = path.join(_parentDirPath, fileName);
  final jsonFile = File(jsonFilePath);
  if (!jsonFile.existsSync()) return;
  await jsonFile.delete();
}
