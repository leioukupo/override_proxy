import 'dart:io';

final _logFile = File('copilot_proxy.log');

bool noLog = false;

void log(Object? object, [bool printToConsole = true, int length = 100]) {
  if (!noLog) _logFile.writeAsStringSync('$object\n', mode: FileMode.append);
  final str = object.toString();
  if (printToConsole) stdout.writeln(str.length <= length ? str : str.substring(0, length));
}

void _error(Object? object, [bool printToConsole = true, int length = 100]) {
  if (!noLog) _logFile.writeAsStringSync('$object\n', mode: FileMode.append);
  final str = object.toString();
  if (printToConsole) stderr.writeln(str.length <= length ? str : str.substring(0, length));
}

void logError(Object? object, [StackTrace? s, String? title, bool printToConsole = true]) {
  if (title != null) _error('[$title]', printToConsole);
  _error('error: $object', printToConsole);
  if (s != null) {
    _error('stackTrace: $s', printToConsole);
  } else if (object is Error) {
    _error('stackTrace: ${object.stackTrace}', printToConsole);
  }
}
