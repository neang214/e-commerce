import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> _addresses = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _showForm = false;

  final _phone = TextEditingController();
  final _addr  = TextEditingController();
  final _city  = TextEditingController();
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAddresses();
      setState(() => _addresses = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_phone.text.trim().isEmpty ||
        _addr.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _formError = 'All fields are required');
      return;
    }
    setState(() { _saving = true; _formError = null; });
    try {
      final a = await ApiService.createAddress(
        _phone.text.trim(),
        _addr.text.trim(),
        _city.text.trim(),
      );
      setState(() {
        _addresses.add(a);
        _showForm = false;
        _phone.clear(); _addr.clear(); _city.clear();
      });
    } catch (e) {
      setState(() => _formError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose(); _addr.dispose(); _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        actions: [
          if (!_showForm)
            TextButton.icon(
              onPressed: () => setState(() { _showForm = true; _formError = null; }),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Add form
                    if (_showForm) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('New address',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _addr,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Street address',
                                  prefixIcon: Icon(Icons.home_outlined, size: 18),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _city,
                                textInputAction: TextInputAction.done,
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _save(),
                                decoration: const InputDecoration(
                                  hintText: 'City',
                                  prefixIcon: Icon(Icons.location_city_outlined, size: 18),
                                ),
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_formError!,
                                      style: const TextStyle(
                                          color: Color(0xFFEF4444), fontSize: 12)),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Save Address',
                                    loading: _saving,
                                    onTap: _save,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppButton(
                                    label: 'Cancel',
                                    outlined: true,
                                    onTap: () => setState(() {
                                      _showForm = false;
                                      _formError = null;
                                      _phone.clear(); _addr.clear(); _city.clear();
                                    }),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Address list
                    if (_addresses.isEmpty && !_showForm)
                      _EmptyAddresses(
                        onAdd: () => setState(() => _showForm = true),
                      )
                    else
                      ..._addresses.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AddressTile(
                          address: e.value,
                          index: e.key + 1,
                        ),
                      )),
                  ],
                ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final int index;

  const _AddressTile({required this.address, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF1FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F6EF7))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.addressLine,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(address.city,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.phone_outlined, size: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(address.phone,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.4))),
                  ]),
                ],
              ),
            ),
            Icon(Icons.location_on_outlined,
                color: const Color(0xFF4F6EF7).withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.location_off_outlined, size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        const Text('No addresses yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Add a delivery address to get started',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 24),
        AppButton(
          label: 'Add Address',
          icon: Icons.add,
          onTap: onAdd,
        ),
      ],
    ),
  );
}
