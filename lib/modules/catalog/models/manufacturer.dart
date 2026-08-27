class Manufacturer {
  final String id;
  final String name;
  final String? logoUrl;

  const Manufacturer({required this.id, required this.name, this.logoUrl});

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logo_url'] as String?,
  );
}
