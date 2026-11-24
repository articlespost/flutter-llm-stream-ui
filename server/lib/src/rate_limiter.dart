import 'dart:collection';

class RateLimiter {
  RateLimiter({
    required this.maxRequests,
    required this.window,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxRequests;
  final Duration window;
  final DateTime Function() _clock;
  final Queue<DateTime> _hits = Queue();

  bool tryAcquire() {
    final now = _clock();
    while (_hits.isNotEmpty && now.difference(_hits.first) >= window) {
      _hits.removeFirst();
    }
    if (_hits.length >= maxRequests) return false;
    _hits.add(now);
    return true;
  }
}
