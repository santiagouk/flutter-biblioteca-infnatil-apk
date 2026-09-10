import 'package:flutter/material.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/poem_model.dart';
import '../../data/services/poems_service.dart';

/// Lista de reportes de poemas enviados por la comunidad, visible
/// solo para admin/moderador (protegido además por RLS del lado del
/// servidor en `poem_reports`).
class AdminPoemReportsScreen extends StatefulWidget {
  const AdminPoemReportsScreen({super.key});

  @override
  State<AdminPoemReportsScreen> createState() =>
      _AdminPoemReportsScreenState();
}

class _AdminPoemReportsScreenState extends State<AdminPoemReportsScreen> {
  final _poemsService = PoemsService();
  List<PoemReportModel> _reports = [];
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
      final reports = await _poemsService.fetchReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible cargar los reportes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissReport(PoemReportModel report) async {
    try {
      await _poemsService.deleteReport(report.id);
      if (!mounted) return;
      setState(() => _reports = _reports.where((r) => r.id != report.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deletePoemAndReport(PoemReportModel report) async {
    try {
      await _poemsService.delete(report.poemaId);
      await _poemsService.deleteReport(report.id);
      if (!mounted) return;
      setState(() => _reports = _reports.where((r) => r.id != report.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poema eliminado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes del Foro de Poemas')),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator()
            : _errorMessage != null
                ? AppErrorState(message: _errorMessage!, onRetry: _load)
                : _reports.isEmpty
                    ? const AppEmptyState(
                        message: 'No hay reportes pendientes.',
                        icon: Icons.check_circle_outline_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Motivo del reporte',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    const SizedBox(height: 4),
                                    Text(report.motivo),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              _dismissReport(report),
                                          child: const Text('Descartar'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              _deletePoemAndReport(report),
                                          child: const Text('Eliminar poema'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
