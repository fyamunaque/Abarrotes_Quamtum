/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:abarrotes_server/src/generated/protocol.dart' as _i1p9jj0z;
import 'package:serverpod/serverpod.dart' as _is;
import '../staff/audit_action.dart' as _id696o20;
import '../users/user.dart' as _iqzoui01;

/// La bitácora de los cambios del personal: quién hizo qué, a quién y cuándo.
abstract class AuditLog
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AuditLog._({
    this.id,
    this.actorUserId,
    this.actor,
    required this.action,
    this.targetEmail,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLog({
    _is.UuidValue? id,
    _is.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    required _id696o20.AuditAction action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  }) = _AuditLogImpl;

  factory AuditLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditLog(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actorUserId: jsonSerialization['actorUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['actorUserId'],
            ),
      actor: jsonSerialization['actor'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['actor'],
            ),
      action: _id696o20.AuditAction.fromJson(
        (jsonSerialization['action'] as String),
      ),
      targetEmail: jsonSerialization['targetEmail'] as String?,
      details: jsonSerialization['details'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = AuditLogTable();

  static const db = AuditLogRepository._();

  @override
  _is.UuidValue? id;

  /// Quién lo hizo; null si fue el sistema.
  _is.UuidValue? actorUserId;

  _iqzoui01.User? actor;

  _id696o20.AuditAction action;

  /// El correo de la persona afectada (null en los cambios de un rol).
  String? targetEmail;

  /// Lo que cambió, como JSON (p. ej. {"from":"Almacenero","to":"Cajera"}).
  String? details;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuditLog copyWith({
    _is.UuidValue? id,
    _is.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    _id696o20.AuditAction? action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuditLog',
      if (id != null) 'id': id?.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId?.toJson(),
      if (actor != null) 'actor': actor?.toJson(),
      'action': action.toJson(),
      if (targetEmail != null) 'targetEmail': targetEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuditLog',
      if (id != null) 'id': id?.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId?.toJson(),
      if (actor != null) 'actor': actor?.toJsonForProtocol(),
      'action': action.toJson(),
      if (targetEmail != null) 'targetEmail': targetEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  static AuditLogInclude include({_iqzoui01.UserInclude? actor}) {
    return AuditLogInclude._(actor: actor);
  }

  static AuditLogIncludeList includeList({
    _is.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    AuditLogInclude? include,
  }) {
    return AuditLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditLogImpl extends AuditLog {
  _AuditLogImpl({
    _is.UuidValue? id,
    _is.UuidValue? actorUserId,
    _iqzoui01.User? actor,
    required _id696o20.AuditAction action,
    String? targetEmail,
    String? details,
    DateTime? createdAt,
  }) : super._(
         id: id,
         actorUserId: actorUserId,
         actor: actor,
         action: action,
         targetEmail: targetEmail,
         details: details,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AuditLog]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuditLog copyWith({
    Object? id = _Undefined,
    Object? actorUserId = _Undefined,
    Object? actor = _Undefined,
    _id696o20.AuditAction? action,
    Object? targetEmail = _Undefined,
    Object? details = _Undefined,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id is _is.UuidValue? ? id : this.id,
      actorUserId: actorUserId is _is.UuidValue?
          ? actorUserId
          : this.actorUserId,
      actor: actor is _iqzoui01.User? ? actor : this.actor?.copyWith(),
      action: action ?? this.action,
      targetEmail: targetEmail is String? ? targetEmail : this.targetEmail,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuditLogUpdateTable extends _is.UpdateTable<AuditLogTable> {
  AuditLogUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actorUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.actorUserId,
    value,
  );

  _is.ColumnValue<_id696o20.AuditAction, _id696o20.AuditAction> action(
    _id696o20.AuditAction value,
  ) => _is.ColumnValue(
    table.action,
    value,
  );

  _is.ColumnValue<String, String> targetEmail(String? value) => _is.ColumnValue(
    table.targetEmail,
    value,
  );

  _is.ColumnValue<String, String> details(String? value) => _is.ColumnValue(
    table.details,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AuditLogTable extends _is.Table<_is.UuidValue?> {
  AuditLogTable({super.tableRelation}) : super(tableName: 'audit_logs') {
    updateTable = AuditLogUpdateTable(this);
    actorUserId = _is.ColumnUuid(
      'actorUserId',
      this,
    );
    action = _is.ColumnEnum(
      'action',
      this,
      _is.EnumSerialization.byName,
    );
    targetEmail = _is.ColumnString(
      'targetEmail',
      this,
    );
    details = _is.ColumnString(
      'details',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final AuditLogUpdateTable updateTable;

  /// Quién lo hizo; null si fue el sistema.
  late final _is.ColumnUuid actorUserId;

  _iqzoui01.UserTable? _actor;

  late final _is.ColumnEnum<_id696o20.AuditAction> action;

  /// El correo de la persona afectada (null en los cambios de un rol).
  late final _is.ColumnString targetEmail;

  /// Lo que cambió, como JSON (p. ej. {"from":"Almacenero","to":"Cajera"}).
  late final _is.ColumnString details;

  late final _is.ColumnDateTime createdAt;

  _iqzoui01.UserTable get actor {
    if (_actor != null) return _actor!;
    _actor = _is.createRelationTable(
      relationFieldName: 'actor',
      field: AuditLog.t.actorUserId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _actor!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    actorUserId,
    action,
    targetEmail,
    details,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'actor') {
      return actor;
    }
    return null;
  }
}

class AuditLogInclude extends _is.IncludeObject {
  AuditLogInclude._({_iqzoui01.UserInclude? actor}) {
    _actor = actor;
  }

  _iqzoui01.UserInclude? _actor;

  @override
  Map<String, _is.Include?> get includes => {'actor': _actor};

  @override
  _is.Table<_is.UuidValue?> get table => AuditLog.t;
}

class AuditLogIncludeList extends _is.IncludeList {
  AuditLogIncludeList._({
    _is.WhereExpressionBuilder<AuditLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuditLog.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AuditLog.t;
}

class AuditLogRepository {
  const AuditLogRepository._();

  final attachRow = const AuditLogAttachRowRepository._();

  final detachRow = const AuditLogDetachRowRepository._();

  /// Returns a list of [AuditLog]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<AuditLog>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    _is.Transaction? transaction,
    AuditLogInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuditLog>(
      where: where?.call(AuditLog.t),
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuditLog] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<AuditLog?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuditLogTable>? where,
    int? offset,
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    _is.Transaction? transaction,
    AuditLogInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuditLog>(
      where: where?.call(AuditLog.t),
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuditLog] by its [id] or null if no such row exists.
  Future<AuditLog?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    AuditLogInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuditLog>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuditLog]s in the list and returns the inserted rows.
  ///
  /// The returned [AuditLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> insert(
    _is.DatabaseSession session,
    List<AuditLog> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AuditLog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AuditLog] and returns the inserted row.
  ///
  /// The returned [AuditLog] will have its `id` field set.
  Future<AuditLog> insertRow(
    _is.DatabaseSession session,
    AuditLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuditLog>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AuditLog]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [AuditLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> upsert(
    _is.DatabaseSession session,
    List<AuditLog> rows, {
    required _is.ColumnSelections<AuditLogTable> conflictColumns,
    _is.ColumnSelections<AuditLogTable>? updateColumns,
    _is.WhereExpressionBuilder<AuditLogTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AuditLog>(
      rows,
      conflictColumns: conflictColumns(AuditLog.t),
      updateColumns: updateColumns?.call(AuditLog.t),
      updateWhere: updateWhere?.call(AuditLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AuditLog] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [AuditLog] will have its `id` field set.
  Future<AuditLog?> upsertRow(
    _is.DatabaseSession session,
    AuditLog row, {
    required _is.ColumnSelections<AuditLogTable> conflictColumns,
    _is.ColumnSelections<AuditLogTable>? updateColumns,
    _is.WhereExpressionBuilder<AuditLogTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AuditLog>(
      row,
      conflictColumns: conflictColumns(AuditLog.t),
      updateColumns: updateColumns?.call(AuditLog.t),
      updateWhere: updateWhere?.call(AuditLog.t),
      transaction: transaction,
    );
  }

  /// Updates all [AuditLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> update(
    _is.DatabaseSession session,
    List<AuditLog> rows, {
    _is.ColumnSelections<AuditLogTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AuditLog>(
      rows,
      columns: columns?.call(AuditLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AuditLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuditLog> updateRow(
    _is.DatabaseSession session,
    AuditLog row, {
    _is.ColumnSelections<AuditLogTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuditLog>(
      row,
      columns: columns?.call(AuditLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuditLog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuditLog?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AuditLogUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AuditLog>(
      id,
      columnValues: columnValues(AuditLog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuditLog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AuditLogUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AuditLogTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AuditLog>(
      columnValues: columnValues(AuditLog.t.updateTable),
      where: where(AuditLog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AuditLog]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> delete(
    _is.DatabaseSession session,
    List<AuditLog> rows, {
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AuditLog>(
      rows,
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AuditLog].
  Future<AuditLog> deleteRow(
    _is.DatabaseSession session,
    AuditLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuditLog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuditLog>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuditLogTable> where,
    _is.OrderByBuilder<AuditLogTable>? orderBy,
    _is.OrderByListBuilder<AuditLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AuditLog>(
      where: where(AuditLog.t),
      orderBy: orderBy?.call(AuditLog.t),
      orderByList: orderByList?.call(AuditLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuditLogTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AuditLog>(
      where: where?.call(AuditLog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuditLog] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuditLogTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuditLog>(
      where: where(AuditLog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AuditLogAttachRowRepository {
  const AuditLogAttachRowRepository._();

  /// Creates a relation between the given [AuditLog] and [User]
  /// by setting the [AuditLog]'s foreign key `actorUserId` to refer to the [User].
  Future<void> actor(
    _is.DatabaseSession session,
    AuditLog auditLog,
    _iqzoui01.User actor, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.id == null) {
      throw ArgumentError.notNull('auditLog.id');
    }
    if (actor.id == null) {
      throw ArgumentError.notNull('actor.id');
    }

    var $auditLog = auditLog.copyWith(actorUserId: actor.id);
    await session.db.updateRow<AuditLog>(
      $auditLog,
      columns: [AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}

class AuditLogDetachRowRepository {
  const AuditLogDetachRowRepository._();

  /// Detaches the relation between this [AuditLog] and the [User] set in `actor`
  /// by setting the [AuditLog]'s foreign key `actorUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> actor(
    _is.DatabaseSession session,
    AuditLog auditLog, {
    _is.Transaction? transaction,
  }) async {
    if (auditLog.id == null) {
      throw ArgumentError.notNull('auditLog.id');
    }

    var $auditLog = auditLog.copyWith(actorUserId: null);
    await session.db.updateRow<AuditLog>(
      $auditLog,
      columns: [AuditLog.t.actorUserId],
      transaction: transaction,
    );
  }
}
