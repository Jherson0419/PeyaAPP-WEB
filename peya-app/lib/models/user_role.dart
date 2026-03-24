enum UserRole {
  client('CLIENT'),
  rider('RIDER'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;
}
