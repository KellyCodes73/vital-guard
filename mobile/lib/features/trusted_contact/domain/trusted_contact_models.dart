class PersonSummary {
  final int id;
  final String name;
  final String lastName;

  const PersonSummary({required this.id, required this.name, required this.lastName});

  factory PersonSummary.fromJson(Map<String, dynamic> json) => PersonSummary(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        lastName: json['lastName'] as String,
      );

  String get fullName => '$name $lastName';
}

class TrustedContactLink {
  final int id;
  final String status; // PENDING | ACTIVE
  final String? inviteCode;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final PersonSummary? monitoredUser;
  final PersonSummary? helperUser;

  const TrustedContactLink({
    required this.id,
    required this.status,
    required this.inviteCode,
    required this.expiresAt,
    required this.createdAt,
    required this.acceptedAt,
    required this.monitoredUser,
    required this.helperUser,
  });

  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';

  static PersonSummary? _person(dynamic v) =>
      v == null ? null : PersonSummary.fromJson(Map<String, dynamic>.from(v as Map));

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);

  factory TrustedContactLink.fromJson(Map<String, dynamic> json) => TrustedContactLink(
        id: (json['id'] as num).toInt(),
        status: json['status'] as String,
        inviteCode: json['inviteCode'] as String?,
        expiresAt: _date(json['expiresAt']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        acceptedAt: _date(json['acceptedAt']),
        monitoredUser: _person(json['monitoredUser']),
        helperUser: _person(json['helperUser']),
      );
}
