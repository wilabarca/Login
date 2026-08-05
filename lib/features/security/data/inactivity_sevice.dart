import 'dart:async';

class InactivityService {
  static const Duration _timeout = Duration(
    seconds: 20,
  ); // aqui se pone el tiempo de salida del login
  Timer? _timer;
  final void Function() onTimeout;

  InactivityService({required this.onTimeout});

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, onTimeout);
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}
