class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    this.note,
    this.paymentMethod,
    this.categoryId,
    this.accountId,
    this.categoryName,
    this.accountName,
  });

  final String id;
  final String type;
  final int amountMinor;
  final DateTime occurredAt;
  final String? note;
  final String? paymentMethod;
  final String? categoryId;
  final String? accountId;
  final String? categoryName;
  final String? accountName;

  factory TransactionModel.fromRow(Map<String, dynamic> json) {
    final occurredRaw = json['occurred_at'];
    DateTime occurred;
    if (occurredRaw is String) {
      occurred = DateTime.parse(occurredRaw);
    } else {
      occurred = DateTime.now();
    }

    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amountMinor: (json['amount_minor'] as num).toInt(),
      occurredAt: occurred,
      note: json['note'] as String?,
      paymentMethod: json['payment_method'] as String?,
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?,
      categoryName: _nestedName(json, 'categories'),
      accountName: _nestedName(json, 'accounts'),
    );
  }

  static String? _nestedName(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is Map<String, dynamic>) {
      return v['name'] as String?;
    }
    return null;
  }
}
