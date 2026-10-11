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

/// Una acción propia de cada fila (p. ej. "Quitar"), aparte de tocar la fila.
/// Va fuera de la descripción de la fila: el lector de pantalla la anuncia
/// como un botón propio, con [semanticLabel] ("Quitar ana@gmail.com").
class AdminRowAction<T> {
  const AdminRowAction({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.destructive = false,
    this.showFor,
  });

  final String label;
  final IconData icon;
  final String Function(T row) semanticLabel;
  final ValueChanged<T> onPressed;

  /// Quita o borra algo: va en el color de error (y debería pedir
  /// confirmación).
  final bool destructive;

  /// Las filas que la tienen (p. ej. "Desactivar", solo las activas). Sin
  /// esto, todas.
  final bool Function(T row)? showFor;

  bool _shows(T row) => showFor?.call(row) ?? true;
}

/// Cómo alinear una celda de varias líneas (un precio con el anterior tachado,
/// el stock con su mínimo): a la derecha en las columnas numéricas de la
/// tabla, a la izquierda en las tarjetas del teléfono.
class AdminCellAlignment extends InheritedWidget {
  const AdminCellAlignment({
    super.key,
    required this.alignment,
    required super.child,
  });

  final CrossAxisAlignment alignment;

  static CrossAxisAlignment of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdminCellAlignment>()
          ?.alignment ??
      CrossAxisAlignment.start;

  @override
  bool updateShouldNotify(AdminCellAlignment oldWidget) =>
      alignment != oldWidget.alignment;
}

/// La tabla de las secciones del panel, página por página.
///
/// - Con [value] cargando, un indicador; con error, el mensaje y
///   "Reintentar" ([onRetry]); sin filas, [emptyText].
/// - Desde [wideFrom] de ancho disponible es una tabla. Por debajo, cada fila
///   es una tarjeta con "título: valor", con las mismas columnas: en un
///   teléfono no hay scroll horizontal.
/// - Tocar una fila llama a [onRowTap] (abrir el detalle o editar).
/// - Con [rowActions], cada fila tiene además esos botones: al final de la
///   fila en la tabla y abajo a la derecha en las tarjetas.
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
    this.rowActions = const [],
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
  final List<AdminRowAction<T>> rowActions;
  final String emptyText;

  static const wideFrom = 720.0;

  /// El ancho de cada botón de [rowActions] en la tabla.
  static const _actionWidth = 136.0;

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

  Widget _actionButton(BuildContext context, AdminRowAction<T> action, T row) {
    final theme = Theme.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: action.destructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: () => action.onPressed(row),
      icon: Icon(action.icon, size: 18),
      label: Text(action.label, semanticsLabel: action.semanticLabel(row)),
    );
  }
}

class _Table<T> extends StatelessWidget {
  const _Table(this.table, this.page);

  final AdminTable<T> table;
  final PageList<T> page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = table.rowActions;
    // Con rowActions, una columna más al final, de ancho fijo y sin título.
    // Una acción que la fila no tiene deja su lugar vacío: las demás quedan
    // alineadas.
    Widget withActions(Widget content, T? row) => actions.isEmpty
        ? content
        : Row(
            children: [
              Expanded(child: content),
              for (final action in actions)
                SizedBox(
                  width: AdminTable._actionWidth,
                  child: row != null && action._shows(row)
                      ? Center(child: table._actionButton(context, action, row))
                      : null,
                ),
            ],
          );
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
              child: withActions(
                cells(
                  (column) => Text(
                    column.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                null,
              ),
            ),
          ),
          for (final row in page.items) ...[
            const Divider(),
            KeyedSubtree(
              key: ValueKey(table.rowKey(row)),
              child: withActions(
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
                      child: cells(
                        (column) => column.numeric
                            ? AdminCellAlignment(
                                alignment: CrossAxisAlignment.end,
                                child: column.cell(row),
                              )
                            : column.cell(row),
                      ),
                    ),
                  ),
                ),
                row,
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
    Widget content(T row) => Padding(
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.items)
          Padding(
            key: ValueKey(table.rowKey(row)),
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: switch ([
                for (final action in table.rowActions)
                  if (action._shows(row)) action,
              ]) {
                [] => table._row(context, row, content(row)),
                // Las acciones abajo a la derecha, fuera de la fila.
                final actions => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    table._row(context, row, content(row)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        children: [
                          for (final action in actions)
                            table._actionButton(context, action, row),
                        ],
                      ),
                    ),
                  ],
                ),
              },
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
