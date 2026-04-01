import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/client_auth_prompt_sheet.dart';
import 'package:peya_app/models/cart_item.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'package:peya_app/state/cart_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final appFlow = AppFlowScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          'Mi Pedido',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return const _EmptyCartState();
          }

          final subtotal = cart.subtotal;
          final shipping = cart.totalDeliveryFee;
          final total = cart.total;
          final deliveryLabel = appFlow.deliveryAddressLabel ?? 'Plaza de Armas, Trujillo';
          final groupedEntries = cart.itemsByStore.entries.toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    ...groupedEntries.map((entry) {
                      final storeItems = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StoreCartSection(items: storeItems),
                      );
                    }),
                    const SizedBox(height: 8),
                    _DeliverySummaryCard(
                      deliveryLabel: deliveryLabel,
                      storeCount: cart.storeCount,
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _PaymentDetail(
                      subtotal: subtotal,
                      shipping: shipping,
                      total: total,
                      storeCount: cart.storeCount,
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final session = Supabase.instance.client.auth.currentSession;
                        if (session == null) {
                          final ok = await ensureClientAuthenticated(
                            context,
                            dishName: 'tu pedido',
                          );
                          if (!ok) return;
                        }
                        if (!context.mounted) return;
                        final result = await _checkoutSplitOrders(
                          cart: cart,
                          deliveryAddress: deliveryLabel,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      },
                      child: Text(
                        'Proceder al Pago - S/ ${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _checkoutSplitOrders({
    required CartState cart,
    required String deliveryAddress,
  }) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 'No hay sesión activa para continuar.';

    try {
      final profile = await client
          .from('ClientProfile')
          .select('id')
          .eq('userId', userId)
          .maybeSingle();
      if (profile == null) {
        return 'No se encontró perfil de cliente para crear pedidos.';
      }
      final clientProfileId = profile['id']?.toString();
      if (clientProfileId == null || clientProfileId.isEmpty) {
        return 'Perfil de cliente inválido.';
      }

      final payloads = cart.buildSplitOrderPayloads();
      var createdOrders = 0;

      for (final payload in payloads) {
        final storeId = payload['storeId']?.toString();
        if (storeId == null || storeId.isEmpty) continue;

        final order = await client
            .from('Order')
            .insert({
              'clientProfileId': clientProfileId,
              'storeId': storeId,
              'status': 'PENDING',
            })
            .select('id')
            .single();

        final orderId = order['id']?.toString();
        if (orderId == null || orderId.isEmpty) {
          continue;
        }

        final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
        if (items.isNotEmpty) {
          final orderItems = items
              .map(
                (item) => {
                  'orderId': orderId,
                  'productId': item['productId'],
                  'quantity': item['quantity'],
                  'unitPrice': item['unitPrice'],
                },
              )
              .toList();
          await client.from('OrderItem').insert(orderItems);
        }
        createdOrders++;
      }

      if (createdOrders == 0) {
        return 'No se pudo crear pedidos para las tiendas actuales.';
      }

      cart.clearCart();
      return 'Pago iniciado: $createdOrders pedido(s) generado(s).';
    } catch (e) {
      return 'No se pudo procesar el checkout multitienda: $e';
    }
  }
}

class _StoreCartSection extends StatelessWidget {
  const _StoreCartSection({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final storeName = items.first.branchName;
    final storeIconUrl = items.first.storeIconUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (storeIconUrl != null && storeIconUrl.isNotEmpty)
                    ? Image.network(
                        storeIconUrl,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _storeIconFallback(),
                      )
                    : _storeIconFallback(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pedido de $storeName',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartItemCard(item: item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeIconFallback() {
    return Container(
      width: 30,
      height: 30,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.storefront, size: 16, color: Color(0xFF64748B)),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna 1: imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.productImageUrl,
              width: 74,
              height: 74,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 74,
                height: 74,
                color: const Color(0xFFE2E8F0),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Columna 2: nombre + precio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00796B),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Columna 3: cantidad editable
          Column(
            children: [
              _QtyButton(
                icon: Icons.add,
                onTap: () =>
                    cart.updateQuantity(item.branchId, item.productId, item.quantity + 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${item.quantity}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.remove,
                onTap: () =>
                    cart.updateQuantity(item.branchId, item.productId, item.quantity - 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0xFF00796B),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _DeliverySummaryCard extends StatelessWidget {
  const _DeliverySummaryCard({
    required this.deliveryLabel,
    required this.storeCount,
  });

  final String deliveryLabel;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.straighten, color: Color(0xFF00796B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrega en',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deliveryLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  storeCount > 1
                      ? 'Entregas desde $storeCount tiendas'
                      : 'Entrega desde 1 tienda',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.storeCount,
  });

  final double subtotal;
  final double shipping;
  final double total;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentRow(label: 'Productos', value: subtotal),
        const SizedBox(height: 8),
        _PaymentRow(
          label: storeCount > 1
              ? 'Costo de envio (x$storeCount tiendas)'
              : 'Costo de envio',
          value: shipping,
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        const SizedBox(height: 10),
        _PaymentRow(
          label: 'Total',
          value: total,
          strong: true,
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = strong ? const Color(0xFF0F172A) : const Color(0xFF334155);
    final size = strong ? 22.0 : 15.0;
    final weight = strong ? FontWeight.w800 : FontWeight.w500;
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: color, fontSize: size, fontWeight: weight)),
        const Spacer(),
        Text(
          'S/ ${value.toStringAsFixed(2)}',
          style: GoogleFonts.inter(color: color, fontSize: size, fontWeight: weight),
        ),
      ],
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 42,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu carrito esta esperando por deliciosos platos',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
