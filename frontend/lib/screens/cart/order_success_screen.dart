import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../account/orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8)
        : order.id;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF22C55E), size: 48),
              ),
              const SizedBox(height: 28),
              const Text('Order placed!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 10),
              Text(
                'Your order has been placed\nand is being processed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 32),

              // Order card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _Row('Order ID', '#…$shortId'),
                      const SizedBox(height: 10),
                      _Row('Total',
                          '\$${order.totalPrice.toStringAsFixed(2)}',
                          valueStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F6EF7))),
                      const SizedBox(height: 10),
                      _Row('Status', '', badge: OrderStatusBadge(status: order.status)),
                      if (order.address != null) ...[
                        const SizedBox(height: 10),
                        _Row('Delivery', order.address!.display),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'View Orders',
                icon: Icons.receipt_long_outlined,
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  (r) => r.isFirst,
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continue Shopping',
                outlined: true,
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? badge;

  const _Row(this.label, this.value, {this.valueStyle, this.badge});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      badge ?? Text(value,
          style: valueStyle ??
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}
