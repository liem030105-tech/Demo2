class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory AccountModel.fromRow(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
