import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lee sucursales activas desde la misma base que Prisma (`VendorBranch`).
class BranchService {
  BranchService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<VendorBranchModel>> getActiveBranches() async {
    final response = await _client
        .from('VendorBranch')
        .select('id,name,address,categoryId,verticalId,latitude,longitude,iconUrl,isActive')
        .eq('isActive', true)
        .order('createdAt', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((e) => VendorBranchModel.fromJson(e as Map<String, dynamic>))
        .where((b) => b.latitude != 0 || b.longitude != 0)
        .toList();
  }

  Future<List<VendorBranchModel>> getBranchesByCategory(String categoryId) async {
    final response = await _client
        .from('VendorBranch')
        .select('id,name,address,categoryId,verticalId,latitude,longitude,iconUrl,isActive,Product!inner(id,categoryId)')
        .eq('isActive', true)
        .eq('Product.categoryId', categoryId)
        .order('createdAt', ascending: false);

    final list = response as List<dynamic>;
    final unique = <String, VendorBranchModel>{};
    for (final row in list) {
      final branch = VendorBranchModel.fromJson(row as Map<String, dynamic>);
      unique[branch.id] = branch;
    }
    return unique.values.toList();
  }

  /// Sucursales activas de una vertical (sin filtros por ubicación/distancia).
  Future<List<VendorBranchModel>> getBranchesByVerticalId(String verticalId) async {
    final response = await _client
        .from('VendorBranch')
        .select('id,name,address,categoryId,verticalId,latitude,longitude,iconUrl,isActive')
        .eq('verticalId', verticalId)
        .eq('isActive', true)
        .order('createdAt', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((e) => VendorBranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<VendorBranchModel?> getBranchById(String branchId) async {
    try {
      final response = await _client
          .from('VendorBranch')
          .select(
            'id,name,address,categoryId,verticalId,latitude,longitude,iconUrl,isActive,'
            'BranchCategory(name,Vertical(name))',
          )
          .eq('id', branchId)
          .maybeSingle();
      if (response == null) return null;
      return VendorBranchModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      final response = await _client
          .from('VendorBranch')
          .select('id,name,address,categoryId,verticalId,latitude,longitude,iconUrl,isActive')
          .eq('id', branchId)
          .maybeSingle();
      if (response == null) return null;
      return VendorBranchModel.fromJson(Map<String, dynamic>.from(response));
    }
  }
}
