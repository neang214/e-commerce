import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().add(widget.product.id, _qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p  = widget.product;
    final cs = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final outOfStock = p.stock == 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image app bar
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            actions: [
              CartBadge(
                count: cart.itemCount,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: p.image != null
                  ? CachedNetworkImage(
                      imageUrl: '${ApiService.imageBaseUrl}/${p.image!.replaceFirst(RegExp(r'^/'), '')}',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.image_outlined, size: 64,
                            color: cs.onSurface.withValues(alpha: 0.2)),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined, size: 64,
                          color: cs.onSurface.withValues(alpha: 0.2)),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (p.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF1FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p.category!.name,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F6EF7))),
                        )
                      else
                        const SizedBox(),
                      if (outOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Out of stock',
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                        )
                      else
                        Text('${p.stock} in stock',
                            style: TextStyle(fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 10),
                  Text('\$${p.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F6EF7))),
                  const SizedBox(height: 20),

                  // Description
                  if (p.description.isNotEmpty) ...[
                    const Text('Description',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(p.description,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: cs.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 24),
                  ],

                  // Qty selector
                  if (!outOfStock) ...[
                    const Text('Quantity',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    QuantitySelector(
                      value: _qty,
                      max: p.stock,
                      onChanged: (v) => setState(() => _qty = v),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Add to cart
                  AppButton(
                    label: outOfStock ? 'Out of Stock' : 'Add to Cart',
                    onTap: outOfStock ? null : _addToCart,
                    loading: _adding,
                    icon: outOfStock ? null : Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Total preview
                  if (!outOfStock)
                    Center(
                      child: Text(
                        'Total: \$${(p.price * _qty).toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
