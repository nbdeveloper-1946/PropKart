/// Client-side RBAC helpers. Server must still enforce every mutation.
class RoleGuard {
  static bool isSuperAdmin(String? role) =>
      (role ?? '').toLowerCase() == 'super admin';

  static bool isAdmin(String? role) {
    final r = (role ?? '').toLowerCase();
    return r == 'admin' || r == 'super admin';
  }

  static bool canManageEmployees(String? role) => isAdmin(role);

  /// Only Super Admin may assign/create/update/delete Admin accounts.
  static bool canAssignAdminRole(String? callerRole) => isSuperAdmin(callerRole);

  /// Returns an error message if [callerRole] cannot create/update a user
  /// with [targetRoleName]; null if allowed.
  static String? validateUserMutation({
    required String? callerRole,
    required String? targetRoleName,
    required bool isDelete,
  }) {
    if (!canManageEmployees(callerRole)) {
      return 'You do not have permission to manage employees.';
    }

    final target = (targetRoleName ?? '').toLowerCase();
    if (target == 'super admin') {
      return 'Super Admin accounts cannot be created or modified from the app.';
    }

    if (target == 'admin') {
      if (!canAssignAdminRole(callerRole)) {
        return 'Only Super Admin can create, update, or delete Admin users.';
      }
    }

    if (isDelete && target == 'admin' && !canAssignAdminRole(callerRole)) {
      return 'Only Super Admin can delete Admin users.';
    }

    // Admin may only manage Sales (and similar non-admin roles).
    if (!isSuperAdmin(callerRole) && target == 'admin') {
      return 'Admins may only manage Sales users.';
    }

    return null;
  }

  /// Resolve role name from role id using a roles list of maps/objects with id+name.
  static String? roleNameForId(String? roleId, Iterable<({String id, String name})> roles) {
    if (roleId == null) return null;
    for (final r in roles) {
      if (r.id == roleId) return r.name;
    }
    return null;
  }
}
