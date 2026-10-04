import '../../auth/auth_repository.dart';
import '../../common/api_client.dart';

/// El mensaje para la persona de un error de los repositorios: los del
/// servidor ([ApiFailure]) y los de la sesión ([AuthFailure]) ya vienen en
/// español. Para cualquier otro, [fallback].
String errorMessage(Object error, String fallback) => switch (error) {
  ApiFailure(:final message) || AuthFailure(:final message) => message,
  _ => fallback,
};
