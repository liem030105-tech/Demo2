class TransactionReceiptModel {
  const TransactionReceiptModel({
    required this.id,
    required this.transactionId,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final String transactionId;
  final String path;
  final DateTime createdAt;

  factory TransactionReceiptModel.fromRow(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    final createdAt = createdRaw is String
        ? DateTime.tryParse(createdRaw) ?? DateTime.now()
        : DateTime.now();
    return TransactionReceiptModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      path: json['path'] as String,
      createdAt: createdAt,
    );
  }
}

