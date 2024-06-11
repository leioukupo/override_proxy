import 'dart:async';

class Lock {
  final int concurrency;

  int _useCount = 0;
  Completer<void> _lock = Completer<void>()..complete();

  Lock(this.concurrency);

  void lock() {
    _useCount++;
    _lock = Completer<void>();
  }

  void unlock() {
    _useCount--;
    _lock.complete();
  }

  Future<void> wait() => _lock.future;

  bool get isBusy => _useCount >= concurrency;
}
