import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'admin_products_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  // FIX: Accept a callback so quick actions can switch tabs in AdminShell
  final void Function(int tabIndex)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // FIX: adminGetStats now hits the real /api/admin/stats endpoint
      final stats = await ApiService.adminGetStats();
      setState(() => _stats = stats);
    } catch (e) {
      setState(() {
        _stats = {};
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // FIX: Navigate to the correct bottom-nav tab instead of showing a snackbar
  void _goToTab(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    }
  }

  // FIX: "Add New Product" opens the product form sheet directly
  void _addNewProduct() {
    _goToTab(1); // switch to Products tab
    // After switching, show the add-product bottom sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminProductsScreen(openAddOnLoad: true),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name.split(' ').first ?? 'Admin'} 👋',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.accent),
            ),
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will be returned to the login screen.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: AppTheme.danger))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Admin badge card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: AppTheme.accent, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Administrator',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text(user?.email ?? '',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Active',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FIX: Show error banner if stats failed to load
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Could not load stats: $_error',
                              style: const TextStyle(
                                  color: AppTheme.danger, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry',
                                style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Text('Overview',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Stats grid — FIX: values now come from real API
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        label: 'Total Orders',
                        value: '${_stats?['totalOrders'] ?? '--'}',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.accent,
                        onTap: () => _goToTab(2),
                      ),
                      _StatCard(
                        label: 'Revenue',
                        value: _stats?['totalRevenue'] != null
                            ? '\$${(_stats!['totalRevenue'] as num).toStringAsFixed(0)}'
                            : '--',
                        icon: Icons.attach_money_rounded,
                        color: AppTheme.success,
                        onTap: () => _goToTab(2),
                      ),
                      _StatCard(
                        label: 'Products',
                        value: '${_stats?['totalProducts'] ?? '--'}',
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.warning,
                        onTap: () => _goToTab(1),
                      ),
                      _StatCard(
                        label: 'Users',
                        value: '${_stats?['totalUsers'] ?? '--'}',
                        icon: Icons.people_rounded,
                        color: const Color(0xFFEC4899),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Quick Actions',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // FIX: Quick actions now actually navigate instead of showing snackbars
                  _QuickAction(
                    icon: Icons.add_box_rounded,
                    label: 'Add New Product',
                    subtitle: 'Create a product listing',
                    color: AppTheme.accent,
                    onTap: () => _goToTab(1),
                  ),
                  const SizedBox(height: 10),
                  _QuickAction(
                    icon: Icons.local_shipping_rounded,
                    label: 'Manage Orders',
                    subtitle: 'Update order statuses',
                    color: AppTheme.success,
                    onTap: () => _goToTab(2),
                  ),
                  const SizedBox(height: 10),
                  _QuickAction(
                    icon: Icons.category_rounded,
                    label: 'Manage Categories',
                    subtitle: 'Add or remove categories',
                    color: AppTheme.warning,
                    onTap: () => _goToTab(3),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ── Stat card — tappable to navigate ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: color.withValues(alpha: 0.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action row ──────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).disabledColor),
          ],
        ),
      ),
    );
  }
}
