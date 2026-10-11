import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/emails.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart' hide AuditLogRepository;
import 'audit_log_repository.dart';
import 'permissions.dart';
import 'roles_service.dart';
import 'staff_service.dart';

/// Rutas de roles, personal y bitácora: todas piden `staff.manage`.
List<RouteEntry> staffRoutes({
  required RolesService roles,
  required StaffService staff,
  required AuditLogRepository audit,
  required Guards guards,
}) {
  Route manage(Method method, ApiHandler handler) =>
      guards.require(Permission.staffManage, ApiRoute(method, handler));

  StaffActor actorOf(Request request) => (
    user: request.currentUser,
    email: normalizeEmail(request.firebaseIdentity.email ?? ''),
  );

  return [
    (
      '/staff/roles',
      manage(Method.get, (session, request) async {
        final list = await roles.list(session);
        return jsonResponse(200, {'data': list.map(roleJson).toList()});
      }),
    ),
    (
      '/staff/roles/:id',
      manage(Method.get, (session, request) async {
        return jsonResponse(
          200,
          roleJson(await roles.get(session, idParam(request))),
        );
      }),
    ),
    (
      '/staff/roles',
      manage(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'name', 'permissions'},
        );
        final name = _readName(body, required: true);
        final permissions = _readPermissions(body, required: true);
        body.check();

        final role = await roles.create(
          session,
          name: name!,
          permissions: permissions!,
          actor: request.currentUser,
        );
        return jsonResponse(201, roleJson((role: role, members: 0)));
      }),
    ),
    (
      '/staff/roles/:id',
      manage(Method.patch, (session, request) async {
        final id = idParam(request);
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'name', 'permissions', 'active'},
        );
        final name = _readName(body, required: false);
        final permissions = _readPermissions(body, required: false);
        final active = body.boolean('active', required: false);
        body.check();

        await roles.update(
          session,
          id,
          name: name,
          permissions: permissions,
          active: active,
          actor: request.currentUser,
        );
        return jsonResponse(200, roleJson(await roles.get(session, id)));
      }),
    ),
    (
      '/staff/roles/:id',
      manage(Method.delete, (session, request) async {
        await roles.delete(
          session,
          idParam(request),
          actor: request.currentUser,
        );
        return Response.noContent();
      }),
    ),
    (
      '/staff/members',
      manage(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'search', 'includeInactive'},
        );
        final page = PageQuery.read(query);
        final search = query.text('search', maxLength: 254, required: false);
        final includeInactive =
            query.boolean('includeInactive', required: false) ?? false;
        query.check();

        final (list, total) = await staff.list(
          session,
          page,
          search: search,
          includeInactive: includeInactive,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(staffMemberJson).toList(), total),
        );
      }),
    ),
    (
      '/staff/members',
      // Uno o varios correos con un rol: responde qué se agregó, qué ya
      // estaba y qué no es un correo válido.
      manage(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'emails', 'roleId'},
        );
        final emails = body.strings(
          'emails',
          maxLength: 320,
          min: 1,
          max: StaffService.maxPerRequest,
        );
        final roleId = body.uuid('roleId');
        body.check();

        final summary = await staff.add(
          session,
          emails!,
          roleId: roleId!,
          actor: actorOf(request),
        );
        return jsonResponse(200, {
          'added': summary.added,
          'duplicates': summary.duplicates,
          'invalid': summary.invalid,
        });
      }),
    ),
    (
      '/staff/members/:id',
      manage(Method.patch, (session, request) async {
        final id = idParam(request);
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'roleId'},
        );
        final roleId = body.uuid('roleId');
        body.check();

        final item = await staff.changeRole(
          session,
          id,
          roleId: roleId!,
          actor: actorOf(request),
        );
        return jsonResponse(200, staffMemberJson(item));
      }),
    ),
    (
      '/staff/members/:id',
      // Baja lógica: pierde sus permisos de inmediato y queda el historial.
      manage(Method.delete, (session, request) async {
        final item = await staff.deactivate(
          session,
          idParam(request),
          actor: actorOf(request),
        );
        return jsonResponse(200, staffMemberJson(item));
      }),
    ),
    (
      '/staff/audit',
      manage(Method.get, (session, request) async {
        final query = InputReader.query(request, allowed: PageQuery.fields);
        final page = PageQuery.read(query);
        query.check();

        final (list, total) = await audit.list(session, page);
        return jsonResponse(
          200,
          page.wrap(list.map(auditLogJson).toList(), total),
        );
      }),
    ),
  ];
}

/// El nombre de un rol: hasta 60 caracteres.
String? _readName(InputReader body, {required bool required}) =>
    body.text('name', maxLength: 60, required: required);

/// Los permisos de un rol, por clave ("products.view"): al menos uno, y solo
/// los del catálogo.
Set<Permission>? _readPermissions(
  InputReader body, {
  required bool required,
}) {
  final keys = body.strings(
    'permissions',
    maxLength: 60,
    min: 1,
    max: 100,
    required: required,
  );
  if (keys == null) return null;
  final permissions = <Permission>{};
  for (final (i, key) in keys.indexed) {
    final permission = permissionFromKey(key);
    if (permission == null) {
      body.reject('permissions[$i]: "$key" no es un permiso');
    } else {
      permissions.add(permission);
    }
  }
  return permissions;
}

/// Un rol para el panel: sus permisos efectivos y cuántas personas activas
/// lo tienen.
Map<String, Object?> roleJson(RoleWithMembers item) {
  final role = item.role;
  return {
    'id': role.id.toString(),
    'name': role.name,
    'permissions': permissionKeys(effectivePermissions(role)),
    'isSystem': role.isSystem,
    'active': role.active,
    'members': item.members,
    'createdAt': role.createdAt.toUtc().toIso8601String(),
  };
}

/// Una persona del personal para el panel.
Map<String, Object?> staffMemberJson(StaffListItem item) {
  final member = item.member;
  final role = member.role;
  final addedBy = member.addedBy;
  return {
    'id': member.id.toString(),
    'email': member.email,
    'active': member.active,
    'createdAt': member.createdAt.toUtc().toIso8601String(),
    'hasAccount': item.hasAccount,
    'role': role == null ? null : {'id': role.id.toString(), 'name': role.name},
    'addedBy': addedBy == null
        ? null
        : {
            'id': addedBy.id.toString(),
            'name': addedBy.name,
            'email': addedBy.email,
          },
  };
}

/// Una entrada de la bitácora.
Map<String, Object?> auditLogJson(AuditLog entry) {
  final actor = entry.actor;
  return {
    'id': entry.id.toString(),
    'action': entry.action.name,
    'targetEmail': entry.targetEmail,
    'details': entry.details == null ? null : jsonDecode(entry.details!),
    'createdAt': entry.createdAt.toUtc().toIso8601String(),
    'actor': actor == null
        ? null
        : {'id': actor.id.toString(), 'name': actor.name, 'email': actor.email},
  };
}
