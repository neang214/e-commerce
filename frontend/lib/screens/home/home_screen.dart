import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../products/product_detail_screen.dart';
import '../products/product_list_screen.dart';
import '../products/search_screen.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _featured = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<CartProvider>().fetch();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getCategories(),
      ]);
      setState(() {
        _featured = (results[0] as List<Product>).take(6).toList();
        _categories = results[1] as List<Category>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.watch<AuthProvider>().user;
    final cs   = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('What are you looking for?',
                style: TextStyle(fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Search bar
                      _SearchBar(onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()))),
                      const SizedBox(height: 24),

                      // Banner
                      _HeroBanner(onShop: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProductListScreen()))),
                      const SizedBox(height: 28),

                      // Categories
                      SectionHeader(
                        title: 'Categories',
                        action: 'See all',
                        onAction: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProductListScreen())),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => CategoryChip(
                            label: _categories[i].name,
                            selected: false,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    ProductListScreen(initialCategory: _categories[i]))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Featured
                      SectionHeader(
                        title: 'Featured',
                        action: 'See all',
                        onAction: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProductListScreen())),
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _featured.length,
                        itemBuilder: (_, i) => ProductCard(
                          product: _featured[i],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  ProductDetailScreen(product: _featured[i]))),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Text('Search products…',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onShop;
  const _HeroBanner({required this.onShop});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4F6EF7), Color(0xFF7B8FFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New arrivals\nthis week',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onShop,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Shop now',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F6EF7))),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.local_offer_rounded, size: 72, color: Colors.white24),
      ],
    ),
  );
}
