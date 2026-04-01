import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:peya_app/models/vertical_model.dart';
import 'package:peya_app/services/branch_service.dart';
import 'package:peya_app/services/product_service.dart';
import 'package:peya_app/services/vertical_service.dart';

/// Verticales activas para el home (tabla `Vertical`).
Future<List<VerticalModel>> verticalsProvider() async {
  return VerticalService().getActiveVerticals();
}

/// Sucursales con `verticalId` asignado en base de datos.
Future<List<VendorBranchModel>> storesByVerticalProvider(String verticalId) async {
  return BranchService().getBranchesByVerticalId(verticalId);
}

Future<List<ProductModel>> storeMenuProvider(String storeId) async {
  final service = ProductService();
  return service.getStoreMenuByStoreId(storeId);
}

Map<String, List<ProductModel>> groupProductsByCategory(List<ProductModel> products) {
  final grouped = <String, List<ProductModel>>{};
  for (final product in products) {
    final key = product.displayCategoryName.trim().isEmpty
        ? 'Otros'
        : product.displayCategoryName.trim();
    grouped.putIfAbsent(key, () => <ProductModel>[]).add(product);
  }
  return grouped;
}

Future<Map<String, List<ProductModel>>> groupedStoreMenuProvider(String storeId) async {
  final products = await storeMenuProvider(storeId);
  return groupProductsByCategory(products);
}
