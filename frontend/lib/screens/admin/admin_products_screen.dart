import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  // FIX: When true (from "Add New Product" quick action), opens the form immediately
  final bool openAddOnLoad;
  const AdminProductsScreen({super.key, this.openAddOnLoad = false});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // FIX: Auto-open the add product form when navigated from quick action
    if (widget.openAddOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openProductForm());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getCategories(),
      ]);
      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminDeleteProduct(p.id);
      setState(() => _products.removeWhere((x) => x.id == p.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${p.name}" deleted'),
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

  void _openProductForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
        product: product,
        categories: _categories,
        onSaved: (_) {
          _load();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products (${_products.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add product',
            onPressed: () => _openProductForm(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : RefreshIndicator(
        onRefresh: _load,
        child: _products.isEmpty
            ? const Center(child: Text('No products yet'))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
          itemBuilder: (_, i) => _ProductTile(
            product: _products[i],
            onEdit: () =>
                _openProductForm(product: _products[i]),
            onDelete: () => _deleteProduct(_products[i]),
          ),
        ),
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: product.image != null
                    ? CachedNetworkImage(
                  imageUrl:
                  '${ApiService.imageBaseUrl}/${product.image!.replaceFirst(RegExp(r'^/'), '')}',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    child:
                    const Icon(Icons.image_outlined, size: 24),
                  ),
                )
                    : Container(
                  color: cs.surfaceContainerHighest,
                  child:
                  const Icon(Icons.image_outlined, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? AppTheme.successLight
                          : AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.stock > 0
                          ? 'Stock: ${product.stock}'
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: product.stock > 0
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: AppTheme.accent),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.danger),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit product bottom sheet ──────────────────────────────────────────
class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final void Function(dynamic) onSaved;

  const _ProductFormSheet({
    this.product,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;

  String? _selectedCategoryId;
  String? _existingImagePath;
  File? _pickedImageFile;
  bool _uploadingImage = false;
  bool _saving = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? '${p.price}' : '');
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '');
    _existingImagePath = p?.image;
    _selectedCategoryId = p?.category?.id ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  // ── Request camera permission ─────────────────────────────────────────────
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera access is permanently denied. '
                  'Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (open == true) await openAppSettings();
      }
      return false;
    }
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  // ── Request gallery permission ────────────────────────────────────────────
  Future<bool> _requestGalleryPermission() async {
    final permission = Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Gallery Permission Required'),
            content: const Text(
              'Photo library access is permanently denied. '
                  'Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (open == true) await openAppSettings();
      }
      return false;
    }
    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }

  void _showPermissionDenied(String source) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$source permission denied'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  // ── Pick image ────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null) return;

    bool granted = false;
    if (source == ImageSource.camera) {
      granted = await _requestCameraPermission();
      if (!granted) {
        _showPermissionDenied('Camera');
        return;
      }
    } else {
      granted = await _requestGalleryPermission();
      if (!granted) {
        _showPermissionDenied('Gallery');
        return;
      }
    }

    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (xfile == null) return;

      setState(() {
        _pickedImageFile = File(xfile.path);
        _existingImagePath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to pick image: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
      _existingImagePath = null;
    });
  }

  // ── Save product ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _price.text.trim().isEmpty) {
      setState(() => _error = 'Name and price are required');
      return;
    }

    final parsedPrice = double.tryParse(_price.text.trim());
    if (parsedPrice == null) {
      setState(() => _error = 'Please enter a valid price');
      return;
    }

    // ✅ Keep this: Capturing the reference prevents loss during rebuild
    final fileToUpload = _pickedImageFile;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      String? finalImagePath = _existingImagePath;

      // 1. Upload image if a new one was picked
      if (fileToUpload != null) {
        setState(() => _uploadingImage = true);
        try {
          // This returns the "uploads/filename.jpg" string from your server
          finalImagePath = await ApiService.uploadImage(fileToUpload.path);
        } finally {
          if (mounted) setState(() => _uploadingImage = false);
        }
      }

      // 2. Build product body
      // Match these keys EXACTLY to your MongoDB Schema / Controller
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': parsedPrice,
        'stock': int.tryParse(_stock.text.trim()) ?? 0,
        'image': finalImagePath ?? '', // Ensure this isn't null
        'category': _selectedCategoryId,
      };

      // 3. API Call
      if (widget.product == null) {
        final result = await ApiService.adminCreateProduct(body);
        widget.onSaved(result);
      } else {
        final result = await ApiService.adminUpdateProduct(widget.product!.id, body);
        widget.onSaved(result);
      }
      // Navigation is handled by the onSaved callback in _openProductForm.

    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isEdit ? 'Edit Product' : 'Add Product',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // ── Image picker ───────────────────────────────────────────
            const Text('Product Image',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ImagePickerWidget(
              pickedFile: _pickedImageFile,
              existingPath: _existingImagePath,
              uploading: _uploadingImage,
              onPick: _pickImage,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 16),

            // ── Text fields ────────────────────────────────────────────
            _Field(
                label: 'Product Name *',
                controller: _name,
                hint: 'e.g. Wireless Headphones'),
            const SizedBox(height: 12),
            _Field(
                label: 'Description',
                controller: _desc,
                hint: 'Product description',
                maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _Field(
                    label: 'Price *',
                    controller: _price,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                    label: 'Stock',
                    controller: _stock,
                    hint: '0',
                    keyboardType: TextInputType.number),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Category dropdown ──────────────────────────────────────
            if (widget.categories.isNotEmpty) ...[
              const Text('Category',
                  style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4F4F8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0))),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: widget.categories
                    .map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
            ],

            // ── Error ──────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.danger, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            AppButton(
              label: _uploadingImage
                  ? 'Uploading image…'
                  : (isEdit ? 'Save Changes' : 'Add Product'),
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image picker widget ───────────────────────────────────────────────────────
class _ImagePickerWidget extends StatelessWidget {
  final File? pickedFile;
  final String? existingPath;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerWidget({
    required this.pickedFile,
    required this.existingPath,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null || existingPath != null;

    return GestureDetector(
      onTap: uploading ? null : onPick,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage
                ? AppTheme.accent.withValues(alpha: 0.4)
                : const Color(0xFFE8E8F0),
            width: hasImage ? 2 : 1,
          ),
        ),
        child: uploading
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Uploading…',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        )
            : hasImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: pickedFile != null
                  ? Image.file(pickedFile!, fit: BoxFit.cover)
                  : CachedNetworkImage(
                imageUrl:
                '${ApiService.imageBaseUrl}/${existingPath!.replaceFirst(RegExp(r'^/'), '')}',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 40,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _OverlayBtn(
                      icon: Icons.edit_rounded, onTap: onPick),
                  const SizedBox(width: 6),
                  _OverlayBtn(
                    icon: Icons.delete_rounded,
                    color: AppTheme.danger,
                    onTap: onRemove,
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: AppTheme.accent, size: 26),
            ),
            const SizedBox(height: 10),
            const Text('Tap to pick image',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent)),
            const SizedBox(height: 4),
            const Text('From gallery or camera',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn({
    required this.icon,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

// ── Image source bottom sheet ─────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select Image Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.accent),
            ),
            title: const Text('Photo Library',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Pick from your gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppTheme.success),
            ),
            title: const Text('Camera',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Take a new photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Text field helper ─────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}