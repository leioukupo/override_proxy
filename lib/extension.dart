import 'dart:io';

import 'package:args/args.dart';

extension ExList<T> on List<T> {
  T minBy(int Function(T) selector) {
    T? minItem;
    int? minValue;
    for (final item in this) {
      final value = selector(item);
      if (minValue == null || value.compareTo(minValue) < 0) {
        minItem = item;
        minValue = value;
      }
    }
    return minItem!;
  }
}

extension ExArgResults on ArgResults {
  String getString(String name, String envName, String defaultValue) {
    return this[name] as String? ?? Platform.environment[envName] ?? defaultValue;
  }
}
