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
