class DeliveryDriver {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final bool isAvailable;
  final double? rating;
  final int completedDeliveries;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isColdChainCertified;

  const DeliveryDriver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.isAvailable,
    this.rating,
    required this.completedDeliveries,
    this.vehicleType,
    this.vehiclePlate,
    this.currentLatitude,
    this.currentLongitude,
    this.isColdChainCertified = false,
  });

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) => DeliveryDriver(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    photoUrl: json['photo_url'] as String?,
    isAvailable: json['is_available'] as bool? ?? true,
    rating: (json['rating'] as num?)?.toDouble(),
    completedDeliveries: json['completed_deliveries'] as int? ?? 0,
    vehicleType: json['vehicle_type'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
    currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
    currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
    isColdChainCertified: json['is_cold_chain_certified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'photo_url': photoUrl,
    'is_available': isAvailable,
    'rating': rating,
    'completed_deliveries': completedDeliveries,
    'vehicle_type': vehicleType,
    'vehicle_plate': vehiclePlate,
    'current_latitude': currentLatitude,
    'current_longitude': currentLongitude,
    'is_cold_chain_certified': isColdChainCertified,
  };

  DeliveryDriver copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAvailable,
    double? rating,
    int? completedDeliveries,
    String? vehicleType,
    String? vehiclePlate,
    double? currentLatitude,
    double? currentLongitude,
    bool? isColdChainCertified,
  }) {
    return DeliveryDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      isColdChainCertified: isColdChainCertified ?? this.isColdChainCertified,
    );
  }
}
