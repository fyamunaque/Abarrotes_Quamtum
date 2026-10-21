import 'package:serverpod/serverpod.dart';

import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/pagination.dart';
import 'vip_service.dart';

/// Rutas de clientes VIP: admin y staff los ven; solo admin los cambia.
List<RouteEntry> vipRoutes(VipService vips, FirebaseTokenVerifier verifier) {
  Route staffOnly(Method method, ApiHandler handler) =>
      RoleGuard(staffRoles, ApiRoute(method, handler), verifier: verifier);
  Route adminOnly(Method method, ApiHandler handler) =>
      RoleGuard(adminRoles, ApiRoute(method, handler), verifier: verifier);

  return [
    (
      '/vip-customers',
      staffOnly(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'search', 'includeInactive'},
        );
        final page = PageQuery.read(query);
        final search = query.text('search', maxLength: 254, required: false);
        final includeInactive =
            query.boolean('includeInactive', required: false) ?? false;
        query.check();

        final (list, total) = await vips.list(
          session,
          page,
          search: search,
          includeInactive: includeInactive,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(vipCustomerJson).toList(), total),
        );
      }),
    ),
    (
      '/vip-customers',
      // Uno o varios correos a la vez: responde qué se agregó, qué ya estaba
      // y qué no es un correo válido.
      adminOnly(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'emails'},
        );
        final emails = body.strings(
          'emails',
          maxLength: 320,
          min: 1,
          max: VipService.maxPerRequest,
        );
        body.check();

        final summary = await vips.add(
          session,
          emails!,
          by: request.currentUser,
        );
        return jsonResponse(200, {
          'added': summary.added,
          'duplicates': summary.duplicates,
          'invalid': summary.invalid,
        });
      }),
    ),
    (
      '/vip-customers/:id',
      // Baja lógica: deja de ser VIP y queda el historial.
      adminOnly(Method.delete, (session, request) async {
        final item = await vips.deactivate(session, idParam(request));
        return jsonResponse(200, vipCustomerJson(item));
      }),
    ),
  ];
}

/// Un VIP para el panel: con quién lo agregó y si su correo ya tiene cuenta.
Map<String, Object?> vipCustomerJson(VipListItem item) {
  final vip = item.vip;
  final addedBy = vip.addedBy;
  return {
    'id': vip.id.toString(),
    'email': vip.email,
    'active': vip.active,
    'createdAt': vip.createdAt.toUtc().toIso8601String(),
    'hasAccount': item.hasAccount,
    'addedBy': addedBy == null
        ? null
        : {
            'id': addedBy.id.toString(),
            'name': addedBy.name,
            'email': addedBy.email,
          },
  };
}
