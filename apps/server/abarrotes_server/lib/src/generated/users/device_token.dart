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

/// Un dispositivo (un teléfono o un navegador) donde la cuenta recibe avisos
/// push: su token de registro de FCM. Una cuenta puede tener varios.
abstract class DeviceToken
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  DeviceToken._({
    this.id,
    required this.token,
    this.platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory DeviceToken({
    _is.UuidValue? id,
    required String token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
  }) = _DeviceTokenImpl;

  factory DeviceToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceToken(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      token: jsonSerialization['token'] as String,
      platform: jsonSerialization['platform'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      user: jsonSerialization['user'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<_iqzoui01.User>(
              jsonSerialization['user'],
            ),
    );
  }

  static final t = DeviceTokenTable();

  static const db = DeviceTokenRepository._();

  @override
  _is.UuidValue? id;

  /// El token de registro de FCM, que da la app (firebase_messaging).
  String token;

  /// android o web; solo informativo.
  String? platform;

  DateTime createdAt;

  /// La última vez que la app lo registró.
  DateTime updatedAt;

  _is.UuidValue userId;

  _iqzoui01.User? user;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceToken copyWith({
    _is.UuidValue? id,
    String? token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    _is.UuidValue? userId,
    _iqzoui01.User? user,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'token': token,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id?.toJson(),
      'token': token,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'userId': userId.toJson(),
      if (user != null) 'user': user?.toJsonForProtocol(),
    };
  }

  static DeviceTokenInclude include({_iqzoui01.UserInclude? user}) {
    return DeviceTokenInclude._(user: user);
  }

  static DeviceTokenIncludeList includeList({
    _is.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    DeviceTokenInclude? include,
  }) {
    return DeviceTokenIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceTokenImpl extends DeviceToken {
  _DeviceTokenImpl({
    _is.UuidValue? id,
    required String token,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    required _is.UuidValue userId,
    _iqzoui01.User? user,
  }) : super._(
         id: id,
         token: token,
         platform: platform,
         createdAt: createdAt,
         updatedAt: updatedAt,
         userId: userId,
         user: user,
       );

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceToken copyWith({
    Object? id = _Undefined,
    String? token,
    Object? platform = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _is.UuidValue? userId,
    Object? user = _Undefined,
  }) {
    return DeviceToken(
      id: id is _is.UuidValue? ? id : this.id,
      token: token ?? this.token,
      platform: platform is String? ? platform : this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      user: user is _iqzoui01.User? ? user : this.user?.copyWith(),
    );
  }
}

class DeviceTokenUpdateTable extends _is.UpdateTable<DeviceTokenTable> {
  DeviceTokenUpdateTable(super.table);

  _is.ColumnValue<String, String> token(String value) => _is.ColumnValue(
    table.token,
    value,
  );

  _is.ColumnValue<String, String> platform(String? value) => _is.ColumnValue(
    table.platform,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );
}

class DeviceTokenTable extends _is.Table<_is.UuidValue?> {
  DeviceTokenTable({super.tableRelation}) : super(tableName: 'device_tokens') {
    updateTable = DeviceTokenUpdateTable(this);
    token = _is.ColumnString(
      'token',
      this,
    );
    platform = _is.ColumnString(
      'platform',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
  }

  late final DeviceTokenUpdateTable updateTable;

  /// El token de registro de FCM, que da la app (firebase_messaging).
  late final _is.ColumnString token;

  /// android o web; solo informativo.
  late final _is.ColumnString platform;

  late final _is.ColumnDateTime createdAt;

  /// La última vez que la app lo registró.
  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnUuid userId;

  _iqzoui01.UserTable? _user;

  _iqzoui01.UserTable get user {
    if (_user != null) return _user!;
    _user = _is.createRelationTable(
      relationFieldName: 'user',
      field: DeviceToken.t.userId,
      foreignField: _iqzoui01.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzoui01.UserTable(tableRelation: foreignTableRelation),
    );
    return _user!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    token,
    platform,
    createdAt,
    updatedAt,
    userId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'user') {
      return user;
    }
    return null;
  }
}

class DeviceTokenInclude extends _is.IncludeObject {
  DeviceTokenInclude._({_iqzoui01.UserInclude? user}) {
    _user = user;
  }

  _iqzoui01.UserInclude? _user;

  @override
  Map<String, _is.Include?> get includes => {'user': _user};

  @override
  _is.Table<_is.UuidValue?> get table => DeviceToken.t;
}

class DeviceTokenIncludeList extends _is.IncludeList {
  DeviceTokenIncludeList._({
    _is.WhereExpressionBuilder<DeviceTokenTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DeviceToken.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => DeviceToken.t;
}

class DeviceTokenRepository {
  const DeviceTokenRepository._();

  final attachRow = const DeviceTokenAttachRowRepository._();

  /// Returns a list of [DeviceToken]s matching the given query parameters.
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
  Future<List<DeviceToken>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _is.Transaction? transaction,
    DeviceTokenInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DeviceToken>(
      where: where?.call(DeviceToken.t),
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DeviceToken] matching the given query parameters.
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
  Future<DeviceToken?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? offset,
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _is.Transaction? transaction,
    DeviceTokenInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DeviceToken>(
      where: where?.call(DeviceToken.t),
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DeviceToken] by its [id] or null if no such row exists.
  Future<DeviceToken?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    DeviceTokenInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DeviceToken>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DeviceToken]s in the list and returns the inserted rows.
  ///
  /// The returned [DeviceToken]s will have their `id` fields set.
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
  Future<List<DeviceToken>> insert(
    _is.DatabaseSession session,
    List<DeviceToken> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DeviceToken>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DeviceToken] and returns the inserted row.
  ///
  /// The returned [DeviceToken] will have its `id` field set.
  Future<DeviceToken> insertRow(
    _is.DatabaseSession session,
    DeviceToken row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DeviceToken>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DeviceToken]s in the list and returns the resulting rows.
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
  /// The returned [DeviceToken]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceToken>> upsert(
    _is.DatabaseSession session,
    List<DeviceToken> rows, {
    required _is.ColumnSelections<DeviceTokenTable> conflictColumns,
    _is.ColumnSelections<DeviceTokenTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceTokenTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DeviceToken>(
      rows,
      conflictColumns: conflictColumns(DeviceToken.t),
      updateColumns: updateColumns?.call(DeviceToken.t),
      updateWhere: updateWhere?.call(DeviceToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DeviceToken] and returns the resulting row.
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
  /// The returned [DeviceToken] will have its `id` field set.
  Future<DeviceToken?> upsertRow(
    _is.DatabaseSession session,
    DeviceToken row, {
    required _is.ColumnSelections<DeviceTokenTable> conflictColumns,
    _is.ColumnSelections<DeviceTokenTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceTokenTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DeviceToken>(
      row,
      conflictColumns: conflictColumns(DeviceToken.t),
      updateColumns: updateColumns?.call(DeviceToken.t),
      updateWhere: updateWhere?.call(DeviceToken.t),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceToken]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceToken>> update(
    _is.DatabaseSession session,
    List<DeviceToken> rows, {
    _is.ColumnSelections<DeviceTokenTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DeviceToken>(
      rows,
      columns: columns?.call(DeviceToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DeviceToken]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DeviceToken> updateRow(
    _is.DatabaseSession session,
    DeviceToken row, {
    _is.ColumnSelections<DeviceTokenTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DeviceToken>(
      row,
      columns: columns?.call(DeviceToken.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeviceToken] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DeviceToken?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DeviceTokenUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DeviceToken>(
      id,
      columnValues: columnValues(DeviceToken.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceToken]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceToken>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeviceTokenUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DeviceTokenTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DeviceToken>(
      columnValues: columnValues(DeviceToken.t.updateTable),
      where: where(DeviceToken.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DeviceToken]s in the list and returns the deleted rows.
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
  Future<List<DeviceToken>> delete(
    _is.DatabaseSession session,
    List<DeviceToken> rows, {
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DeviceToken>(
      rows,
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DeviceToken].
  Future<DeviceToken> deleteRow(
    _is.DatabaseSession session,
    DeviceToken row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DeviceToken>(
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
  Future<List<DeviceToken>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceTokenTable> where,
    _is.OrderByBuilder<DeviceTokenTable>? orderBy,
    _is.OrderByListBuilder<DeviceTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DeviceToken>(
      where: where(DeviceToken.t),
      orderBy: orderBy?.call(DeviceToken.t),
      orderByList: orderByList?.call(DeviceToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTokenTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DeviceToken>(
      where: where?.call(DeviceToken.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DeviceToken] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceTokenTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DeviceToken>(
      where: where(DeviceToken.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DeviceTokenAttachRowRepository {
  const DeviceTokenAttachRowRepository._();

  /// Creates a relation between the given [DeviceToken] and [User]
  /// by setting the [DeviceToken]'s foreign key `userId` to refer to the [User].
  Future<void> user(
    _is.DatabaseSession session,
    DeviceToken deviceToken,
    _iqzoui01.User user, {
    _is.Transaction? transaction,
  }) async {
    if (deviceToken.id == null) {
      throw ArgumentError.notNull('deviceToken.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $deviceToken = deviceToken.copyWith(userId: user.id);
    await session.db.updateRow<DeviceToken>(
      $deviceToken,
      columns: [DeviceToken.t.userId],
      transaction: transaction,
    );
  }
}
