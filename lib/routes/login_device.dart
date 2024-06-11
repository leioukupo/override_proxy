//This file contains the handlers for the /login/device and /login/device/code routes.
import 'dart:io';

import 'package:copilot_proxy/check_auth/check_auth.dart';
import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/db_util.dart';

Future<void> postLoginDeviceCode(Context context) async {
  final clientId = context['client_id'];
  if (clientId == null || clientId.isEmpty) {
    context.statusCode = HttpStatus.badRequest;
    return;
  }
  final (userCode, deviceCode) = generateUserCode(clientId);
  final uri = context.request.requestedUri;
  final verificationUri = '${uri.origin}'
      '/login/device?'
      'user_code=$userCode';
  context.ok();
  context.json({
    'device_code': deviceCode,
    'expires_in': 1800,
    'interval': 5,
    'user_code': userCode,
    'verification_uri': verificationUri,
    'verification_uri_complete': verificationUri,
  });
}

Future<void> getLoginDevice(Context context) async {
  final userCode = context['user_code'];
  if (userCode == null || userCode.isEmpty || !checkUserCode(userCode)) {
    context.statusCode = HttpStatus.badRequest;
    return;
  }
  final username = context['username'];
  final password = context['password'];
  if (username == null ||
      username.isEmpty ||
      password == null ||
      password.isEmpty) {
    context.ok();
    context.response.headers.contentType = ContentType.html;
    context.write(_buildLoginPage(userCode));
    return;
  }
  if (!await _checkUsernamePassword(username, password)) {
    context.statusCode = HttpStatus.unauthorized;
    return;
  }
  allowDeviceCode(userCode, username);
  context.ok();
  context.response.headers.contentType = ContentType.html;
  context.write(_buildLoginSuccessPage(username));
}

Future<bool> _checkUsernamePassword(String username, String password) async {
  final userJson = await getUser(username);
  if (userJson == null || userJson['password'] != password) return false;
  return true;
}

String _buildLoginPage(String userCode) {
  return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
        }
        .login-container {
            background-color: white;
            padding: 2em;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            text-align: center;
            box-sizing: border-box;
            width: 300px; /* 添加固定宽度 */
        }
        input {
            width: 100%;
            padding: 1em;
            margin: 0.5em 0;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box; /* 确保填充和边框包含在宽度和高度中 */
        }
        button {
            width: 100%;
            padding: 1em;
            margin-top: 1em;
            border: none;
            border-radius: 5px;
            background-color: #007bff;
            color: white;
            font-size: 1em;
            cursor: pointer;
        }
        button:hover {
            background-color: #0056b3;
        }

        /* Dark mode styles */
        @media (prefers-color-scheme: dark) {
            body, html {
                background-color: #121212;
                color: white;
            }
            .login-container {
                background-color: #1e1e1e;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5);
            }
            input {
                background-color: #2e2e2e;
                border: 1px solid #444;
                color: white;
            }
            input::placeholder {
                color: #888;
            }
            button {
                background-color: #007bff;
                color: white;
            }
            button:hover {
                background-color: #0056b3;
            }
        }
    </style>
</head>
<body>
<div class="login-container">
    <h1>Login</h1>
    <form onsubmit="redirectToDeviceCode(event)">
        <input type="text" id="username" name="username" placeholder="Username" required>
        <input type="password" id="password" name="password" placeholder="Password" required>
        <button type="submit">Login</button>
    </form>
</div>
<script>
    function redirectToDeviceCode(event) {
        event.preventDefault();
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const userCode = '$userCode';

        const url = `/login/device?user_code=\${userCode}&username=\${encodeURIComponent(username)}&password=\${encodeURIComponent(password)}`;
        window.location.href = url;
    }
</script>
</body>
</html>
''';
}

String _buildLoginSuccessPage(String username) {
  return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
            color: #000;
        }
        .message {
            text-align: center;
        }
        @media (prefers-color-scheme: dark) {
            body, html {
                background-color: #121212;
                color: #fff;
            }
        }
    </style>
</head>
<body>
<div class="message">
    <h1>Hello $username, you can close this page now.</h1>
</div>
</body>
</html>
''';
}
