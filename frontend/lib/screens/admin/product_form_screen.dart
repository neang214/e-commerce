import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

/// Standalone screen version of the product form (used by some navigations).
/// Mirrors the inline _ProductFormSheet in admin_products_screen.dart.
class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // null = add, non-null = edit

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  String? _existingImagePath;
  File?   _pickedImageFile;

  bool _uploadingImage = false;
  bool _saving         = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl.text  = p?['name']        ?? '';
    _descCtrl.text  = p?['description'] ?? '';
    _priceCtrl.text = p?['price']?.toString() ?? '';
    // FIX: was 'countInStock' — correct field is 'stock'
    _stockCtrl.text = p?['stock']?.toString() ?? '';
    _existingImagePath = p?['image'];

    // Pre-select category if editing
    final cat = p?['category'];
    if (cat is Map) _selectedCategoryId = cat['_id']?.toString();

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        // Default selection for new products
        if (_selectedCategoryId == null && cats.isNotEmpty) {
          _selectedCategoryId = cats.first.id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => _SourceSheet(),
    );
    if (source == null) return;

    // Permission check
    bool granted = false;
    if (source == ImageSource.camera) {
      granted = (await Permission.camera.request()).isGranted;
    } else {
      final s = await Permission.photos.request();
      granted = s.isGranted || s.isLimited;
    }
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')));
      }
      return;
    }

    try {
      final xfile = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1200);
      if (xfile == null) return;
      setState(() {
        _pickedImageFile   = File(xfile.path);
        _existingImagePath = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removeImage() => setState(() {
    _pickedImageFile   = null;
    _existingImagePath = null;
  });

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null) {
      setState(() => _error = 'Name and a valid price are required');
      return;
    }

    final fileToUpload = _pickedImageFile;
    setState(() { _saving = true; _error = null; });

    try {
      String? finalImagePath = _existingImagePath;

      // FIX: Upload image if a new one was picked
      if (fileToUpload != null) {
        setState(() => _uploadingImage = true);
        try {
          finalImagePath = await ApiService.uploadImage(fileToUpload.path);
        } finally {
          if (mounted) setState(() => _uploadingImage = false);
        }
      }

      final body = <String, dynamic>{
        'name':        name,
        'description': _descCtrl.text.trim(),
        'price':       price,
        'stock':       int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'image':       finalImagePath ?? '',
        'category':    _selectedCategoryId,
      };

      final id = widget.product?['_id'] as String?;
      if (id == null) {
        await ApiService.adminCreateProduct(body);
      } else {
        await ApiService.adminUpdateProduct(id, body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(id == null ? 'Product created!' : 'Product updated!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final cs     = Theme.of(context).colorScheme;
    final hasImage = _pickedImageFile != null || _existingImagePath != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Image picker ─────────────────────────────────────────────────
          const Text('Product Image',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasImage
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                      : Theme.of(context).dividerColor,
                  width: hasImage ? 2 : 1,
                ),
              ),
              child: _uploadingImage
                  ? const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Uploading…'),
                      ],
                    ))
                  : hasImage
                      ? Stack(fit: StackFit.expand, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: _pickedImageFile != null
                                ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: '${ApiService.imageBaseUrl}/'
                                        '${_existingImagePath!.replaceFirst(RegExp(r'^/'), '')}',
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined, size: 40),
                                  ),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: Row(children: [
                              _OverlayBtn(icon: Icons.edit_rounded, onTap: _pickImage),
                              const SizedBox(width: 6),
                              _OverlayBtn(icon: Icons.delete_rounded,
                                  color: Colors.redAccent, onTap: _removeImage),
                            ]),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 36, color: cs.primary),
                            const SizedBox(height: 8),
                            Text('Tap to pick image',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, color: cs.primary)),
                            const SizedBox(height: 4),
                            Text('Gallery or camera',
                                style: TextStyle(fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Fields ───────────────────────────────────────────────────────
          _buildField('Product Name *', _nameCtrl, hint: 'e.g. Wireless Headphones'),
          const SizedBox(height: 12),
          _buildField('Description', _descCtrl, hint: 'Product description', maxLines: 3),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildField('Price *', _priceCtrl, hint: '0.00',
                keyboard: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _buildField('Stock', _stockCtrl, hint: '0',
                keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 12),

          // ── Category ────────────────────────────────────────────────────
          if (_categories.isNotEmpty) ...[
            const Text('Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ],

          // ── Error ────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_uploadingImage
                      ? 'Uploading image…'
                      : (isEdit ? 'Save Changes' : 'Add Product')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn(
      {required this.icon, this.color = Colors.white, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      );
}

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Photo Library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );
}
