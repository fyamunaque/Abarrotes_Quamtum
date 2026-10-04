import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/page_list.dart';
import '../../shared/error_message.dart';

/// Una columna de [AdminTable]: el título y cómo se dibuja cada celda.
class AdminColumn<T> {
  const AdminColumn(
    this.label,
    this.cell, {
    this.flex = 2,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T row) cell;

  /// Cuánto ancho toma, relativo a las demás.
  final int flex;

  /// Los números van alineados a la derecha.
  final bool numeric;
}

/// La tabla de las secciones del panel, página por página.
///
/// - Con [value] cargando, un indicador; con error, el mensaje y
///   "Reintentar" ([onRetry]); sin filas, [emptyText].
/// - Desde [wideFrom] de ancho disponible es una tabla. Por debajo, cada fila
///   es una tarjeta con "título: valor", con las mismas columnas: en un
///   teléfono no hay scroll horizontal.
/// - Tocar una fila llama a [onRowTap] (abrir el detalle o editar).
/// - Abajo, "1–20 de 54" y las flechas de página ([onPage]).
class AdminTable<T> extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.value,
    required this.rowKey,
    required this.rowLabel,
    required this.onRetry,
    required this.onPage,
    this.onRowTap,
    this.emptyText = 'No hay nada para mostrar.',
  });

  final List<AdminColumn<T>> columns;
  final AsyncValue<PageList<T>> value;

  /// Identifica cada fila (para que Flutter no las confunda al cambiar).
  final Object Function(T row) rowKey;

  /// Lo que lee un lector de pantalla al llegar a la fila.
  final String Function(T row) rowLabel;

  final VoidCallback onRetry;
  final ValueChanged<int> onPage;
  final ValueChanged<T>? onRowTap;
  final String emptyText;

  static const wideFrom = 720.0;

  @override
  Widget build(BuildContext context) {
    // Mientras pasa de página se sigue viendo la anterior.
    return switch (value) {
      AsyncValue(value: final page?) when page.items.isEmpty => _Message(
        emptyText,
      ),
      AsyncValue(value: final page?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= wideFrom
                ? _Table(this, page)
                : _Cards(this, page),
          ),
          _Pagination(page: page, onPage: onPage),
        ],
      ),
      AsyncError(:final error) => _Message(
        errorMessage(error, 'No se pudo cargar la tabla.'),
        action: FilledButton.tonal(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _row(BuildContext context, T row, Widget child) => MergeSemantics(
    key: ValueKey(rowKey(row)),
    child: Semantics(
      label: rowLabel(row),
      button: onRowTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onRowTap == null ? null : () => onRowTap!(row),
        child: child,
      ),
    ),
  );
}

class _Table<T> extends StatelessWidget {
  const _Table(this.table, this.page);

  final AdminTable<T> table;
  final PageList<T> page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cells(Widget Function(AdminColumn<T>) build) => Row(
      children: [
        for (final column in table.columns)
          Expanded(
            flex: column.flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: column.numeric
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: build(column),
              ),
            ),
          ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: cells(
                (column) => Text(
                  column.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          for (final row in page.items) ...[
            const Divider(),
            table._row(
              context,
              row,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium,
                  child: cells((column) => column.cell(row)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cards<T> extends StatelessWidget {
  const _Cards(this.table, this.page);

  final AdminTable<T> table;
  final PageList<T> page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: table._row(
                context,
                row,
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final column in table.columns)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 104,
                                child: Text(
                                  column.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DefaultTextStyle.merge(
                                  style: theme.textTheme.bodyMedium,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: column.cell(row),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _Pagination extends StatelessWidget {
  const _Pagination({required this.page, required this.onPage});

  final PageList<Object?> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final first = (page.page - 1) * page.pageSize + 1;
    final last = first + page.items.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$first–$last de ${page.total}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (page.pageCount > 1) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Página anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: page.hasPrevious ? () => onPage(page.page - 1) : null,
            ),
            IconButton(
              tooltip: 'Página siguiente',
              icon: const Icon(Icons.chevron_right),
              onPressed: page.hasNext ? () => onPage(page.page + 1) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
