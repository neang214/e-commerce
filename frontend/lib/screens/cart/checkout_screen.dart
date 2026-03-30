import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> _addresses = [];
  Address? _selected;
  String _payMethod = 'Cash';
  bool _loadingAddresses = true;
  bool _placing = false;
  String? _error;

  // New address form
  final _phone  = TextEditingController();
  final _addr   = TextEditingController();
  final _city   = TextEditingController();
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final list = await ApiService.getAddresses();
      setState(() {
        _addresses = list;
        if (list.isNotEmpty) _selected = list.first;
      });
    } catch (_) {} finally {
      setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_phone.text.isEmpty || _addr.text.isEmpty || _city.text.isEmpty) return;
    final a = await ApiService.createAddress(_phone.text.trim(), _addr.text.trim(), _city.text.trim());
    setState(() {
      _addresses.add(a);
      _selected = a;
      _showForm = false;
      _phone.clear(); _addr.clear(); _city.clear();
    });
  }

  Future<void> _placeOrder() async {
    if (_selected == null) {
      setState(() => _error = 'Please select a delivery address');
      return;
    }
    setState(() { _placing = true; _error = null; });
    try {
      final order = await ApiService.createOrder(_selected!.id);
      await ApiService.pay(order.id, _payMethod);
      if (!mounted) return;
      context.read<CartProvider>().clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (r) => r.isFirst,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose(); _addr.dispose(); _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Delivery address ──────────────────────────────────────────
            const Text('Delivery address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_loadingAddresses)
              const Center(child: CircularProgressIndicator())
            else ...[
              ..._addresses.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AddressCard(
                  address: a,
                  selected: _selected?.id == a.id,
                  onTap: () => setState(() => _selected = a),
                ),
              )),
              if (!_showForm)
                AppButton(
                  label: '+ Add new address',
                  outlined: true,
                  onTap: () => setState(() => _showForm = true),
                )
              else
                _AddressForm(
                  phone: _phone,
                  addr: _addr,
                  city: _city,
                  onSave: _saveAddress,
                  onCancel: () => setState(() => _showForm = false),
                ),
            ],

            const SizedBox(height: 28),

            // ── Payment method ────────────────────────────────────────────
            const Text('Payment method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[('Cash', Icons.payments_outlined),
                ('ABA', Icons.account_balance_outlined),
                ('Stripe', Icons.credit_card_outlined)]
                .map((e) => _PayOption(
                  label: e.$1,
                  icon: e.$2,
                  selected: _payMethod == e.$1,
                  onTap: () => setState(() => _payMethod = e.$1),
                )),

            const SizedBox(height: 28),

            // ── Order summary ─────────────────────────────────────────────
            const Text('Order summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.product.name} × ${item.quantity}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis)),
                          Text('\$${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('\$${cart.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: Color(0xFF4F6EF7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ),
            ],

            const SizedBox(height: 24),
            AppButton(
              label: 'Place Order · \$${cart.total.toStringAsFixed(2)}',
              onTap: _placeOrder,
              loading: _placing,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayOption({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF4F6EF7) : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
        color: selected ? const Color(0xFFEEF1FE) : Theme.of(context).cardColor,
      ),
      child: Row(children: [
        Icon(icon, size: 20,
            color: selected ? const Color(0xFF4F6EF7) : Theme.of(context).disabledColor),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF4F6EF7) : null)),
        const Spacer(),
        if (selected)
          const Icon(Icons.check_circle, color: Color(0xFF4F6EF7), size: 18),
      ]),
    ),
  );
}

class _AddressForm extends StatelessWidget {
  final TextEditingController phone, addr, city;
  final VoidCallback onSave, onCancel;

  const _AddressForm({
    required this.phone, required this.addr, required this.city,
    required this.onSave, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number')),
          const SizedBox(height: 10),
          TextField(controller: addr,
              decoration: const InputDecoration(hintText: 'Street address')),
          const SizedBox(height: 10),
          TextField(controller: city,
              decoration: const InputDecoration(hintText: 'City')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: AppButton(label: 'Save', onTap: onSave)),
            const SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Cancel', outlined: true, onTap: onCancel)),
          ]),
        ],
      ),
    ),
  );
}
