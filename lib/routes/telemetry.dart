//This file contains the handler for the /telemetry route.
import 'dart:convert';

import 'package:copilot_proxy/context.dart';
import 'package:copilot_proxy/utils/json_util.dart';

Future<void> postTelemetry(Context context) async {
  final contentType = context['content-type'];
  if (!_jsonContentTypes.contains(contentType)) return context.noContent();
  late final JsonList list;
  final stream = utf8.decoder.bind(context.request);
  if (contentType == 'application/x-json-stream') {
    list = await stream.toList();
  } else if (contentType == 'application/json') {
    list = jsonDecode(await stream.join());
  }
  final size = list.length;
  context.json({
    "itemsReceived": size,
    "itemsAccepted": size,
    "appId": null,
    "errors": [],
  });
}

final _jsonContentTypes = {
  'application/json',
  'application/x-json-stream',
};
