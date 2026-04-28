class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.icon,
  });

  final String id;
  final String name;
  /// `expense` | `income`
  final String type;
  final String? color;
  final String? icon;

  factory CategoryModel.fromRow(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }
}
