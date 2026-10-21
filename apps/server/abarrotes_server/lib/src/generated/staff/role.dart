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
import '../staff/permission.dart' as _ikdgfgc9;
import '../staff/staff_member.dart' as _i3fhtrko;

/// Un rol del personal: un nombre y sus permisos. El de sistema
/// (Administrador) tiene siempre todos y no se edita ni se borra; los demás
/// los arma un admin (p. ej. las plantillas Almacenero y Cajera).
abstract class Role
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Role._({
    this.id,
    required this.name,
    required this.permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    this.members,
  }) : isSystem = isSystem ?? false,
       active = active ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory Role({
    _is.UuidValue? id,
    required String name,
    required List<_ikdgfgc9.Permission> permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  }) = _RoleImpl;

  factory Role.fromJson(Map<String, dynamic> jsonSerialization) {
    return Role(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      permissions: _i1p9jj0z.Protocol().deserialize<List<_ikdgfgc9.Permission>>(
        jsonSerialization['permissions'],
      ),
      isSystem: jsonSerialization['isSystem'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isSystem']),
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      members: jsonSerialization['members'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_i3fhtrko.StaffMember>>(
              jsonSerialization['members'],
            ),
    );
  }

  static final t = RoleTable();

  static const db = RoleRepository._();

  @override
  _is.UuidValue? id;

  String name;

  List<_ikdgfgc9.Permission> permissions;

  bool isSystem;

  /// Un rol inactivo no da permisos ni se puede asignar.
  bool active;

  DateTime createdAt;

  List<_i3fhtrko.StaffMember>? members;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Role]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Role copyWith({
    _is.UuidValue? id,
    String? name,
    List<_ikdgfgc9.Permission>? permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Role',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'permissions': permissions.toJson(valueToJson: (v) => v.toJson()),
      'isSystem': isSystem,
      'active': active,
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Role',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'permissions': permissions.toJson(valueToJson: (v) => v.toJson()),
      'isSystem': isSystem,
      'active': active,
      'createdAt': createdAt.toJson(),
      if (members != null)
        'members': members?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static RoleInclude include({_i3fhtrko.StaffMemberIncludeList? members}) {
    return RoleInclude._(members: members);
  }

  static RoleIncludeList includeList({
    _is.WhereExpressionBuilder<RoleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    RoleInclude? include,
  }) {
    return RoleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoleImpl extends Role {
  _RoleImpl({
    _is.UuidValue? id,
    required String name,
    required List<_ikdgfgc9.Permission> permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    List<_i3fhtrko.StaffMember>? members,
  }) : super._(
         id: id,
         name: name,
         permissions: permissions,
         isSystem: isSystem,
         active: active,
         createdAt: createdAt,
         members: members,
       );

  /// Returns a shallow copy of this [Role]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Role copyWith({
    Object? id = _Undefined,
    String? name,
    List<_ikdgfgc9.Permission>? permissions,
    bool? isSystem,
    bool? active,
    DateTime? createdAt,
    Object? members = _Undefined,
  }) {
    return Role(
      id: id is _is.UuidValue? ? id : this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions.map((e0) => e0).toList(),
      isSystem: isSystem ?? this.isSystem,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      members: members is List<_i3fhtrko.StaffMember>?
          ? members
          : this.members?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class RoleUpdateTable extends _is.UpdateTable<RoleTable> {
  RoleUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<List<_ikdgfgc9.Permission>, List<_ikdgfgc9.Permission>>
  permissions(List<_ikdgfgc9.Permission> value) => _is.ColumnValue(
    table.permissions,
    value,
  );

  _is.ColumnValue<bool, bool> isSystem(bool value) => _is.ColumnValue(
    table.isSystem,
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
}

class RoleTable extends _is.Table<_is.UuidValue?> {
  RoleTable({super.tableRelation}) : super(tableName: 'staff_roles') {
    updateTable = RoleUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    permissions = _is.ColumnSerializable<List<_ikdgfgc9.Permission>>(
      'permissions',
      this,
    );
    isSystem = _is.ColumnBool(
      'isSystem',
      this,
      hasDefault: true,
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
  }

  late final RoleUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnSerializable<List<_ikdgfgc9.Permission>> permissions;

  late final _is.ColumnBool isSystem;

  /// Un rol inactivo no da permisos ni se puede asignar.
  late final _is.ColumnBool active;

  late final _is.ColumnDateTime createdAt;

  _i3fhtrko.StaffMemberTable? ___members;

  _is.ManyRelation<_i3fhtrko.StaffMemberTable>? _members;

  _i3fhtrko.StaffMemberTable get __members {
    if (___members != null) return ___members!;
    ___members = _is.createRelationTable(
      relationFieldName: '__members',
      field: Role.t.id,
      foreignField: _i3fhtrko.StaffMember.t.roleId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3fhtrko.StaffMemberTable(tableRelation: foreignTableRelation),
    );
    return ___members!;
  }

  _is.ManyRelation<_i3fhtrko.StaffMemberTable> get members {
    if (_members != null) return _members!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'members',
      field: Role.t.id,
      foreignField: _i3fhtrko.StaffMember.t.roleId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3fhtrko.StaffMemberTable(tableRelation: foreignTableRelation),
    );
    _members = _is.ManyRelation<_i3fhtrko.StaffMemberTable>(
      tableWithRelations: relationTable,
      table: _i3fhtrko.StaffMemberTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _members!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    name,
    permissions,
    isSystem,
    active,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'members') {
      return __members;
    }
    return null;
  }
}

class RoleInclude extends _is.IncludeObject {
  RoleInclude._({_i3fhtrko.StaffMemberIncludeList? members}) {
    _members = members;
  }

  _i3fhtrko.StaffMemberIncludeList? _members;

  @override
  Map<String, _is.Include?> get includes => {'members': _members};

  @override
  _is.Table<_is.UuidValue?> get table => Role.t;
}

class RoleIncludeList extends _is.IncludeList {
  RoleIncludeList._({
    _is.WhereExpressionBuilder<RoleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Role.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Role.t;
}

class RoleRepository {
  const RoleRepository._();

  final attach = const RoleAttachRepository._();

  final attachRow = const RoleAttachRowRepository._();

  /// Returns a list of [Role]s matching the given query parameters.
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
  Future<List<Role>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    _is.Transaction? transaction,
    RoleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Role>(
      where: where?.call(Role.t),
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Role] matching the given query parameters.
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
  Future<Role?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoleTable>? where,
    int? offset,
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    _is.Transaction? transaction,
    RoleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Role>(
      where: where?.call(Role.t),
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Role] by its [id] or null if no such row exists.
  Future<Role?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    RoleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Role>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Role]s in the list and returns the inserted rows.
  ///
  /// The returned [Role]s will have their `id` fields set.
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
  Future<List<Role>> insert(
    _is.DatabaseSession session,
    List<Role> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Role>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Role] and returns the inserted row.
  ///
  /// The returned [Role] will have its `id` field set.
  Future<Role> insertRow(
    _is.DatabaseSession session,
    Role row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Role>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Role]s in the list and returns the resulting rows.
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
  /// The returned [Role]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Role>> upsert(
    _is.DatabaseSession session,
    List<Role> rows, {
    required _is.ColumnSelections<RoleTable> conflictColumns,
    _is.ColumnSelections<RoleTable>? updateColumns,
    _is.WhereExpressionBuilder<RoleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Role>(
      rows,
      conflictColumns: conflictColumns(Role.t),
      updateColumns: updateColumns?.call(Role.t),
      updateWhere: updateWhere?.call(Role.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Role] and returns the resulting row.
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
  /// The returned [Role] will have its `id` field set.
  Future<Role?> upsertRow(
    _is.DatabaseSession session,
    Role row, {
    required _is.ColumnSelections<RoleTable> conflictColumns,
    _is.ColumnSelections<RoleTable>? updateColumns,
    _is.WhereExpressionBuilder<RoleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Role>(
      row,
      conflictColumns: conflictColumns(Role.t),
      updateColumns: updateColumns?.call(Role.t),
      updateWhere: updateWhere?.call(Role.t),
      transaction: transaction,
    );
  }

  /// Updates all [Role]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Role>> update(
    _is.DatabaseSession session,
    List<Role> rows, {
    _is.ColumnSelections<RoleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Role>(
      rows,
      columns: columns?.call(Role.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Role]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Role> updateRow(
    _is.DatabaseSession session,
    Role row, {
    _is.ColumnSelections<RoleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Role>(
      row,
      columns: columns?.call(Role.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Role] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Role?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<RoleUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Role>(
      id,
      columnValues: columnValues(Role.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Role]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Role>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RoleUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RoleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Role>(
      columnValues: columnValues(Role.t.updateTable),
      where: where(Role.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Role]s in the list and returns the deleted rows.
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
  Future<List<Role>> delete(
    _is.DatabaseSession session,
    List<Role> rows, {
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Role>(
      rows,
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Role].
  Future<Role> deleteRow(
    _is.DatabaseSession session,
    Role row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Role>(
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
  Future<List<Role>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoleTable> where,
    _is.OrderByBuilder<RoleTable>? orderBy,
    _is.OrderByListBuilder<RoleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Role>(
      where: where(Role.t),
      orderBy: orderBy?.call(Role.t),
      orderByList: orderByList?.call(Role.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Role>(
      where: where?.call(Role.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Role] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Role>(
      where: where(Role.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RoleAttachRepository {
  const RoleAttachRepository._();

  /// Creates a relation between this [Role] and the given [StaffMember]s
  /// by setting each [StaffMember]'s foreign key `roleId` to refer to this [Role].
  Future<void> members(
    _is.DatabaseSession session,
    Role role,
    List<_i3fhtrko.StaffMember> staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.any((e) => e.id == null)) {
      throw ArgumentError.notNull('staffMember.id');
    }
    if (role.id == null) {
      throw ArgumentError.notNull('role.id');
    }

    var $staffMember = staffMember
        .map((e) => e.copyWith(roleId: role.id))
        .toList();
    await session.db.update<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.roleId],
      transaction: transaction,
    );
  }
}

class RoleAttachRowRepository {
  const RoleAttachRowRepository._();

  /// Creates a relation between this [Role] and the given [StaffMember]
  /// by setting the [StaffMember]'s foreign key `roleId` to refer to this [Role].
  Future<void> members(
    _is.DatabaseSession session,
    Role role,
    _i3fhtrko.StaffMember staffMember, {
    _is.Transaction? transaction,
  }) async {
    if (staffMember.id == null) {
      throw ArgumentError.notNull('staffMember.id');
    }
    if (role.id == null) {
      throw ArgumentError.notNull('role.id');
    }

    var $staffMember = staffMember.copyWith(roleId: role.id);
    await session.db.updateRow<_i3fhtrko.StaffMember>(
      $staffMember,
      columns: [_i3fhtrko.StaffMember.t.roleId],
      transaction: transaction,
    );
  }
}
