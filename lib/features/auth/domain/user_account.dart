class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
    this.alias = '',
  });

  final String id;
  final String email;
  final String displayName;
  final String alias;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'alias': alias,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ??
          json['display_name'] as String? ??
          '',
      alias: json['alias'] as String? ?? '',
    );
  }
}
