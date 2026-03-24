import 'package:peya_app/models/product_model.dart';
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
}
