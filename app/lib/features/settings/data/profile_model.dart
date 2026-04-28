class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.currencyCode,
    this.displayName,
  });

  final String id;
  final String? displayName;
  final String currencyCode;

  factory ProfileModel.fromRow(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      currencyCode: (json['currency_code'] as String?) ?? 'VND',
    );
  }
}

