class ProductModel {
  const ProductModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imageUrl,
    required this.categoria,
    required this.descripcion,
    required this.categoryId,
    required this.isActive,
  });

  final String id;
  final String nombre;
  final double precio;
  final String imageUrl;
  final String categoria;
  final String descripcion;
  final String categoryId;
  final bool isActive;

  String get displayName => nombre;
  String get displayDescription => descripcion;
  double get displayPrice => precio;
  String get displayImageUrl => imageUrl;
  String get displayCategoryId => categoryId.isNotEmpty ? categoryId : categoria;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPrice = json['precio'] ?? json['price'];
    final dynamic rawImage = json['imageUrl'] ?? json['image_url'];
    final dynamic rawName = json['nombre'] ?? json['name'];
    final dynamic rawDescription = json['descripcion'] ?? json['description'];
    final dynamic rawCategory = json['categoria'] ?? json['category'];
    final dynamic rawCategoryId = json['categoryId'] ?? json['category_id'];
    final dynamic rawIsActive = json['isActive'] ?? json['is_active'];

    return ProductModel(
      id: json['id'].toString(),
      nombre: (rawName ?? '').toString(),
      precio: (rawPrice as num?)?.toDouble() ?? 0,
      imageUrl: (rawImage ?? '').toString(),
      categoria: (rawCategory ?? '').toString(),
      descripcion: (rawDescription ?? '').toString(),
      categoryId: (rawCategoryId ?? '').toString(),
      isActive: rawIsActive is bool
          ? rawIsActive
          : rawIsActive?.toString().toLowerCase() == 'true',
    );
  }
}
