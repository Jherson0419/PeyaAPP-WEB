import 'package:dio/dio.dart';
import 'package:peya_app/models/product_model.dart';

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'http://10.0.2.2:3000/api/products';
  final Dio _dio;

  Future<List<ProductModel>> getProducts() async {
    final Response<dynamic> response = await _dio.get<dynamic>(_baseUrl);
    final dynamic data = response.data;

    if (data is! List) {
      throw Exception('Respuesta inesperada del servidor');
    }

    return data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
