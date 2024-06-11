import 'dart:convert';
import 'dart:io';

import 'package:copilot_proxy/utils/log_util.dart';

typedef HeaderMap = Map<String, List<String>>;

final blockedHeaders = {
  'accept-language',
  'authorization',
  'cdn-loop',
  'cf-connecting-ip',
  'cf-ipcountry',
  'cf-ray',
  'cf-visitor',
  'content-length',
  'host',
  'priority',
  'sec-ch-ua',
  'sec-ch-ua-mobile',
  'sec-ch-ua-platform',
  'sec-fetch-dest',
  'sec-fetch-mode',
  'sec-fetch-site',
  'sec-fetch-user',
  'upgrade-insecure-requests',
  'x-forwarded-for',
  'x-forwarded-host',
  'x-forwarded-proto',
  'x-request-id',
};

extension ExHttpHeaders on HttpHeaders {
  HeaderMap toFullMap() {
    final HeaderMap headers = {};
    forEach((name, values) {
      headers[name] = values;
    });
    return headers;
  }

  Future<void> print() async {
    log('Headers:');
    forEach((name, values) {
      log('$name: ${values.join(", ")}');
    });
  }
}

extension ExHeaderMap on HeaderMap {
  HeaderMap toSimpleMap() {
    final HeaderMap headers = {};
    forEach((name, values) {
      headers[name] = values;
    });
    blockedHeaders.forEach(headers.remove);
    return headers;
  }
}

extension ExHttpResponse on HttpClientResponse {
  Future<void> print([bool printBody = false]) async {
    log('Status Code: $statusCode');
    log('Reason Phrase: $reasonPhrase');
    await headers.print();
    if (!printBody) return;
    log('Response Body:');
    log(await getBody());
  }

  Future<String> getBody() => utf8.decoder.bind(this).join();
}

extension ExHttpRequest on HttpClientRequest {
  void setHeaders(HeaderMap headerMap) {
    headerMap.forEach((name, values) {
      headers.set(name, values);
    });
  }

  Future<void> print() async {
    log('Method: $method');
    log('Uri: $uri');
    await headers.print();
  }

  void send(String source) => add(utf8.encode(source));
}
