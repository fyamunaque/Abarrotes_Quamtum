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
import '../users/user.dart' as _iqzoui01;

/// Un cliente VIP: un correo (en minúsculas y sin espacios) que accede a las
/// promociones con audiencia `vip`, si además verificó ese correo en Firebase.
/// Se da de baja con `active`, sin borrar la fila: queda el historial.
abstract class VipCustomer
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VipCustomer._({
    this.id,
    required this.email,
    bool? active,
    DateTime? createdAt,
    required this.addedByUserId,
    this.addedBy,
  }) : active = active ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory VipCustomer({
    _is.UuidValue? id,
    required String email,
    bool? active,
    DateTime? createdAt,
    required _is.UuidValue addedByUserId,
    _iqzoui01.User? addedBy,
  }) = _VipCustomerImpl;

  factory VipCustomer.fromJson(Map<String, dynamic> jsonSerialization) {
    return VipCustomer(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      email: jsonSerialization['email'] as String,
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      addedByUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['addedByUserId'],
      ),
      addedBy: jsonSerialization['addedBy'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['addedBy'],
            ),
    );
  }

  static final t = VipCustomerTable();

  static const db = VipCustomerRepository._();

  @override
  _is.UuidValue? id;

  String email;

  bool active;

  DateTime createdAt;

  /// Quién lo agregó (un admin).
  _is.UuidValue addedByUserId;

  _iqzoui01.User? addedBy;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VipCustomer]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VipCustomer copyWith({
    _is.UuidValue? id,
    String? email,
    bool? active,
    DateTime? createdAt,
    _is.UuidValue? addedByUserId,
    _iqzoui01.User? addedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VipCustomer',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'active': active,
      'createdAt': createdAt.toJson(),
      'addedByUserId': addedByUserId.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VipCustomer',
      if (id != null) 'id': id?.toJson(),
      'email': email,
      'active': active,
      'createdAt': createdAt.toJson(),
      'addedByUserId': addedByUserId.toJson(),
      if (addedBy != null) 'addedBy': addedBy?.toJsonForProtocol(),
    };
  }

  static VipCustomerInclude include({_iqzoui01.UserInclude? addedBy}) {
    return VipCustomerInclude._(addedBy: addedBy);
  }

  static VipCustomerIncludeList includeList({
    _is.WhereExpressionBuilder<VipCustomerTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    VipCustomerInclude? include,
  }) {
    return VipCustomerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VipCustomerImpl extends VipCustomer {
  _VipCustomerImpl({
    _is.UuidValue? id,
    required String email,
    bool? active,
    DateTime? createdAt,
    required _is.UuidValue addedByUserId,
    _iqzoui01.User? addedBy,
  }) : super._(
         id: id,
         email: email,
         active: active,
         createdAt: createdAt,
         addedByUserId: addedByUserId,
         addedBy: addedBy,
       );

  /// Returns a shallow copy of this [VipCustomer]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VipCustomer copyWith({
    Object? id = _Undefined,
    String? email,
    bool? active,
    DateTime? createdAt,
    _is.UuidValue? addedByUserId,
    Object? addedBy = _Undefined,
  }) {
    return VipCustomer(
      id: id is _is.UuidValue? ? id : this.id,
      email: email ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedBy: addedBy is _iqzoui01.User? ? addedBy : this.addedBy?.copyWith(),
    );
  }
}

class VipCustomerUpdateTable extends _is.UpdateTable<VipCustomerTable> {
  VipCustomerUpdateTable(super.table);

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );

  _is.ColumnValue<bool, bool> active(bool value) => _is.ColumnValue(
    table.active,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> addedByUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.addedByUserId,
    value,
  );
}

class VipCustomerTable extends _is.Table<_is.UuidValue?> {
  VipCustomerTable({super.tableRelation}) : super(tableName: 'vip_customers') {
    updateTable = VipCustomerUpdateTable(this);
    email = _is.ColumnString(
      'email',
      this,
    );
    active = _is.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    addedByUserId = _is.ColumnUuid(
      'addedByUserId',
      this,
    );
  }

  late final VipCustomerUpdateTable updateTable;

  late final _is.ColumnString email;

  late final _is.ColumnBool active;

  late final _is.ColumnDateTime createdAt;

  /// Quién lo agregó (un admin).
  late final _is.ColumnUuid addedByUserId;

  _iqzoui01.UserTable? _addedBy;

  _iqzoui01.UserTable get addedBy {
    if (_addedBy != null) return _addedBy!;
    _addedBy = _is.createRelationTable(
      relationFieldName: 'addedBy',
      field: VipCustomer.t.addedByUserId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _addedBy!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    email,
    active,
    createdAt,
    addedByUserId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'addedBy') {
      return addedBy;
    }
    return null;
  }
}

class VipCustomerInclude extends _is.IncludeObject {
  VipCustomerInclude._({_iqzoui01.UserInclude? addedBy}) {
    _addedBy = addedBy;
  }

  _iqzoui01.UserInclude? _addedBy;

  @override
  Map<String, _is.Include?> get includes => {'addedBy': _addedBy};

  @override
  _is.Table<_is.UuidValue?> get table => VipCustomer.t;
}

class VipCustomerIncludeList extends _is.IncludeList {
  VipCustomerIncludeList._({
    _is.WhereExpressionBuilder<VipCustomerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VipCustomer.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VipCustomer.t;
}

class VipCustomerRepository {
  const VipCustomerRepository._();

  final attachRow = const VipCustomerAttachRowRepository._();

  /// Returns a list of [VipCustomer]s matching the given query parameters.
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
  Future<List<VipCustomer>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VipCustomerTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    _is.Transaction? transaction,
    VipCustomerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VipCustomer>(
      where: where?.call(VipCustomer.t),
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [VipCustomer] matching the given query parameters.
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
  Future<VipCustomer?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VipCustomerTable>? where,
    int? offset,
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    _is.Transaction? transaction,
    VipCustomerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VipCustomer>(
      where: where?.call(VipCustomer.t),
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VipCustomer] by its [id] or null if no such row exists.
  Future<VipCustomer?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    VipCustomerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VipCustomer>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VipCustomer]s in the list and returns the inserted rows.
  ///
  /// The returned [VipCustomer]s will have their `id` fields set.
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
  Future<List<VipCustomer>> insert(
    _is.DatabaseSession session,
    List<VipCustomer> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VipCustomer>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VipCustomer] and returns the inserted row.
  ///
  /// The returned [VipCustomer] will have its `id` field set.
  Future<VipCustomer> insertRow(
    _is.DatabaseSession session,
    VipCustomer row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VipCustomer>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VipCustomer]s in the list and returns the resulting rows.
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
  /// The returned [VipCustomer]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VipCustomer>> upsert(
    _is.DatabaseSession session,
    List<VipCustomer> rows, {
    required _is.ColumnSelections<VipCustomerTable> conflictColumns,
    _is.ColumnSelections<VipCustomerTable>? updateColumns,
    _is.WhereExpressionBuilder<VipCustomerTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VipCustomer>(
      rows,
      conflictColumns: conflictColumns(VipCustomer.t),
      updateColumns: updateColumns?.call(VipCustomer.t),
      updateWhere: updateWhere?.call(VipCustomer.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VipCustomer] and returns the resulting row.
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
  /// The returned [VipCustomer] will have its `id` field set.
  Future<VipCustomer?> upsertRow(
    _is.DatabaseSession session,
    VipCustomer row, {
    required _is.ColumnSelections<VipCustomerTable> conflictColumns,
    _is.ColumnSelections<VipCustomerTable>? updateColumns,
    _is.WhereExpressionBuilder<VipCustomerTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VipCustomer>(
      row,
      conflictColumns: conflictColumns(VipCustomer.t),
      updateColumns: updateColumns?.call(VipCustomer.t),
      updateWhere: updateWhere?.call(VipCustomer.t),
      transaction: transaction,
    );
  }

  /// Updates all [VipCustomer]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VipCustomer>> update(
    _is.DatabaseSession session,
    List<VipCustomer> rows, {
    _is.ColumnSelections<VipCustomerTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VipCustomer>(
      rows,
      columns: columns?.call(VipCustomer.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VipCustomer]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VipCustomer> updateRow(
    _is.DatabaseSession session,
    VipCustomer row, {
    _is.ColumnSelections<VipCustomerTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VipCustomer>(
      row,
      columns: columns?.call(VipCustomer.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VipCustomer] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VipCustomer?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VipCustomerUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VipCustomer>(
      id,
      columnValues: columnValues(VipCustomer.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VipCustomer]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VipCustomer>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VipCustomerUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<VipCustomerTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VipCustomer>(
      columnValues: columnValues(VipCustomer.t.updateTable),
      where: where(VipCustomer.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VipCustomer]s in the list and returns the deleted rows.
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
  Future<List<VipCustomer>> delete(
    _is.DatabaseSession session,
    List<VipCustomer> rows, {
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VipCustomer>(
      rows,
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VipCustomer].
  Future<VipCustomer> deleteRow(
    _is.DatabaseSession session,
    VipCustomer row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VipCustomer>(
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
  Future<List<VipCustomer>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VipCustomerTable> where,
    _is.OrderByBuilder<VipCustomerTable>? orderBy,
    _is.OrderByListBuilder<VipCustomerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VipCustomer>(
      where: where(VipCustomer.t),
      orderBy: orderBy?.call(VipCustomer.t),
      orderByList: orderByList?.call(VipCustomer.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VipCustomerTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VipCustomer>(
      where: where?.call(VipCustomer.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VipCustomer] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VipCustomerTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VipCustomer>(
      where: where(VipCustomer.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class VipCustomerAttachRowRepository {
  const VipCustomerAttachRowRepository._();

  /// Creates a relation between the given [VipCustomer] and [User]
  /// by setting the [VipCustomer]'s foreign key `addedByUserId` to refer to the [User].
  Future<void> addedBy(
    _is.DatabaseSession session,
    VipCustomer vipCustomer,
    _iqzoui01.User addedBy, {
    _is.Transaction? transaction,
  }) async {
    if (vipCustomer.id == null) {
      throw ArgumentError.notNull('vipCustomer.id');
    }
    if (addedBy.id == null) {
      throw ArgumentError.notNull('addedBy.id');
    }

    var $vipCustomer = vipCustomer.copyWith(addedByUserId: addedBy.id);
    await session.db.updateRow<VipCustomer>(
      $vipCustomer,
      columns: [VipCustomer.t.addedByUserId],
      transaction: transaction,
    );
  }
}
