import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Una fila de tarjetas de [cardWidth] con su [title] arriba, que se desliza
/// de costado (en la web también con el mouse: arrastrar o la barra). Todas
/// miden lo mismo de alto: el de la más alta.
class CardStrip extends StatefulWidget {
  const CardStrip({
    super.key,
    required this.title,
    required this.children,
    this.cardWidth = 200,
  });

  final String title;
  final List<Widget> children;
  final double cardWidth;

  @override
  State<CardStrip> createState() => _CardStripState();
}

class _CardStripState extends State<CardStrip> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context)
              .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
          child: Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, child) in widget.children.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(width: widget.cardWidth, child: child),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
