import 'package:copilot_proxy/check_auth/access_token_check_auth.dart';
import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/tokens/tokens.dart';
import 'package:copilot_proxy/utils/json_util.dart';
import 'package:path/path.dart' as path;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

const _databaseVersion = 2;
final _parentDirPath = path.dirname(config.configFilePath!);
late Database _db;
late final StoreRef<String, JsonMap> users;
late final StoreRef<String, JsonMap> tokens;

Future<void> loadDB() async {
  final dbPath = path.join(_parentDirPath, 'data.db');
  users = stringMapStoreFactory.store('users');
  tokens = stringMapStoreFactory.store('tokens');
  _db = await databaseFactoryIo.openDatabase(
    dbPath,
    version: _databaseVersion,
    onVersionChanged: (db, oldVersion, newVersion) async {
      _db = db;
      if (oldVersion == 0) await initDB();
      if (oldVersion == 1) await mergeTokenData();
    },
  );
}

Future<void> initDB() async {
  JsonMap? upJsonMap = await loadJson('username_password.json');
  JsonMap? oldUserJsonMap = await loadJson('user.json');
  //init admin user
  final adminUsername = 'admin';
  final adminRecord = users.record(adminUsername);
  if (!await adminRecord.exists(_db)) {
    await addUser(adminUsername, config.adminPassword);
  }
  if (oldUserJsonMap != null) {
    //merge old user data
    for (final JsonMap userJson in oldUserJsonMap.values) {
      final String username = userJson['login'];
      final String? password = upJsonMap?.remove(username);
      if (password != null) userJson['password'] = password;
      await users.record(username).add(_db, userJson);
    }
  }
  //new user data
  for (final e in (upJsonMap?.entries ?? <MapEntry<String, String>>[])) {
    await addUser(e.key, e.value);
  }
  await deleteJson('user.json');
  await deleteJson('username_password.json');
  await deleteJson('access_token.json');
  await deleteJson('client_ip.json');
}

Future<void> mergeTokenData() async {
  final JsonList? oldTokenDataList = await loadJson('token.json');
  if (oldTokenDataList == null) return;
  for (final JsonMap tokenJson in oldTokenDataList) {
    await saveTokenData(TokenData.fromGHU(tokenJson['githubToken']));
  }
  await deleteJson('token.json');
}

Future<void> saveDB() => _db.close();

Future<JsonMap?> addUser(
  String username,
  String password,
) async {
  final userJson = generateFakeUser(username: username, password: password);
  await users.record(username).add(_db, userJson);
  return userJson;
}

Future<void> saveUser(String username, JsonMap update) => users.record(username).update(_db, update);

Future<JsonMap?> getUser(String? username) async {
  if (username == null) return null;
  return await users.record(username).get(_db);
}

Future<void> saveTokenData(TokenData tokenData) async {
  await tokens.record(tokenData.hash).put(_db, tokenData.toJson());
}

Future<List<JsonMap>> getAllTokenData() async {
  final list = await tokens.find(_db);
  return list.map((e) => e.value).toList();
}

Future<void> removeTokenData(TokenData token) => tokens.record(token.hash).delete(_db);
