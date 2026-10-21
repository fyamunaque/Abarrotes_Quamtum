import '../../common/api_client.dart';
import '../../common/page_list.dart';
import '../../session/staff_permission.dart';
import '../emails.dart';
import 'staff.dart';

/// El equipo y sus roles (`/staff/*`, todo con `staff.manage`). Los errores
/// salen como `ApiFailure`, con el motivo del servidor cuando rechaza algo
/// (el último Administrador, un rol con personal asignado).
abstract interface class StaffRepository {
  /// Una página del equipo, por correo, con los dados de baja. Con [search],
  /// los correos que lo contienen.
  Future<PageList<StaffMember>> members({int page = 1, String search = ''});

  /// Agrega [emails] al equipo con el rol [roleId]: los dados de baja
  /// vuelven con ese rol.
  Future<EmailAddSummary> addMembers(List<String> emails, String roleId);

  /// Le pone el rol [roleId].
  Future<StaffMember> changeRole(String memberId, String roleId);

  /// Lo da de baja (no se borra) y lo devuelve.
  Future<StaffMember> deactivate(String memberId);

  /// Todos los roles, el del sistema primero.
  Future<List<StaffRole>> roles();

  Future<StaffRole> createRole({
    required String name,
    required Set<StaffPermission> permissions,
  });

  /// Cambia lo que no sea null.
  Future<StaffRole> updateRole(
    String id, {
    String? name,
    Set<StaffPermission>? permissions,
    bool? active,
  });

  Future<void> deleteRole(String id);
}

class HttpStaffRepository implements StaffRepository {
  HttpStaffRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<StaffMember>> members({
    int page = 1,
    String search = '',
  }) async {
    final json = await _api.get(
      '/staff/members',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        'includeInactive': 'true',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      fallback: 'No se pudo cargar el equipo.',
    );
    return decodeResponse(() => decodePage(json, StaffMember.fromJson));
  }

  @override
  Future<EmailAddSummary> addMembers(List<String> emails, String roleId) async {
    final json = await _api.post('/staff/members', {
      'emails': emails,
      'roleId': roleId,
    }, fallback: 'No se pudieron agregar los correos.');
    return decodeResponse(() => EmailAddSummary.fromJson(json));
  }

  @override
  Future<StaffMember> changeRole(String memberId, String roleId) async {
    final json = await _api.patch(
      '/staff/members/${Uri.encodeComponent(memberId)}',
      {'roleId': roleId},
      fallback: 'No se pudo cambiar el rol.',
    );
    return decodeResponse(() => StaffMember.fromJson(json));
  }

  @override
  Future<StaffMember> deactivate(String memberId) async {
    final json = await _api.delete(
      '/staff/members/${Uri.encodeComponent(memberId)}',
      fallback: 'No se pudo dar de baja.',
    );
    return decodeResponse(() => StaffMember.fromJson(json));
  }

  @override
  Future<List<StaffRole>> roles() async {
    final json = await _api.get(
      '/staff/roles',
      fallback: 'No se pudieron cargar los roles.',
    );
    return decodeResponse(
      () => switch (json) {
        {'data': final List<Object?> data} => [
          for (final role in data) StaffRole.fromJson(role),
        ],
        _ => throw FormatException('No es una lista de roles', json),
      },
    );
  }

  @override
  Future<StaffRole> createRole({
    required String name,
    required Set<StaffPermission> permissions,
  }) async {
    final json = await _api.post('/staff/roles', {
      'name': name,
      'permissions': _keys(permissions),
    }, fallback: 'No se pudo crear el rol.');
    return decodeResponse(() => StaffRole.fromJson(json));
  }

  @override
  Future<StaffRole> updateRole(
    String id, {
    String? name,
    Set<StaffPermission>? permissions,
    bool? active,
  }) async {
    final json = await _api.patch('/staff/roles/${Uri.encodeComponent(id)}', {
      'name': ?name,
      if (permissions != null) 'permissions': _keys(permissions),
      'active': ?active,
    }, fallback: 'No se pudo guardar el rol.');
    return decodeResponse(() => StaffRole.fromJson(json));
  }

  @override
  Future<void> deleteRole(String id) => _api.delete(
    '/staff/roles/${Uri.encodeComponent(id)}',
    fallback: 'No se pudo borrar el rol.',
  );

  /// En el orden del catálogo, como los muestra el servidor.
  static List<String> _keys(Set<StaffPermission> permissions) => [
    for (final permission in StaffPermission.values)
      if (permissions.contains(permission)) permission.key,
  ];
}
