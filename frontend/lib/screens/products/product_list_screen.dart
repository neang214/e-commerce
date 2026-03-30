import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class ProductListScreen extends StatefulWidget {
  final Category? initialCategory;
  const ProductListScreen({super.key, this.initialCategory});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product>   _all        = [];
  List<Product>   _filtered   = [];
  List<Category>  _categories = [];
  Category?       _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getCategories(),
      ]);
      _all        = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _applyFilter();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _selected == null
          ? _all
          : _all.where((p) => p.category?.id == _selected!.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          CartBadge(
            count: cart.itemCount,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    // Category filter row
                    if (_categories.isNotEmpty)
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _categories.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return CategoryChip(
                                label: 'All',
                                selected: _selected == null,
                                onTap: () { setState(() => _selected = null); _applyFilter(); },
                              );
                            }
                            final cat = _categories[i - 1];
                            return CategoryChip(
                              label: cat.name,
                              selected: _selected?.id == cat.id,
                              onTap: () { setState(() => _selected = cat); _applyFilter(); },
                            );
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    // Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(children: [
                        Text('${_filtered.length} products',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ]),
                    ),
                    // Grid
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No products found'))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => ProductCard(
                                product: _filtered[i],
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        ProductDetailScreen(product: _filtered[i]))),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
