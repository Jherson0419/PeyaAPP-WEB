class CartItem {
  const CartItem({
    required this.branchId,
    required this.branchName,
    this.storeIconUrl,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.productImageUrl,
    this.branchLatitude,
    this.branchLongitude,
  });

  final String branchId;
  final String branchName;
  final String? storeIconUrl;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String productImageUrl;
  /// Coordenadas de la sucursal al añadir (para distancia correcta sin depender solo del último pin del mapa).
  final double? branchLatitude;
  final double? branchLongitude;

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      branchId: branchId,
      branchName: branchName,
      storeIconUrl: storeIconUrl,
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity ?? this.quantity,
      productImageUrl: productImageUrl,
      branchLatitude: branchLatitude,
      branchLongitude: branchLongitude,
    );
  }
}

