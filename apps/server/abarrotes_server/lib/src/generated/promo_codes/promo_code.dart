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
import '../promo_codes/promo_code_allowed_email.dart' as _i0o3plfo;
import '../promo_codes/promo_code_eligibility.dart' as _ivxx501j;
import '../promotions/promotion.dart' as _irk6gnzq;

/// Un código promocional con el texto que eligió el administrador
/// ("VERANO-10"). Quien lo activa en su cuenta usa sus promociones (las de
/// audiencia `code`) por un tiempo y unos pedidos. Las fechas son los días
/// de la tienda (America/Lima) en que se puede activar: [inicio 00:00, día
/// siguiente al fin 00:00).
abstract class PromoCode
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PromoCode._({
    this.id,
    required this.code,
    bool? active,
    required this.startDate,
    required this.endDate,
    this.benefitDays,
    this.maxRedemptions,
    this.usesPerCustomer,
    this.minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    this.promotions,
    this.allowedEmails,
  }) : active = active ?? true,
       newCustomersOnly = newCustomersOnly ?? false,
       eligibility = eligibility ?? _ivxx501j.PromoCodeEligibility.everyone,
       createdAt = createdAt ?? DateTime.now();

  factory PromoCode({
    _is.UuidValue? id,
    required String code,
    bool? active,
    required DateTime startDate,
    required DateTime endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  }) = _PromoCodeImpl;

  factory PromoCode.fromJson(Map<String, dynamic> jsonSerialization) {
    return PromoCode(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      code: jsonSerialization['code'] as String,
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      startDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startDate'],
      ),
      endDate: _is.DateTimeJsonExtension.fromJson(jsonSerialization['endDate']),
      benefitDays: jsonSerialization['benefitDays'] as int?,
      maxRedemptions: jsonSerialization['maxRedemptions'] as int?,
      usesPerCustomer: jsonSerialization['usesPerCustomer'] as int?,
      minPurchaseCents: jsonSerialization['minPurchaseCents'] as int?,
      newCustomersOnly: jsonSerialization['newCustomersOnly'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['newCustomersOnly'],
            ),
      eligibility: jsonSerialization['eligibility'] == null
          ? null
          : _ivxx501j.PromoCodeEligibility.fromJson(
              (jsonSerialization['eligibility'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      promotions: jsonSerialization['promotions'] == null
          ? null
          : _i1p9jj0z.Protocol().deserialize<List<_irk6gnzq.Promotion>>(
              jsonSerialization['promotions'],
            ),
      allowedEmails: jsonSerialization['allowedEmails'] == null
          ? null
          : _i1p9jj0z.Protocol()
                .deserialize<List<_i0o3plfo.PromoCodeAllowedEmail>>(
                  jsonSerialization['allowedEmails'],
                ),
    );
  }

  static final t = PromoCodeTable();

  static const db = PromoCodeRepository._();

  @override
  _is.UuidValue? id;

  /// En mayúsculas: de 3 a 20 letras, números o guiones.
  String code;

  /// El interruptor: apagado no se activa y sus promociones dejan de valer.
  bool active;

  DateTime startDate;

  DateTime endDate;

  /// Cuántos días dura el beneficio desde que cada cliente lo activa. Sin
  /// valor, hasta el fin de la vigencia.
  int? benefitDays;

  /// Cuántos clientes pueden activarlo. Sin valor, sin límite.
  int? maxRedemptions;

  /// En cuántos pedidos puede usarlo cada cliente. Sin valor, sin límite.
  int? usesPerCustomer;

  /// La compra mínima, en céntimos: el total sin las promociones del código.
  int? minPurchaseCents;

  /// Solo para quien todavía no hizo ningún pedido.
  bool newCustomersOnly;

  /// Quién puede activarlo: todos, los VIP o los correos de [allowedEmails].
  _ivxx501j.PromoCodeEligibility eligibility;

  DateTime createdAt;

  /// Las promociones que da (con audiencia `code`): al menos una para
  /// encenderlo.
  List<_irk6gnzq.Promotion>? promotions;

  /// Con `eligibility` en `listed`: los correos que pueden activarlo.
  List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PromoCode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PromoCode copyWith({
    _is.UuidValue? id,
    String? code,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PromoCode',
      if (id != null) 'id': id?.toJson(),
      'code': code,
      'active': active,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      if (benefitDays != null) 'benefitDays': benefitDays,
      if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      if (usesPerCustomer != null) 'usesPerCustomer': usesPerCustomer,
      if (minPurchaseCents != null) 'minPurchaseCents': minPurchaseCents,
      'newCustomersOnly': newCustomersOnly,
      'eligibility': eligibility.toJson(),
      'createdAt': createdAt.toJson(),
      if (promotions != null)
        'promotions': promotions?.toJson(valueToJson: (v) => v.toJson()),
      if (allowedEmails != null)
        'allowedEmails': allowedEmails?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PromoCode',
      if (id != null) 'id': id?.toJson(),
      'code': code,
      'active': active,
      'startDate': startDate.toJson(),
      'endDate': endDate.toJson(),
      if (benefitDays != null) 'benefitDays': benefitDays,
      if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      if (usesPerCustomer != null) 'usesPerCustomer': usesPerCustomer,
      if (minPurchaseCents != null) 'minPurchaseCents': minPurchaseCents,
      'newCustomersOnly': newCustomersOnly,
      'eligibility': eligibility.toJson(),
      'createdAt': createdAt.toJson(),
      if (promotions != null)
        'promotions': promotions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (allowedEmails != null)
        'allowedEmails': allowedEmails?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  static PromoCodeInclude include({
    _irk6gnzq.PromotionIncludeList? promotions,
    _i0o3plfo.PromoCodeAllowedEmailIncludeList? allowedEmails,
  }) {
    return PromoCodeInclude._(
      promotions: promotions,
      allowedEmails: allowedEmails,
    );
  }

  static PromoCodeIncludeList includeList({
    _is.WhereExpressionBuilder<PromoCodeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    PromoCodeInclude? include,
  }) {
    return PromoCodeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PromoCodeImpl extends PromoCode {
  _PromoCodeImpl({
    _is.UuidValue? id,
    required String code,
    bool? active,
    required DateTime startDate,
    required DateTime endDate,
    int? benefitDays,
    int? maxRedemptions,
    int? usesPerCustomer,
    int? minPurchaseCents,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    List<_irk6gnzq.Promotion>? promotions,
    List<_i0o3plfo.PromoCodeAllowedEmail>? allowedEmails,
  }) : super._(
         id: id,
         code: code,
         active: active,
         startDate: startDate,
         endDate: endDate,
         benefitDays: benefitDays,
         maxRedemptions: maxRedemptions,
         usesPerCustomer: usesPerCustomer,
         minPurchaseCents: minPurchaseCents,
         newCustomersOnly: newCustomersOnly,
         eligibility: eligibility,
         createdAt: createdAt,
         promotions: promotions,
         allowedEmails: allowedEmails,
       );

  /// Returns a shallow copy of this [PromoCode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PromoCode copyWith({
    Object? id = _Undefined,
    String? code,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
    Object? benefitDays = _Undefined,
    Object? maxRedemptions = _Undefined,
    Object? usesPerCustomer = _Undefined,
    Object? minPurchaseCents = _Undefined,
    bool? newCustomersOnly,
    _ivxx501j.PromoCodeEligibility? eligibility,
    DateTime? createdAt,
    Object? promotions = _Undefined,
    Object? allowedEmails = _Undefined,
  }) {
    return PromoCode(
      id: id is _is.UuidValue? ? id : this.id,
      code: code ?? this.code,
      active: active ?? this.active,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      benefitDays: benefitDays is int? ? benefitDays : this.benefitDays,
      maxRedemptions: maxRedemptions is int?
          ? maxRedemptions
          : this.maxRedemptions,
      usesPerCustomer: usesPerCustomer is int?
          ? usesPerCustomer
          : this.usesPerCustomer,
      minPurchaseCents: minPurchaseCents is int?
          ? minPurchaseCents
          : this.minPurchaseCents,
      newCustomersOnly: newCustomersOnly ?? this.newCustomersOnly,
      eligibility: eligibility ?? this.eligibility,
      createdAt: createdAt ?? this.createdAt,
      promotions: promotions is List<_irk6gnzq.Promotion>?
          ? promotions
          : this.promotions?.map((e0) => e0.copyWith()).toList(),
      allowedEmails: allowedEmails is List<_i0o3plfo.PromoCodeAllowedEmail>?
          ? allowedEmails
          : this.allowedEmails?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class PromoCodeUpdateTable extends _is.UpdateTable<PromoCodeTable> {
  PromoCodeUpdateTable(super.table);

  _is.ColumnValue<String, String> code(String value) => _is.ColumnValue(
    table.code,
    value,
  );

  _is.ColumnValue<bool, bool> active(bool value) => _is.ColumnValue(
    table.active,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startDate(DateTime value) =>
      _is.ColumnValue(
        table.startDate,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> endDate(DateTime value) =>
      _is.ColumnValue(
        table.endDate,
        value,
      );

  _is.ColumnValue<int, int> benefitDays(int? value) => _is.ColumnValue(
    table.benefitDays,
    value,
  );

  _is.ColumnValue<int, int> maxRedemptions(int? value) => _is.ColumnValue(
    table.maxRedemptions,
    value,
  );

  _is.ColumnValue<int, int> usesPerCustomer(int? value) => _is.ColumnValue(
    table.usesPerCustomer,
    value,
  );

  _is.ColumnValue<int, int> minPurchaseCents(int? value) => _is.ColumnValue(
    table.minPurchaseCents,
    value,
  );

  _is.ColumnValue<bool, bool> newCustomersOnly(bool value) => _is.ColumnValue(
    table.newCustomersOnly,
    value,
  );

  _is.ColumnValue<
    _ivxx501j.PromoCodeEligibility,
    _ivxx501j.PromoCodeEligibility
  >
  eligibility(_ivxx501j.PromoCodeEligibility value) => _is.ColumnValue(
    table.eligibility,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PromoCodeTable extends _is.Table<_is.UuidValue?> {
  PromoCodeTable({super.tableRelation}) : super(tableName: 'promo_codes') {
    updateTable = PromoCodeUpdateTable(this);
    code = _is.ColumnString(
      'code',
      this,
    );
    active = _is.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
    startDate = _is.ColumnDateTime(
      'startDate',
      this,
    );
    endDate = _is.ColumnDateTime(
      'endDate',
      this,
    );
    benefitDays = _is.ColumnInt(
      'benefitDays',
      this,
    );
    maxRedemptions = _is.ColumnInt(
      'maxRedemptions',
      this,
    );
    usesPerCustomer = _is.ColumnInt(
      'usesPerCustomer',
      this,
    );
    minPurchaseCents = _is.ColumnInt(
      'minPurchaseCents',
      this,
    );
    newCustomersOnly = _is.ColumnBool(
      'newCustomersOnly',
      this,
      hasDefault: true,
    );
    eligibility = _is.ColumnEnum(
      'eligibility',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final PromoCodeUpdateTable updateTable;

  /// En mayúsculas: de 3 a 20 letras, números o guiones.
  late final _is.ColumnString code;

  /// El interruptor: apagado no se activa y sus promociones dejan de valer.
  late final _is.ColumnBool active;

  late final _is.ColumnDateTime startDate;

  late final _is.ColumnDateTime endDate;

  /// Cuántos días dura el beneficio desde que cada cliente lo activa. Sin
  /// valor, hasta el fin de la vigencia.
  late final _is.ColumnInt benefitDays;

  /// Cuántos clientes pueden activarlo. Sin valor, sin límite.
  late final _is.ColumnInt maxRedemptions;

  /// En cuántos pedidos puede usarlo cada cliente. Sin valor, sin límite.
  late final _is.ColumnInt usesPerCustomer;

  /// La compra mínima, en céntimos: el total sin las promociones del código.
  late final _is.ColumnInt minPurchaseCents;

  /// Solo para quien todavía no hizo ningún pedido.
  late final _is.ColumnBool newCustomersOnly;

  /// Quién puede activarlo: todos, los VIP o los correos de [allowedEmails].
  late final _is.ColumnEnum<_ivxx501j.PromoCodeEligibility> eligibility;

  late final _is.ColumnDateTime createdAt;

  /// Las promociones que da (con audiencia `code`): al menos una para
  /// encenderlo.
  _irk6gnzq.PromotionTable? ___promotions;

  /// Las promociones que da (con audiencia `code`): al menos una para
  /// encenderlo.
  _is.ManyRelation<_irk6gnzq.PromotionTable>? _promotions;

  /// Con `eligibility` en `listed`: los correos que pueden activarlo.
  _i0o3plfo.PromoCodeAllowedEmailTable? ___allowedEmails;

  /// Con `eligibility` en `listed`: los correos que pueden activarlo.
  _is.ManyRelation<_i0o3plfo.PromoCodeAllowedEmailTable>? _allowedEmails;

  _irk6gnzq.PromotionTable get __promotions {
    if (___promotions != null) return ___promotions!;
    ___promotions = _is.createRelationTable(
      relationFieldName: '__promotions',
      field: PromoCode.t.id,
      foreignField: _irk6gnzq.Promotion.t.promoCodeId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _irk6gnzq.PromotionTable(tableRelation: foreignTableRelation),
    );
    return ___promotions!;
  }

  _i0o3plfo.PromoCodeAllowedEmailTable get __allowedEmails {
    if (___allowedEmails != null) return ___allowedEmails!;
    ___allowedEmails = _is.createRelationTable(
      relationFieldName: '__allowedEmails',
      field: PromoCode.t.id,
      foreignField: _i0o3plfo.PromoCodeAllowedEmail.t.promoCodeId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i0o3plfo.PromoCodeAllowedEmailTable(
            tableRelation: foreignTableRelation,
          ),
    );
    return ___allowedEmails!;
  }

  _is.ManyRelation<_irk6gnzq.PromotionTable> get promotions {
    if (_promotions != null) return _promotions!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'promotions',
      field: PromoCode.t.id,
      foreignField: _irk6gnzq.Promotion.t.promoCodeId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _irk6gnzq.PromotionTable(tableRelation: foreignTableRelation),
    );
    _promotions = _is.ManyRelation<_irk6gnzq.PromotionTable>(
      tableWithRelations: relationTable,
      table: _irk6gnzq.PromotionTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _promotions!;
  }

  _is.ManyRelation<_i0o3plfo.PromoCodeAllowedEmailTable> get allowedEmails {
    if (_allowedEmails != null) return _allowedEmails!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'allowedEmails',
      field: PromoCode.t.id,
      foreignField: _i0o3plfo.PromoCodeAllowedEmail.t.promoCodeId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i0o3plfo.PromoCodeAllowedEmailTable(
            tableRelation: foreignTableRelation,
          ),
    );
    _allowedEmails = _is.ManyRelation<_i0o3plfo.PromoCodeAllowedEmailTable>(
      tableWithRelations: relationTable,
      table: _i0o3plfo.PromoCodeAllowedEmailTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _allowedEmails!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    code,
    active,
    startDate,
    endDate,
    benefitDays,
    maxRedemptions,
    usesPerCustomer,
    minPurchaseCents,
    newCustomersOnly,
    eligibility,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'promotions') {
      return __promotions;
    }
    if (relationField == 'allowedEmails') {
      return __allowedEmails;
    }
    return null;
  }
}

class PromoCodeInclude extends _is.IncludeObject {
  PromoCodeInclude._({
    _irk6gnzq.PromotionIncludeList? promotions,
    _i0o3plfo.PromoCodeAllowedEmailIncludeList? allowedEmails,
  }) {
    _promotions = promotions;
    _allowedEmails = allowedEmails;
  }

  _irk6gnzq.PromotionIncludeList? _promotions;

  _i0o3plfo.PromoCodeAllowedEmailIncludeList? _allowedEmails;

  @override
  Map<String, _is.Include?> get includes => {
    'promotions': _promotions,
    'allowedEmails': _allowedEmails,
  };

  @override
  _is.Table<_is.UuidValue?> get table => PromoCode.t;
}

class PromoCodeIncludeList extends _is.IncludeList {
  PromoCodeIncludeList._({
    _is.WhereExpressionBuilder<PromoCodeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PromoCode.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PromoCode.t;
}

class PromoCodeRepository {
  const PromoCodeRepository._();

  final attach = const PromoCodeAttachRepository._();

  final attachRow = const PromoCodeAttachRowRepository._();

  final detach = const PromoCodeDetachRepository._();

  final detachRow = const PromoCodeDetachRowRepository._();

  /// Returns a list of [PromoCode]s matching the given query parameters.
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
  Future<List<PromoCode>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PromoCode>(
      where: where?.call(PromoCode.t),
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PromoCode] matching the given query parameters.
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
  Future<PromoCode?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeTable>? where,
    int? offset,
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    _is.Transaction? transaction,
    PromoCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PromoCode>(
      where: where?.call(PromoCode.t),
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PromoCode] by its [id] or null if no such row exists.
  Future<PromoCode?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PromoCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PromoCode>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PromoCode]s in the list and returns the inserted rows.
  ///
  /// The returned [PromoCode]s will have their `id` fields set.
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
  Future<List<PromoCode>> insert(
    _is.DatabaseSession session,
    List<PromoCode> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PromoCode>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PromoCode] and returns the inserted row.
  ///
  /// The returned [PromoCode] will have its `id` field set.
  Future<PromoCode> insertRow(
    _is.DatabaseSession session,
    PromoCode row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PromoCode>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PromoCode]s in the list and returns the resulting rows.
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
  /// The returned [PromoCode]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCode>> upsert(
    _is.DatabaseSession session,
    List<PromoCode> rows, {
    required _is.ColumnSelections<PromoCodeTable> conflictColumns,
    _is.ColumnSelections<PromoCodeTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PromoCode>(
      rows,
      conflictColumns: conflictColumns(PromoCode.t),
      updateColumns: updateColumns?.call(PromoCode.t),
      updateWhere: updateWhere?.call(PromoCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PromoCode] and returns the resulting row.
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
  /// The returned [PromoCode] will have its `id` field set.
  Future<PromoCode?> upsertRow(
    _is.DatabaseSession session,
    PromoCode row, {
    required _is.ColumnSelections<PromoCodeTable> conflictColumns,
    _is.ColumnSelections<PromoCodeTable>? updateColumns,
    _is.WhereExpressionBuilder<PromoCodeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PromoCode>(
      row,
      conflictColumns: conflictColumns(PromoCode.t),
      updateColumns: updateColumns?.call(PromoCode.t),
      updateWhere: updateWhere?.call(PromoCode.t),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCode]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCode>> update(
    _is.DatabaseSession session,
    List<PromoCode> rows, {
    _is.ColumnSelections<PromoCodeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PromoCode>(
      rows,
      columns: columns?.call(PromoCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PromoCode]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PromoCode> updateRow(
    _is.DatabaseSession session,
    PromoCode row, {
    _is.ColumnSelections<PromoCodeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PromoCode>(
      row,
      columns: columns?.call(PromoCode.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PromoCode] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PromoCode?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PromoCodeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PromoCode>(
      id,
      columnValues: columnValues(PromoCode.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PromoCode]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PromoCode>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PromoCodeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PromoCodeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PromoCode>(
      columnValues: columnValues(PromoCode.t.updateTable),
      where: where(PromoCode.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PromoCode]s in the list and returns the deleted rows.
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
  Future<List<PromoCode>> delete(
    _is.DatabaseSession session,
    List<PromoCode> rows, {
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PromoCode>(
      rows,
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PromoCode].
  Future<PromoCode> deleteRow(
    _is.DatabaseSession session,
    PromoCode row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PromoCode>(
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
  Future<List<PromoCode>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeTable> where,
    _is.OrderByBuilder<PromoCodeTable>? orderBy,
    _is.OrderByListBuilder<PromoCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PromoCode>(
      where: where(PromoCode.t),
      orderBy: orderBy?.call(PromoCode.t),
      orderByList: orderByList?.call(PromoCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PromoCodeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PromoCode>(
      where: where?.call(PromoCode.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PromoCode] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PromoCodeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PromoCode>(
      where: where(PromoCode.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PromoCodeAttachRepository {
  const PromoCodeAttachRepository._();

  /// Creates a relation between this [PromoCode] and the given [Promotion]s
  /// by setting each [Promotion]'s foreign key `promoCodeId` to refer to this [PromoCode].
  Future<void> promotions(
    _is.DatabaseSession session,
    PromoCode promoCode,
    List<_irk6gnzq.Promotion> promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.any((e) => e.id == null)) {
      throw ArgumentError.notNull('promotion.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promotion = promotion
        .map((e) => e.copyWith(promoCodeId: promoCode.id))
        .toList();
    await session.db.update<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.promoCodeId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [PromoCode] and the given [PromoCodeAllowedEmail]s
  /// by setting each [PromoCodeAllowedEmail]'s foreign key `promoCodeId` to refer to this [PromoCode].
  Future<void> allowedEmails(
    _is.DatabaseSession session,
    PromoCode promoCode,
    List<_i0o3plfo.PromoCodeAllowedEmail> promoCodeAllowedEmail, {
    _is.Transaction? transaction,
  }) async {
    if (promoCodeAllowedEmail.any((e) => e.id == null)) {
      throw ArgumentError.notNull('promoCodeAllowedEmail.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promoCodeAllowedEmail = promoCodeAllowedEmail
        .map((e) => e.copyWith(promoCodeId: promoCode.id))
        .toList();
    await session.db.update<_i0o3plfo.PromoCodeAllowedEmail>(
      $promoCodeAllowedEmail,
      columns: [_i0o3plfo.PromoCodeAllowedEmail.t.promoCodeId],
      transaction: transaction,
    );
  }
}

class PromoCodeAttachRowRepository {
  const PromoCodeAttachRowRepository._();

  /// Creates a relation between this [PromoCode] and the given [Promotion]
  /// by setting the [Promotion]'s foreign key `promoCodeId` to refer to this [PromoCode].
  Future<void> promotions(
    _is.DatabaseSession session,
    PromoCode promoCode,
    _irk6gnzq.Promotion promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.id == null) {
      throw ArgumentError.notNull('promotion.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promotion = promotion.copyWith(promoCodeId: promoCode.id);
    await session.db.updateRow<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.promoCodeId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [PromoCode] and the given [PromoCodeAllowedEmail]
  /// by setting the [PromoCodeAllowedEmail]'s foreign key `promoCodeId` to refer to this [PromoCode].
  Future<void> allowedEmails(
    _is.DatabaseSession session,
    PromoCode promoCode,
    _i0o3plfo.PromoCodeAllowedEmail promoCodeAllowedEmail, {
    _is.Transaction? transaction,
  }) async {
    if (promoCodeAllowedEmail.id == null) {
      throw ArgumentError.notNull('promoCodeAllowedEmail.id');
    }
    if (promoCode.id == null) {
      throw ArgumentError.notNull('promoCode.id');
    }

    var $promoCodeAllowedEmail = promoCodeAllowedEmail.copyWith(
      promoCodeId: promoCode.id,
    );
    await session.db.updateRow<_i0o3plfo.PromoCodeAllowedEmail>(
      $promoCodeAllowedEmail,
      columns: [_i0o3plfo.PromoCodeAllowedEmail.t.promoCodeId],
      transaction: transaction,
    );
  }
}

class PromoCodeDetachRepository {
  const PromoCodeDetachRepository._();

  /// Detaches the relation between this [PromoCode] and the given [Promotion]
  /// by setting the [Promotion]'s foreign key `promoCodeId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> promotions(
    _is.DatabaseSession session,
    List<_irk6gnzq.Promotion> promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.any((e) => e.id == null)) {
      throw ArgumentError.notNull('promotion.id');
    }

    var $promotion = promotion
        .map((e) => e.copyWith(promoCodeId: null))
        .toList();
    await session.db.update<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.promoCodeId],
      transaction: transaction,
    );
  }
}

class PromoCodeDetachRowRepository {
  const PromoCodeDetachRowRepository._();

  /// Detaches the relation between this [PromoCode] and the given [Promotion]
  /// by setting the [Promotion]'s foreign key `promoCodeId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> promotions(
    _is.DatabaseSession session,
    _irk6gnzq.Promotion promotion, {
    _is.Transaction? transaction,
  }) async {
    if (promotion.id == null) {
      throw ArgumentError.notNull('promotion.id');
    }

    var $promotion = promotion.copyWith(promoCodeId: null);
    await session.db.updateRow<_irk6gnzq.Promotion>(
      $promotion,
      columns: [_irk6gnzq.Promotion.t.promoCodeId],
      transaction: transaction,
    );
  }
}
