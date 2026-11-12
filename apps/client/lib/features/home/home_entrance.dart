import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Si la entrada de la portada ya se vio desde que se abrió la app: se ve
/// una sola vez por sesión (al volver a la portada, el titular ya está).
final homeEntranceProvider = NotifierProvider<HomeEntranceNotifier, bool>(
  HomeEntranceNotifier.new,
);

class HomeEntranceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// La entrada ya se vio.
  void seen() => state = true;
}
