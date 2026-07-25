import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  group('RoleGuard', () {
    test('Sales cannot manage employees', () {
      expect(RoleGuard.canManageEmployees('Sales'), isFalse);
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Sales',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('Admin cannot create or delete Admin', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNotNull,
      );
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Admin',
          isDelete: true,
        ),
        isNotNull,
      );
    });

    test('Admin can manage Sales', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNull,
      );
    });

    test('Super Admin can manage Admin but not Super Admin', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNull,
      );
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Super Admin',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('JWT/role string tampering as Broker is denied', () {
      expect(RoleGuard.canManageEmployees('Broker'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Broker'), isFalse);
    });
  });
}
