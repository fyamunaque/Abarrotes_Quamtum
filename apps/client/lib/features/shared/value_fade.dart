import 'package:flutter/widgets.dart';

import '../../theme/motion.dart';

/// Cambia [child] por el nuevo con un fundido de [NeilsMotion.fade] cuando
/// cambia [value] (una cantidad, un total): el de antes sale y el nuevo entra
/// en el mismo lugar, sin rebote ni desplazamiento. Con "reducir
/// animaciones", cambia en el acto. El que sale no se lee en voz alta.
class ValueFade extends StatelessWidget {
  const ValueFade({
    super.key,
    required this.value,
    required this.child,
    this.alignment = AlignmentDirectional.center,
  });

  final Object value;
  final Widget child;

  /// Dónde se alinean el de antes y el nuevo mientras se cruzan.
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    final keyed = KeyedSubtree(key: ValueKey(value), child: child);
    if (NeilsMotion.reduced(context)) return keyed;
    return AnimatedSwitcher(
      duration: NeilsMotion.fade,
      switchInCurve: NeilsMotion.ease,
      switchOutCurve: NeilsMotion.ease,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [
          for (final child in previous) ExcludeSemantics(child: child),
          ?current,
        ],
      ),
      child: keyed,
    );
  }
}
