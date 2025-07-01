/// Represents a specific model of a headphone/IEM, belonging to a brand.
class PhoneModel {
  final String id;
  final String name;
  final String brandId;
  final List<String>? file;
  final List<String>? suffix;
  final String? price;
  final String? reviewScore;
  final String? reviewLink;
  final String? shopLink;
  final String? collab;

  PhoneModel({
    required this.id,
    required this.name,
    required this.brandId,
    this.file,
    this.suffix,
    this.price,
    this.reviewScore,
    this.reviewLink,
    this.shopLink,
    this.collab,
  });

  factory PhoneModel.fromJson(
    Map<String, dynamic> json,
    String id,
    String brandId,
  ) {
    return PhoneModel(
      id: '$brandId $id',
      name: json['name'] as String,
      brandId: brandId,
      file:
          (json['file'] is String)
              ? [(json['file'] as String)]
              : (json['file'] as List<dynamic>?)?.cast<String>(),
      suffix:
          (json['suffix'] is String)
              ? [(json['suffix'] as String)]
              : (json['suffix'] as List<dynamic>?)?.cast<String>(),
      price: json['price'] as String?,
      reviewScore: json['reviewScore'] as String?,
      reviewLink: json['reviewLink'] as String?,
      shopLink: json['shopLink'] as String?,
      collab: json['collab'] as String?,
    );
  }
}
