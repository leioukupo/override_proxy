import 'dart:async';
import 'dart:convert';

import 'package:copilot_proxy/common.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/middleware/middleware.dart';
import 'package:copilot_proxy/utils/utils.dart';

Future<void> accessTokenCheckAuth(
  String? accessToken,
  Context context,
  Next next,
) async {
  final data = signToken2JsonMap(accessToken);
  if (data == null) return;
  final username = data['u'];
  if (username == null) return;
  _accessTokens.add(accessToken!);
  context['username'] = username;
  context.auth = true;
  await next();
}

final Set<String> _accessTokens = {};

void addAccessToken(String accessToken, String username)  => _accessTokens.add(accessToken);

JsonMap generateFakeUser({
  String? username,
  String? password,
  String? accessToken,
}) {
  final now = DateTime.now();
  final createdAt = now.subtract(Duration(days: random.nextInt(3650) + 365));
  final updatedAt = createdAt.add(Duration(days: random.nextInt(3650)));

  return {
    'login': username ?? 'fakeuser${random.nextInt(10000)}',
    if (password != null) 'password': password,
    'id': random.nextInt(10000),
    'node_id': 'MDQ6VXNlcj${base64Encode(random.nextInt(10000).toString().codeUnits)}',
    'avatar_url': 'https://avatars.githubusercontent.com/u/${random.nextInt(10000)}?v=4',
    'gravatar_id': '',
    'url': 'https://api.github.com/users/fakeuser',
    'html_url': 'https://github.com/fakeuser',
    'followers_url': 'https://api.github.com/users/fakeuser/followers',
    'following_url': 'https://api.github.com/users/fakeuser/following{/other_user}',
    'gists_url': 'https://api.github.com/users/fakeuser/gists{/gist_id}',
    'starred_url': 'https://api.github.com/users/fakeuser/starred{/owner}{/repo}',
    'subscriptions_url': 'https://api.github.com/users/fakeuser/subscriptions',
    'organizations_url': 'https://api.github.com/users/fakeuser/orgs',
    'repos_url': 'https://api.github.com/users/fakeuser/repos',
    'events_url': 'https://api.github.com/users/fakeuser/events{/privacy}',
    'received_events_url': 'https://api.github.com/users/fakeuser/received_events',
    'type': 'User',
    'site_admin': false,
    'name': 'Fake User ${random.nextInt(1000)}',
    'company': 'FakeCompany',
    'blog': 'https://fakeblog.com',
    'location': 'FakeCity',
    'email': 'fakeuser${random.nextInt(1000)}@fakeemail.com',
    'hireable': random.nextBool(),
    'bio': 'This is a fake bio',
    'twitter_username': 'fakeuser${random.nextInt(1000)}',
    'public_repos': random.nextInt(100),
    'public_gists': random.nextInt(100),
    'followers': random.nextInt(1000),
    'following': random.nextInt(1000),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (accessToken != null) 'access_token': accessToken,
  };
}
