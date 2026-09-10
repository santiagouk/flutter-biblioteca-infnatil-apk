import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poems_provider.dart';

/// Formulario para publicar un nuevo poema en el Foro de Poemas.
class PoemFormScreen extends StatefulWidget {
  const PoemFormScreen({super.key});

  @override
  State<PoemFormScreen> createState() => _PoemFormScreenState();
}

class _PoemFormScreenState extends State<PoemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  late final TextEditingController _autorController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final displayName =
        context.read<AuthProvider>().userProfile?.displayName ?? '';
    _autorController = TextEditingController(text: displayName);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final userId = context.read<AuthProvider>().userProfile?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    final ok = await context.read<PoemsProvider>().publish(
          userId: userId,
          titulo: _tituloController.text,
          contenido: _contenidoController.text,
          nombreAutor: _autorController.text,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      context.pop();
    } else {
      final error = context.read<PoemsProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No fue posible publicar tu poema.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar poema')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _tituloController,
                      label: 'Título',
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'El título es obligatorio.';
                        if (text.length > 150) {
                          return 'El título no puede superar 150 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _autorController,
                      label: 'Nombre del autor',
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'El nombre del autor es obligatorio.';
                        if (text.length > 100) {
                          return 'El nombre no puede superar 100 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _contenidoController,
                      label: 'Poema',
                      hint: 'Escribe tu poema aquí...',
                      maxLines: 10,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'El poema no puede estar vacío.';
                        if (text.length > 5000) {
                          return 'El poema no puede superar 5000 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Publicar',
                      icon: Icons.send_rounded,
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
}
