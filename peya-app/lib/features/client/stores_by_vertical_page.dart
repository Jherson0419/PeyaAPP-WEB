import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/store_details_page.dart';
import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:peya_app/providers/store_providers.dart';

/// Lista de tiendas (`VendorBranch`) filtradas por [verticalId].
class StoresByVerticalPage extends StatelessWidget {
  const StoresByVerticalPage({
    required this.verticalId,
    required this.verticalName,
    super.key,
  });

  final String verticalId;
  final String verticalName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          verticalName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<VendorBranchModel>>(
        future: storesByVerticalProvider(verticalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudo cargar sucursales.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final branches = snapshot.data ?? <VendorBranchModel>[];
          if (branches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay tiendas en esta vertical por ahora.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = branches[i];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => StoreDetailsPage(
                        storeId: b.id,
                        storeName: b.name,
                        storeLogoUrl: b.iconUrl,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'branch-logo-${b.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: b.iconUrl != null && b.iconUrl!.isNotEmpty
                              ? Image.network(
                                  b.iconUrl!,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _placeholderLogo(),
                                )
                              : _placeholderLogo(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Distancia no calculada',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00796B),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderLogo() {
    return Container(
      width: 54,
      height: 54,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.storefront, color: Color(0xFF64748B)),
    );
  }
}
