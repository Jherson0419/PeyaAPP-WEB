class ProductModel {
  const ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imageUrl,
    required this.categoria,
    required this.descripcion,
    required this.categoryId,
    this.categoryName,
    required this.storeId,
    required this.isActive,
  });

  final String id;
  final String nombre;
  final double precio;
  final String imageUrl;
  final String categoria;
  final String descripcion;
  final String categoryId;
  final String? categoryName;
  final String? storeId;
  final bool isActive;

  String get displayName => nombre;
  String get displayDescription => descripcion;
  double get displayPrice => precio;
  String get displayImageUrl => imageUrl;
  String get displayCategoryId => categoryId.isNotEmpty ? categoryId : categoria;
  String get displayCategoryName {
    final byJoin = categoryName?.trim();
    if (byJoin != null && byJoin.isNotEmpty) return byJoin;
    final raw = categoria.trim();
    if (raw.isNotEmpty) return raw;
    return 'Otros';
  }

  static String? _extractCategoryName(Map<String, dynamic> json) {
    final direct = json['categoryName'] ?? json['category_name'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    final category = json['ProductCategory'] ?? json['category'];
    if (category is Map<String, dynamic>) {
      final name = category['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPrice = json['precio'] ?? json['price'];
    final dynamic rawImage = json['imageUrl'] ?? json['image_url'];
    final dynamic rawName = json['nombre'] ?? json['name'];
    final dynamic rawDescription = json['descripcion'] ?? json['description'];
    final dynamic rawCategory = json['categoria'] ?? json['category'];
    final dynamic rawCategoryId = json['categoryId'] ?? json['category_id'];
    final dynamic rawStoreId = json['storeId'] ?? json['store_id'];
    final dynamic rawIsActive = json['isActive'] ?? json['is_active'];

    return ProductModel(
      id: json['id'].toString(),
      nombre: (rawName ?? '').toString(),
      precio: (rawPrice as num?)?.toDouble() ?? 0,
      imageUrl: (rawImage ?? '').toString(),
      categoria: (rawCategory ?? '').toString(),
      descripcion: (rawDescription ?? '').toString(),
      categoryId: (rawCategoryId ?? '').toString(),
      categoryName: _extractCategoryName(json),
      storeId: rawStoreId?.toString(),
      isActive: rawIsActive is bool
          ? rawIsActive
          : rawIsActive?.toString().toLowerCase() == 'true',
    );
  }
}
