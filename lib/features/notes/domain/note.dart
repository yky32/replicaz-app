class Note {
  const Note({
    required this.id,
    required this.identityId,
    required this.title,
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
    this.dirty = false,
  });

  final String id;
  final String identityId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;

  Note copyWith({
    String? id,
    String? identityId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id ?? this.id,
      identityId: identityId ?? this.identityId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityId': identityId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      identityId: json['identityId'] as String? ?? json['identity_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}
