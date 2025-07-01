/// Represents a brand or manufacturer.
class Brand {
  final String id;
  final String name;
  final String? suffix;

  Brand({required this.id, required this.name, this.suffix});

  factory Brand.fromJson(Map<String, dynamic> json, String id) {
    return Brand(
      id: id,
      name: json['name'] as String,
      suffix: json['suffix'] as String?,
    );
  }
}
