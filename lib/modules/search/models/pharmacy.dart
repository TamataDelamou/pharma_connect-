class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  /// C252 : position facultative (officine inscrite sans position).
  final double? latitude;
  final double? longitude;
  final bool isOpenNow;
  final bool isOpen24h;
  final bool isOnDuty;
  final double? distance;
  final String? openingHours;
  final String? imageUrl;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
    required this.isOpenNow,
    this.isOpen24h = false,
    this.isOnDuty = false,
    this.distance,
    this.openingHours,
    this.imageUrl,
  });

  // isOpenNow/isOpen24h/isOnDuty/openingHours n'existent pas dans
  // public.pharmacies (aucune notion d'horaires en base aujourd'hui) —
  // valeurs par défaut documentées, pas une vraie source de vérité.
  // distance est calculé côté client (LocationService), jamais lu ici.
  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isOpenNow: true,
    isOpen24h: false,
    isOnDuty: false,
  );

  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isOpenNow,
    bool? isOpen24h,
    bool? isOnDuty,
    double? distance,
    String? openingHours,
    String? imageUrl,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      isOpen24h: isOpen24h ?? this.isOpen24h,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      distance: distance ?? this.distance,
      openingHours: openingHours ?? this.openingHours,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get distanceFormatted {
    if (distance == null) return 'Distance inconnue';
    if (distance! < 1000) return '${distance!.round()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
