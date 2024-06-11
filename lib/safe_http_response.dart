import 'dart:io';

class SafeHttpResponse {
  final HttpResponse source;

  bool _hasStatusCode = false;

  SafeHttpResponse(this.source);

  int get statusCode => source.statusCode;

  set statusCode(int code) {
    if (_hasStatusCode) return;
    source.statusCode = code;
  }

  HttpHeaders get headers => source.headers;

  void write(Object? object) {
    _hasStatusCode = true;
    source.write(object);
  }

  void writeln([Object? object = ""]) {
    _hasStatusCode = true;
    source.writeln(object);
  }

  Future close() {
    _hasStatusCode = true;
    return source.close();
  }

  Future addStream(Stream<List<int>> stream) {
    _hasStatusCode = true;
    return source.addStream(stream);
  }
}
