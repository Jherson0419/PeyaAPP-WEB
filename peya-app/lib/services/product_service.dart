import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/product_category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  ProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ProductModel>> getActiveProducts() async {
    final response = await _client
        .from('Product')
        .select()
        .eq('isActive', true)
        .order('categoryId', ascending: true);

    return (response as List<dynamic>)
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductCategoryModel>> getActiveCategories() async {
    final response = await _client
        .from('Category')
        .select('id,name,icon')
        .order('name', ascending: true);
    return (response as List<dynamic>)
        .map((item) => ProductCategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> getStoreMenuByStoreId(String storeId) async {
    final response = await _client
        .from('Product')
        .select(
          'id,name,description,price,imageUrl,categoryId,storeId,isActive,ProductCategory(name)',
        )
        .eq('isActive', true)
        .eq('storeId', storeId)
        .order('createdAt', ascending: false);

    return (response as List<dynamic>)
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
