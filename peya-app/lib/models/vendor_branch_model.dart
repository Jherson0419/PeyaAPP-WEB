/// Sucursal del vendedor (tabla `VendorBranch` en Supabase / Postgres).
class VendorBranchModel {
  const VendorBranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    this.iconUrl,
    this.verticalId,
    this.verticalName,
    this.branchCategoryName,
  });

  final String id;
  final String name;
  final String address;
  final String categoryId;
  /// FK opcional hacia `Vertical` (sucursal asociada a una vertical).
  final String? verticalId;
  final double latitude;
  final double longitude;
  final String? iconUrl;
  final bool isActive;
  /// Nombre de la vertical (si viene en el join `BranchCategory -> Vertical`).
  final String? verticalName;
  /// Nombre del tipo de negocio (`BranchCategory`), útil si no hay vertical.
  final String? branchCategoryName;

  static double _parseCoord(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory VendorBranchModel.fromJson(Map<String, dynamic> json) {
    return VendorBranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      verticalId: json['verticalId']?.toString() ?? json['vertical_id']?.toString(),
      latitude: _parseCoord(json['latitude']),
      longitude: _parseCoord(json['longitude']),
      iconUrl: json['iconUrl']?.toString(),
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : json['isActive']?.toString().toLowerCase() == 'true',
      verticalName: _nestedVerticalName(json),
      branchCategoryName: _nestedBranchCategoryName(json),
    );
  }

  static String? _nestedBranchCategoryName(Map<String, dynamic> json) {
    final bc = json['BranchCategory'];
    if (bc is Map<String, dynamic>) {
      return bc['name']?.toString();
    }
    return null;
  }

  static String? _nestedVerticalName(Map<String, dynamic> json) {
    final bc = json['BranchCategory'];
    if (bc is Map<String, dynamic>) {
      final v = bc['Vertical'] ?? bc['vertical'];
      if (v is Map<String, dynamic>) {
        return v['name']?.toString();
      }
    }
    return null;
  }
}
