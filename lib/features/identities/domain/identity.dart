import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_colors.dart';

enum IdentityType { job, freelance, personal, sideProject, custom }

extension IdentityTypeX on IdentityType {
  String get label => switch (this) {
        IdentityType.job => 'Job',
        IdentityType.freelance => 'Freelance',
        IdentityType.personal => 'Personal',
        IdentityType.sideProject => 'Side Project',
        IdentityType.custom => 'Custom',
      };

  Color get color => switch (this) {
        IdentityType.job => AppColors.identityJob,
        IdentityType.freelance => AppColors.identityFreelance,
        IdentityType.personal => AppColors.identityPersonal,
        IdentityType.sideProject => AppColors.identitySide,
        IdentityType.custom => AppColors.identityCustom,
      };
}

class Identity {
  const Identity({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    this.tagline = '',
    required this.createdAt,
    required this.updatedAt,
    this.dirty = false,
  });

  final String id;
  final String name;
  final IdentityType type;
  final int colorValue;
  final String tagline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;

  Color get color => Color(colorValue);

  Identity copyWith({
    String? id,
    String? name,
    IdentityType? type,
    int? colorValue,
    String? tagline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Identity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      tagline: tagline ?? this.tagline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'colorValue': colorValue,
        'tagline': tagline,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: IdentityType.values.byName(json['type'] as String),
      colorValue: json['colorValue'] as int? ??
          (json['color_value'] as int?) ??
          AppColors.identityCustom.toARGB32(),
      tagline: json['tagline'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}
