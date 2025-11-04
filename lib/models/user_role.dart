enum UserRole { customer, manong, admin, superadmin, moderator, guest }

extension UserRoleExtension on UserRole {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
