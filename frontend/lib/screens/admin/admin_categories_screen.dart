import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await ApiService.getCategories();
      setState(() => _categories = cats);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = 'Category name is required');
      return;
    }
    setState(() { _saving = true; _formError = null; });
    try {
      await ApiService.adminCreateCategory(name);
      _nameCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" added'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _formError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
            'Delete "${cat.name}"? Products in this category won\'t be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminDeleteCategory(cat.id);
      setState(() => _categories.removeWhere((c) => c.id == cat.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${cat.name}" deleted'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Categories (${_categories.length})')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Add category form
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('New Category',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addCategory(),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Electronics',
                                  prefixIcon: Icon(Icons.category_outlined,
                                      size: 20),
                                ),
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 8),
                                Text(_formError!,
                                    style: const TextStyle(
                                        color: AppTheme.danger, fontSize: 12)),
                              ],
                              const SizedBox(height: 12),
                              AppButton(
                                label: 'Add Category',
                                loading: _saving,
                                onTap: _addCategory,
                                icon: Icons.add_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_categories.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No categories yet',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        )
                      else
                        ...  _categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CategoryTile(
                            category: cat,
                            onDelete: () => _deleteCategory(cat),
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;

  const _CategoryTile({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.category_rounded,
              color: AppTheme.accent, size: 20),
        ),
        title: Text(category.name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: AppTheme.danger, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
