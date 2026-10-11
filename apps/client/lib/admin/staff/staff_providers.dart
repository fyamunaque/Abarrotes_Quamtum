import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../../session/staff_permission.dart';
import '../emails.dart';
import '../paged_notifier.dart';
import 'staff.dart';
import 'staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => HttpStaffRepository(ref.watch(authedApiProvider)),
);

/// El equipo, filtrado por lo buscado ('' para todos).
final staffMembersProvider = AsyncNotifierProvider.autoDispose
    .family<StaffMembersNotifier, PageList<StaffMember>, String>(
      StaffMembersNotifier.new,
    );

class StaffMembersNotifier extends PagedNotifier<StaffMember> {
  StaffMembersNotifier(this.search);

  final String search;

  StaffRepository get _repository => ref.read(staffRepositoryProvider);

  @override
  Future<PageList<StaffMember>> fetch(int page) =>
      _repository.members(page: page, search: search);

  /// Agrega [emails] con el rol [roleId] y vuelve a cargar la tabla desde
  /// la primera página.
  Future<EmailAddSummary> add(List<String> emails, String roleId) async {
    final summary = await _repository.addMembers(emails, roleId);
    if (summary.added.isNotEmpty) {
      ref.invalidateSelf();
      // Cambió cuántas personas tiene el rol.
      ref.invalidate(staffRolesProvider);
    }
    return summary;
  }

  /// Le pone el rol [roleId] y deja la fila al día, sin volver a pedir la
  /// tabla.
  Future<StaffMember> changeRole(String id, String roleId) async {
    final member = await _repository.changeRole(id, roleId);
    replace(member, (current) => current.id == id);
    ref.invalidate(staffRolesProvider);
    return member;
  }

  /// La da de baja: sigue en la tabla, como dada de baja.
  Future<StaffMember> deactivate(String id) async {
    final member = await _repository.deactivate(id);
    replace(member, (current) => current.id == id);
    ref.invalidate(staffRolesProvider);
    return member;
  }

  /// La vuelve a agregar con el rol que tenía (el servidor la reactiva) y
  /// vuelve a pedir la página.
  Future<void> reactivate(StaffMember member) async {
    await _repository.addMembers([member.email], member.roleId!);
    ref.invalidate(staffRolesProvider);
    // Si falla, la tabla queda como estaba: el alta ya se guardó.
    await refresh().catchError((Object _) {});
  }
}

/// Los roles del equipo, el del sistema primero.
final staffRolesProvider =
    AsyncNotifierProvider.autoDispose<StaffRolesNotifier, List<StaffRole>>(
      StaffRolesNotifier.new,
    );

class StaffRolesNotifier extends AsyncNotifier<List<StaffRole>> {
  StaffRepository get _repository => ref.read(staffRepositoryProvider);

  @override
  Future<List<StaffRole>> build() => _repository.roles();

  Future<StaffRole> create({
    required String name,
    required Set<StaffPermission> permissions,
  }) async {
    final role = await _repository.createRole(
      name: name,
      permissions: permissions,
    );
    ref.invalidateSelf();
    return role;
  }

  /// Cambia lo que no sea null.
  Future<StaffRole> save(
    String id, {
    String? name,
    Set<StaffPermission>? permissions,
    bool? active,
  }) async {
    final role = await _repository.updateRole(
      id,
      name: name,
      permissions: permissions,
      active: active,
    );
    ref.invalidateSelf();
    // La tabla del equipo muestra el nombre del rol.
    ref.invalidate(staffMembersProvider);
    return role;
  }

  Future<void> delete(String id) async {
    await _repository.deleteRole(id);
    ref.invalidateSelf();
  }
}
