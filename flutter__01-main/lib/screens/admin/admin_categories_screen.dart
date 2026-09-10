import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/category_model.dart';
import '../../data/services/category_service.dart';

/// Íconos lógicos soportados (deben coincidir con el mapeo real de
/// `CategoryChip._iconForCategory`).
const _iconOptions = <String, IconData>{
  'adventure': Icons.explore_rounded,
  'fantasy': Icons.auto_awesome_rounded,
  'animals': Icons.pets_rounded,
  'science': Icons.science_rounded,
  'values': Icons.favorite_rounded,
  'classic': Icons.castle_rounded,
  'space': Icons.rocket_launch_rounded,
  'ocean': Icons.water_rounded,
};

const _colorOptions = <String>[
  '#4A6FE5', '#9B5DE5', '#06D6A0', '#FF9F1C', '#FF6B6B', '#4ECDC4',
];

/// Gestión de categorías infantiles: crear, editar y eliminar.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _service = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar las categorías: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({CategoryModel? category}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Se eliminará "${category.nombre}". Los libros de esta categoría '
          'quedarán sin categoría asignada.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(category.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva categoría'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator()
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _load)
                : _categories.isEmpty
                    ? const AppEmptyState(message: 'Todavía no hay categorías.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final color = _parseColor(category.colorHex);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  _iconOptions[category.icono] ??
                                      Icons.menu_book_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(category.nombre),
                              subtitle: category.descripcion != null
                                  ? Text(category.descripcion!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () =>
                                        _openForm(category: category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        color: AppColors.error),
                                    onPressed: () => _confirmDelete(category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final parsed = int.tryParse('FF$clean', radix: 16);
    return parsed != null ? Color(parsed) : AppColors.accentPurple;
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = CategoryService();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  String _icono = _iconOptions.keys.first;
  String _color = _colorOptions.first;
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.category?.nombre ?? '');
    _descripcionController =
        TextEditingController(text: widget.category?.descripcion ?? '');
    _icono = widget.category?.icono ?? _iconOptions.keys.first;
    _color = widget.category?.colorHex ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final category = CategoryModel(
        id: widget.category?.id ?? '',
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        icono: _icono,
        colorHex: _color,
      );
      if (_isEditing) {
        await _service.update(category);
      } else {
        await _service.create(category);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar categoría' : 'Nueva categoría'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nombreController,
                label: 'Nombre',
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descripcionController,
                label: 'Descripción',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _icono,
                decoration: const InputDecoration(labelText: 'Ícono'),
                items: _iconOptions.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value, size: 18),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _icono = value ?? _icono),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _colorOptions.map((hex) {
                  final clean = hex.replaceFirst('#', '');
                  final color = Color(int.parse('FF$clean', radix: 16));
                  final selected = _color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
