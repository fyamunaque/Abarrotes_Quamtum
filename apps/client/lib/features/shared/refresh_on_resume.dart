import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session_provider.dart';

/// Cuando la app vuelve a primer plano (en Android, al volver a ella; en la
/// web, al volver a la pestaña), vuelve a pedir el perfil: así un correo que
/// un admin hizo VIP, o que la persona acaba de confirmar, se ve sin cerrar
/// la sesión. Envuelve toda la app (`MaterialApp.router(builder:)`).
class RefreshOnResume extends ConsumerStatefulWidget {
  const RefreshOnResume({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends ConsumerState<RefreshOnResume> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(sessionProvider.notifier).refreshProfile(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
