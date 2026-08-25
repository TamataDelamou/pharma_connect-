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
