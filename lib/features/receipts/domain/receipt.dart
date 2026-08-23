enum ReceiptKind {
  handwritten,
  pos,
  delivery;

  String get label => switch (this) {
        ReceiptKind.handwritten => 'Handwritten',
        ReceiptKind.pos => 'POS',
        ReceiptKind.delivery => 'Delivery',
      };

  String get labelZh => switch (this) {
        ReceiptKind.handwritten => '手寫單',
        ReceiptKind.pos => 'POS 單',
        ReceiptKind.delivery => '收貨單',
      };

  static ReceiptKind fromStorage(String? raw) {
    return ReceiptKind.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ReceiptKind.pos,
    );
  }
}

class Receipt {
  const Receipt({
    required this.id,
    required this.identityId,
    required this.kind,
    required this.title,
    this.merchant = '',
    this.amountText = '',
    this.note = '',
    this.qrPayload = '',
    this.imagePath = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String identityId;
  final ReceiptKind kind;
  final String title;
  final String merchant;
  final String amountText;
  final String note;
  final String qrPayload;
  final String imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt copyWith({
    String? id,
    String? identityId,
    ReceiptKind? kind,
    String? title,
    String? merchant,
    String? amountText,
    String? note,
    String? qrPayload,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      identityId: identityId ?? this.identityId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      amountText: amountText ?? this.amountText,
      note: note ?? this.note,
      qrPayload: qrPayload ?? this.qrPayload,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityId': identityId,
        'kind': kind.name,
        'title': title,
        'merchant': merchant,
        'amountText': amountText,
        'note': note,
        'qrPayload': qrPayload,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      identityId:
          json['identityId'] as String? ?? json['identity_id'] as String,
      kind: ReceiptKind.fromStorage(json['kind'] as String?),
      title: json['title'] as String? ?? 'Receipt',
      merchant: json['merchant'] as String? ?? '',
      amountText: json['amountText'] as String? ??
          json['amount_text'] as String? ??
          '',
      note: json['note'] as String? ?? '',
      qrPayload:
          json['qrPayload'] as String? ?? json['qr_payload'] as String? ?? '',
      imagePath:
          json['imagePath'] as String? ?? json['image_path'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
    );
  }
}
