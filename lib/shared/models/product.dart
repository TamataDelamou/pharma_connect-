class Product {
  final String id;
  final String name;
  final String genericName;
  final String dosage;
  final String form;
  final String category;
  final String imageUrl;
  final bool isGeneric;
  final String manufacturer;
  final bool isPrescriptionRequired;
  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dosage,
    required this.form,
    required this.category,
    required this.imageUrl,
    required this.isGeneric,
    required this.manufacturer,
    required this.isPrescriptionRequired,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final manufacturer = json['manufacturer'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      genericName: json['generic_name'] as String,
      dosage: json['dosage'] as String,
      form: json['form'] as String,
      category: category?['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      isGeneric: json['is_generic'] as bool? ?? false,
      manufacturer: manufacturer?['name'] as String? ?? '',
      isPrescriptionRequired: json['is_prescription_required'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? genericName,
    String? dosage,
    String? form,
    String? category,
    String? imageUrl,
    bool? isGeneric,
    String? manufacturer,
    bool? isPrescriptionRequired,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isGeneric: isGeneric ?? this.isGeneric,
      manufacturer: manufacturer ?? this.manufacturer,
      isPrescriptionRequired:
          isPrescriptionRequired ?? this.isPrescriptionRequired,
      description: description ?? this.description,
    );
  }
}
