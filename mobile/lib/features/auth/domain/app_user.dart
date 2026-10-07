enum Role {
  monitored('MONITORED'),
  helper('HELPER');

  const Role(this.apiValue);
  final String apiValue;

  static Role fromApi(String value) => value == 'HELPER' ? Role.helper : Role.monitored;
}

class AppUser {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final Role role;

  const AppUser({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        role: Role.fromApi(json['role'] as String),
      );

  String get fullName => '$name $lastName';
}
