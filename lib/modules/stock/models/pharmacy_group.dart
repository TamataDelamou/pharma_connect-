class PharmacyGroup {
  final String id;
  final String name;
  final String code;
  final List<PharmacyBranch> branches;
  final bool isActive;

  const PharmacyGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.branches,
    this.isActive = true,
  });

  int get totalBranches => branches.length;
  int get activeBranches => branches.where((b) => b.isActive).length;
}

class PharmacyBranch {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isActive;
  final String? managerId;

  const PharmacyBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    this.managerId,
  });
}
