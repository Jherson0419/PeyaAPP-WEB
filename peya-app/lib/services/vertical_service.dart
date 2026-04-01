import 'package:peya_app/models/vertical_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerticalService {
  VerticalService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<VerticalModel>> getActiveVerticals() async {
    final response = await _client
        .from('Vertical')
        .select()
        .eq('isActive', true)
        .order('name', ascending: true);

    final list = response as List<dynamic>;
    return list
        .map((e) => VerticalModel.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .where((v) => v.id.isNotEmpty && v.name.isNotEmpty)
        .toList();
  }
}
