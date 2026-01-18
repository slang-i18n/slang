extension StopwatchExt on Stopwatch {
  String get elapsedSeconds {
    return '(${elapsed.inMilliseconds / 1000} seconds)';
  }
}
