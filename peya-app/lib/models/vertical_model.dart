/// Fila de la tabla `Vertical` (Super App: Restaurantes, Supermercados, etc.).
class VerticalModel {
  const VerticalModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;

  factory VerticalModel.fromJson(Map<String, dynamic> json) {
    final rawActive = json['isActive'] ?? json['is_active'];
    return VerticalModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      isActive: rawActive is bool
          ? rawActive
          : rawActive?.toString().toLowerCase() == 'true',
    );
  }
}
