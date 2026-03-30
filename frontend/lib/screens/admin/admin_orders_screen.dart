import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
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
      final orders = await ApiService.adminGetAllOrders();
      // Fix #1: explicit sort instead of cascade mutation
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(Order order) async {
    // Fix #2: block updates on terminal statuses
    if (order.status == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed orders cannot be changed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    const statuses = ['pending', 'paid', 'shipped', 'completed'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusPicker(
        currentStatus: order.status,
        statuses: statuses,
      ),
    );
    if (selected == null || selected == order.status) return;
    try {
      final updated = await ApiService.adminUpdateOrderStatus(order.id, selected);
      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) setState(() => _orders[idx] = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to "$selected"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Orders (${_orders.length})')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _AdminOrderTile(
            order: _orders[i],
            onUpdateStatus: () => _updateStatus(_orders[i]),
          ),
        ),
      ),
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────
class _AdminOrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback onUpdateStatus;

  const _AdminOrderTile({required this.order, required this.onUpdateStatus});

  // Fix #2: terminal statuses disable the update button
  bool get _isTerminal => order.status == 'completed';

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8)
        : order.id;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: ID + status ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#…$shortId',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),

            // ── Date + total ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy · HH:mm').format(order.createdAt),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                Text(
                  '\$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent),
                ),
              ],
            ),

            // Fix #4: null-safe address fields
            if (order.address != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        order.address!.addressLine,
                        order.address!.city,
                      ].where((s) => s.isNotEmpty).join(', '),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Update status button — dimmed for terminal statuses
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTerminal ? null : onUpdateStatus,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(_isTerminal ? 'Order Finalised' : 'Update Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  _isTerminal ? cs.onSurface.withValues(alpha: 0.4) : AppTheme.accent,
                  side: BorderSide(
                    color: _isTerminal
                        ? cs.onSurface.withValues(alpha: 0.2)
                        : AppTheme.accent,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status picker bottom sheet ────────────────────────────────────────────────
class _StatusPicker extends StatelessWidget {
  final String currentStatus;
  final List<String> statuses;

  const _StatusPicker({
    required this.currentStatus,
    required this.statuses,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return AppTheme.success;
      case 'shipped':   return AppTheme.warning;
      case 'paid':      return AppTheme.accent;
      default:          return const Color(0xFF888899); // pending
    }
  }

  // Fix #5: safe capitalisation for any status string including multi-word
  String _label(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Update Order Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...statuses.map((s) {
            final isCurrent = s == currentStatus;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _statusColor(s).withValues(alpha: isCurrent ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.circle, size: 10, color: _statusColor(s)),
              ),
              title: Text(
                _label(s),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? _statusColor(s)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              trailing: isCurrent
                  ? const Icon(Icons.check_circle, color: AppTheme.accent, size: 20)
                  : null,
              // Fix #3: current status tile is not tappable
              onTap: isCurrent ? null : () => Navigator.pop(context, s),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}