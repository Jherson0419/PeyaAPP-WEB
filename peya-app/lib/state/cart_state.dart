import 'package:flutter/widgets.dart';
import 'package:peya_app/models/cart_item.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/vendor_branch_model.dart';

const double _baseDeliveryFee = 3.00;

class CartState extends ChangeNotifier {
  final List<CartItem> _items = <CartItem>[];
  VendorBranchModel? _selectedBranch;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (acc, item) => acc + item.quantity);
  VendorBranchModel? get selectedBranch => _selectedBranch;

  void selectBranch(VendorBranchModel branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  bool addToCart(
    ProductModel product, {
    int quantity = 1,
    String? branchId,
    String? branchName,
    String? storeIconUrl,
    double? branchLatitude,
    double? branchLongitude,
  }) {
    final resolvedBranchId = branchId ?? _selectedBranch?.id ?? 'sin-sucursal';
    final resolvedBranchName =
        branchName ?? _selectedBranch?.name ?? 'Sucursal no seleccionada';
    double? lat = branchLatitude;
    double? lng = branchLongitude;
    if ((lat == null || lng == null) &&
        _selectedBranch != null &&
        _selectedBranch!.id == resolvedBranchId) {
      lat = _selectedBranch!.latitude;
      lng = _selectedBranch!.longitude;
    }
    final idx = _items.indexWhere(
      (i) => i.productId == product.id && i.branchId == resolvedBranchId,
    );
    if (idx == -1) {
      _items.add(
        CartItem(
          branchId: resolvedBranchId,
          branchName: resolvedBranchName,
          storeIconUrl: storeIconUrl ?? _selectedBranch?.iconUrl,
          productId: product.id,
          productName: product.displayName,
          price: product.displayPrice,
          quantity: quantity.clamp(1, 99),
          productImageUrl: product.displayImageUrl,
          branchLatitude: lat,
          branchLongitude: lng,
        ),
      );
    } else {
      final updated = _items[idx].quantity + quantity;
      _items[idx] = _items[idx].copyWith(quantity: updated.clamp(1, 99));
    }
    notifyListeners();
    return true;
  }

  void clearCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  void removeFromCart(String branchId, String productId) {
    _items.removeWhere((i) => i.branchId == branchId && i.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String branchId, String productId, int quantity) {
    final idx = _items.indexWhere(
      (i) => i.branchId == branchId && i.productId == productId,
    );
    if (idx == -1) return;
    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx] = _items[idx].copyWith(quantity: quantity.clamp(1, 99));
    }
    notifyListeners();
  }

  double get subtotal {
    return _items.fold(0.0, (acc, item) => acc + item.total);
  }

  Map<String, List<CartItem>> get itemsByStore {
    final grouped = <String, List<CartItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.branchId, () => <CartItem>[]).add(item);
    }
    return grouped;
  }

  int get storeCount => itemsByStore.length;

  double get totalDeliveryFee {
    if (_items.isEmpty) return 0;
    return storeCount * _baseDeliveryFee;
  }

  double get total => subtotal + totalDeliveryFee;

  List<Map<String, dynamic>> buildSplitOrderPayloads() {
    final grouped = itemsByStore;
    return grouped.entries.map((entry) {
      final storeId = entry.key;
      final storeItems = entry.value;
      final productsSubtotal = storeItems.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );
      return {
        'storeId': storeId,
        'storeName': storeItems.first.branchName,
        'storeIconUrl': storeItems.first.storeIconUrl,
        'deliveryFee': _baseDeliveryFee,
        'subtotal': productsSubtotal,
        'total': productsSubtotal + _baseDeliveryFee,
        'items': storeItems
            .map(
              (item) => {
                'productId': item.productId,
                'productName': item.productName,
                'quantity': item.quantity,
                'unitPrice': item.price,
                'lineTotal': item.total,
              },
            )
            .toList(),
      };
    }).toList();
  }
}

class CartScope extends InheritedNotifier<CartState> {
  const CartScope({
    required CartState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static CartState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope no encontrado en el arbol.');
    return scope!.notifier!;
  }
}
