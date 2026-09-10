import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/book_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/book_service.dart';
import '../../data/services/category_service.dart';
import '../../data/services/storage_service.dart';

/// Formulario de creación/edición de libro para el panel de
/// administrador. Si [book] llega como `extra` de la ruta, se abre en
/// modo edición; si no, en modo creación.
class AdminBookFormScreen extends StatefulWidget {
  final BookModel? book;
  const AdminBookFormScreen({super.key, this.book});

  @override
  State<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends State<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = BookService();
  final _categoryService = CategoryService();
  final _storageService = StorageService();

  late final TextEditingController _tituloController;
  late final TextEditingController _autorController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _sinopsisController;
  late final TextEditingController _idiomaController;
  late final TextEditingController _numeroPaginasController;
  late final TextEditingController _fuenteController;
  late final TextEditingController _anioController;
  late final TextEditingController _costoCreditosController;

  String? _categoriaId;
  String _edadRecomendada = AppConstants.ageRanges.first;
  bool _destacado = false;
  bool _publicado = true;
  bool _esVip = false;

  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  PlatformFile? _pickedCover;
  PlatformFile? _pickedPdf;
  String? _existingCoverUrl;
  String? _existingPdfUrl;

  bool get _isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _tituloController = TextEditingController(text: book?.titulo ?? '');
    _autorController = TextEditingController(text: book?.autor ?? '');
    _descripcionController =
        TextEditingController(text: book?.descripcion ?? '');
    _sinopsisController = TextEditingController(text: book?.sinopsis ?? '');
    _idiomaController = TextEditingController(text: book?.idioma ?? 'es');
    _numeroPaginasController =
        TextEditingController(text: book?.numeroPaginas?.toString() ?? '');
    _fuenteController =
        TextEditingController(text: book?.fuenteDominioPublico ?? '');
    _anioController = TextEditingController(
        text: book?.anioPublicacionOriginal?.toString() ?? '');
    _costoCreditosController =
        TextEditingController(text: book?.costoCreditos.toString() ?? '0');

    _categoriaId = book?.categoriaId;
    _edadRecomendada = book?.edadRecomendada ?? AppConstants.ageRanges.first;
    _destacado = book?.destacado ?? false;
    _publicado = book?.publicado ?? true;
    _esVip = book?.esVip ?? false;
    _existingCoverUrl = book?.portadaUrl;
    _existingPdfUrl = book?.archivoPdfUrl;

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    _descripcionController.dispose();
    _sinopsisController.dispose();
    _idiomaController.dispose();
    _numeroPaginasController.dispose();
    _fuenteController.dispose();
    _anioController.dispose();
    _costoCreditosController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.lengthInBytes > 5 * 1024 * 1024) {
      _showSnack('La portada no puede superar 5 MB.');
      return;
    }
    setState(() => _pickedCover = file);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.lengthInBytes > 50 * 1024 * 1024) {
      _showSnack('El PDF no puede superar 50 MB.');
      return;
    }
    setState(() => _pickedPdf = file);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_existingPdfUrl == null && _pickedPdf == null) {
      _showSnack('Debes seleccionar el archivo PDF del libro.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      var portadaUrl = _existingCoverUrl;
      var pdfUrl = _existingPdfUrl ?? '';

      if (_pickedCover != null) {
        portadaUrl = await _storageService.uploadBookCover(
          bytes: _pickedCover!.bytes!,
          originalFileName: _pickedCover!.name,
        );
      }
      if (_pickedPdf != null) {
        pdfUrl = await _storageService.uploadBookFile(
          bytes: _pickedPdf!.bytes!,
          originalFileName: _pickedPdf!.name,
        );
      }

      final numeroPaginas = int.tryParse(_numeroPaginasController.text.trim());
      final anio = int.tryParse(_anioController.text.trim());
      final costoCreditos =
          int.tryParse(_costoCreditosController.text.trim()) ?? 0;

      final payload = BookModel(
        id: widget.book?.id ?? '',
        titulo: _tituloController.text.trim(),
        autor: _autorController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        sinopsis: _sinopsisController.text.trim().isEmpty
            ? null
            : _sinopsisController.text.trim(),
        categoriaId: _categoriaId,
        edadRecomendada: _edadRecomendada,
        idioma: _idiomaController.text.trim().isEmpty
            ? 'es'
            : _idiomaController.text.trim(),
        portadaUrl: portadaUrl,
        archivoPdfUrl: pdfUrl,
        numeroPaginas: numeroPaginas,
        destacado: _destacado,
        publicado: _publicado,
        fuenteDominioPublico: _fuenteController.text.trim().isEmpty
            ? null
            : _fuenteController.text.trim(),
        anioPublicacionOriginal: anio,
        esVip: _esVip,
        costoCreditos: _esVip ? (costoCreditos < 1 ? 1 : costoCreditos) : 0,
        creadoEn: widget.book?.creadoEn ?? DateTime.now(),
      );

      if (_isEditing) {
        await _bookService.update(payload);
      } else {
        await _bookService.create(payload);
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar libro' : 'Nuevo libro')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilePickerRow(
                      label: 'Portada',
                      pickedName: _pickedCover?.name,
                      existingUrl: _existingCoverUrl,
                      onPick: _pickCover,
                      previewBytes: _pickedCover?.bytes,
                    ),
                    const SizedBox(height: 12),
                    _buildFilePickerRow(
                      label: 'Archivo PDF',
                      pickedName: _pickedPdf?.name,
                      existingUrl: _existingPdfUrl,
                      onPick: _pickPdf,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _tituloController,
                      label: 'Título',
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _autorController,
                      label: 'Autor',
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _descripcionController,
                      label: 'Descripción',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _sinopsisController,
                      label: 'Sinopsis',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _isLoadingCategories
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String?>(
                            value: _categoriaId,
                            decoration:
                                const InputDecoration(labelText: 'Categoría'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Sin categoría'),
                              ),
                              ..._categories.map(
                                (category) => DropdownMenuItem<String?>(
                                  value: category.id,
                                  child: Text(category.nombre),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _categoriaId = value),
                          ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _edadRecomendada,
                      decoration:
                          const InputDecoration(labelText: 'Edad recomendada'),
                      items: AppConstants.ageRanges
                          .map((edad) => DropdownMenuItem(
                                value: edad,
                                child: Text('$edad años'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(
                          () => _edadRecomendada = value ?? _edadRecomendada),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _idiomaController,
                            label: 'Idioma',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _numeroPaginasController,
                            label: 'N.º de páginas',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _fuenteController,
                      label: 'Fuente (dominio público)',
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _anioController,
                      label: 'Año de publicación original',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final year = int.tryParse(text);
                        if (year == null || text.length != 4) {
                          return 'Debe tener 4 dígitos.';
                        }
                        if (year > 2027) return 'No puede ser mayor a 2027.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _destacado,
                      onChanged: (v) => setState(() => _destacado = v),
                      title: const Text('Destacado'),
                      subtitle: const Text(
                          'Se usa como respaldo si aún no hay suficiente popularidad real.'),
                    ),
                    SwitchListTile(
                      value: _publicado,
                      onChanged: (v) => setState(() => _publicado = v),
                      title: const Text('Publicado'),
                      subtitle: const Text('Visible para los usuarios.'),
                    ),
                    SwitchListTile(
                      value: _esVip,
                      onChanged: (v) => setState(() => _esVip = v),
                      title: const Text('Libro VIP'),
                      subtitle: const Text(
                          'Requiere canjear créditos para desbloquearse.'),
                    ),
                    if (_esVip)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AppTextField(
                          controller: _costoCreditosController,
                          label: 'Costo en créditos',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (!_esVip) return null;
                            final value = int.tryParse(v?.trim() ?? '');
                            if (value == null || value < 1) {
                              return 'Debe ser al menos 1 crédito.';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _isEditing ? 'Guardar cambios' : 'Crear libro',
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerRow({
    required String label,
    required String? pickedName,
    required String? existingUrl,
    required VoidCallback onPick,
    Uint8List? previewBytes,
  }) {
    final hasFile = pickedName != null || (existingUrl?.isNotEmpty ?? false);
    return Card(
      color: AppColors.lightSurfaceVariant.withOpacity(0.4),
      child: ListTile(
        leading: previewBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(previewBytes,
                    width: 40, height: 52, fit: BoxFit.cover),
              )
            : const Icon(Icons.attach_file_rounded),
        title: Text(label),
        subtitle: Text(
          pickedName ??
              (hasFile ? 'Archivo actual (sin cambios)' : 'Ningún archivo seleccionado'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onPick,
          child: Text(hasFile ? 'Cambiar' : 'Elegir'),
        ),
      ),
    );
  }
}
