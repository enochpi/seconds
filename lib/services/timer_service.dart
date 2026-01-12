import 'dart:async';

class TimerService {
  Timer? _timer;
  Stopwatch? _stopwatch;

  void startStopwatch() {
    // Clean up any existing stopwatch first
    _stopwatch?.stop();
    _stopwatch?.reset();
    _stopwatch = Stopwatch();
    _stopwatch!.start();
  }

  void stopStopwatch() {
    _stopwatch?.stop();
  }

  int get elapsedMilliseconds => _stopwatch?.elapsedMilliseconds ?? 0;

  void startPeriodicTimer(Duration duration, void Function(Timer) callback) {
    // Cancel any existing timer first
    _timer?.cancel();
    _timer = Timer.periodic(duration, callback);
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch?.reset(); // ADDED: Reset the stopwatch
    _stopwatch = null;   // ADDED: Clear the reference
  }
}