class Contact {
  const Contact({
    required this.id,
    required this.identityId,
    required this.name,
    this.email = '',
    this.phone = '',
    this.company = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.dirty = false,
  });

  final String id;
  final String identityId;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;

  Contact copyWith({
    String? id,
    String? identityId,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Contact(
      id: id ?? this.id,
      identityId: identityId ?? this.identityId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityId': identityId,
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      identityId: json['identityId'] as String? ?? json['identity_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}
