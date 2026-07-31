enum FollowUpStatus { open, done }

class FollowUp {
  const FollowUp({
    required this.id,
    required this.identityId,
    required this.title,
    this.details = '',
    this.dueAt,
    this.status = FollowUpStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.dirty = false,
  });

  final String id;
  final String identityId;
  final String title;
  final String details;
  final DateTime? dueAt;
  final FollowUpStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;

  FollowUp copyWith({
    String? id,
    String? identityId,
    String? title,
    String? details,
    DateTime? dueAt,
    FollowUpStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
    bool clearDueAt = false,
  }) {
    return FollowUp(
      id: id ?? this.id,
      identityId: identityId ?? this.identityId,
      title: title ?? this.title,
      details: details ?? this.details,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityId': identityId,
        'title': title,
        'details': details,
        'dueAt': dueAt?.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'] as String,
      identityId: json['identityId'] as String? ?? json['identity_id'] as String,
      title: json['title'] as String,
      details: json['details'] as String? ?? '',
      dueAt: (json['dueAt'] ?? json['due_at']) != null
          ? DateTime.parse((json['dueAt'] ?? json['due_at']) as String)
          : null,
      status: FollowUpStatus.values.byName(json['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}
