import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_placeholders.dart';
import '../../data/models/book_model.dart';
import '../../data/services/book_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credits_provider.dart';
import '../../providers/reading_activity_provider.dart';
import '../../widgets/vip/vip_lock_card.dart';

/// Pantalla de lectura dentro de la app.
///
/// El catálogo real solo maneja libros en PDF (columna
/// `archivo_pdf_url`), por lo que esta pantalla usa
/// `syncfusion_flutter_pdfviewer` para renderizar el PDF directamente
/// (funciona igual en Web, Android e iOS, a diferencia del enfoque
/// anterior con WebView + Google Docs Viewer, que no tiene
/// implementación web sin el paquete adicional `webview_flutter_web`
/// y por eso la lectura se quedaba en blanco).
///
/// El PDF se descarga primero con el paquete `http` (en lugar de
/// dejar que `SfPdfViewer.network()` lo descargue internamente) y se
/// muestra con `SfPdfViewer.memory()`. Esto es a propósito: si la
/// descarga falla, `http` nos da el código de estado HTTP real y el
/// mensaje del servidor, mientras que `SfPdfViewer.network()` solo
/// reporta un mensaje genérico ("There was an error opening this
/// document.") sin decir si el problema es CORS, un 403/404, o falta
/// de conexión — algo indispensable para diagnosticar bien.
///
/// El progreso de lectura se guarda automáticamente en
/// `reading_history` cada vez que el usuario cambia de página, y
/// también al salir de la pantalla.
class ReaderScreen extends StatefulWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final BookService _bookService = BookService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  BookModel? _book;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isVipLocked = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final book = await _bookService.fetchById(widget.bookId);
      if (book.archivoPdfUrl.isEmpty) {
        throw Exception('Este libro no tiene un archivo PDF asignado.');
      }

      var vipLocked = false;
      if (book.esVip && mounted) {
        final userId = context.read<AuthProvider>().userProfile?.id;
        if (userId != null) {
          vipLocked = !await context
              .read<CreditsProvider>()
              .isBookUnlocked(userId: userId, bookId: book.id);
        }
      }

      // Si está bloqueado por VIP no hace falta descargar el PDF: se
      // muestra la tarjeta de canje y listo.
      Uint8List? bytes;
      if (!vipLocked) {
        bytes = await _downloadPdfBytes(book.archivoPdfUrl);
      }

      if (!mounted) return;
      setState(() {
        _book = book;
        _pdfBytes = bytes;
        _isVipLocked = vipLocked;
        try {
          _currentPage =
              context.read<ReadingActivityProvider>().lastPageFor(book.id);
        } catch (_) {
          _currentPage = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Descarga el PDF con `http` en lugar de dejárselo a
  /// `SfPdfViewer.network()`, para poder mostrar el código de estado
  /// y el mensaje reales si algo falla (403, 404, CORS, sin
  /// conexión...) en vez del mensaje genérico del visor.
  Future<Uint8List> _downloadPdfBytes(String url) async {
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw Exception(
        'No fue posible conectarse para descargar el PDF. Verifica tu '
        'conexión a internet. Detalle técnico: $e',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'El servidor rechazó la descarga del PDF '
        '(código ${response.statusCode}). Esto suele significar que el '
        'archivo no existe en el bucket "libros-pdf" o que la URL '
        'guardada para este libro es incorrecta.',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('pdf') &&
        !contentType.contains('octet-stream') &&
        response.bodyBytes.length > 5 &&
        String.fromCharCodes(response.bodyBytes.take(5)) != '%PDF-') {
      throw Exception(
        'El archivo descargado no es un PDF válido (Content-Type: '
        '"$contentType"). Puede que el enlace guardado para este libro '
        'esté dañado o apunte a otro tipo de archivo.',
      );
    }

    return response.bodyBytes;
  }

  Future<void> _handleRedeem() async {
    final book = _book;
    final userId = context.read<AuthProvider>().userProfile?.id;
    if (book == null || userId == null) return;

    final result =
        await context.read<CreditsProvider>().redeemVipBook(bookId: book.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.mensaje)),
    );

    if (result.exito) {
      await context.read<AuthProvider>().refreshProfile();
      if (!mounted) return;
      try {
        final bytes = await _downloadPdfBytes(book.archivoPdfUrl);
        if (!mounted) return;
        setState(() {
          _pdfBytes = bytes;
          _isVipLocked = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isVipLocked = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _saveProgress(int page) {
    final userId = context.read<AuthProvider>().userProfile?.id;
    final book = _book;
    if (userId == null || book == null || page <= 0) return;
    context.read<ReadingActivityProvider>().saveReadingProgress(
          userId: userId,
          bookId: book.id,
          lastPageRead: page,
          totalPages: _totalPages > 0 ? _totalPages : book.numeroPaginas ?? 0,
        );
  }

  Future<void> _showSearchDialog() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar en el libro'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe una palabra...'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    if (query == null || query.trim().isEmpty || !mounted) return;
    _searchResult = _pdfViewerController.searchText(query.trim());
    setState(() {});
  }

  @override
  void dispose() {
    if (_currentPage > 0 && !_isVipLocked) {
      _saveProgress(_currentPage);
    }
    _searchResult.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: AppLoadingIndicator(message: 'Abriendo libro...'),
      );
    }
    if (_errorMessage != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
        ),
        body: AppErrorState(
          message: _errorMessage ?? 'Libro no encontrado.',
          onRetry: _loadBook,
        ),
      );
    }

    final book = _book!;
    final pdfBytes = _pdfBytes;

    if (_isVipLocked) {
      final creditos = context.watch<AuthProvider>().userProfile?.creditos ?? 0;
      return Scaffold(
        appBar: AppBar(
          title: Text(book.titulo, overflow: TextOverflow.ellipsis),
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: VipLockCard(
              book: book,
              creditosDisponibles: creditos,
              onRedeem: _handleRedeem,
            ),
          ),
        ),
      );
    }

    if (pdfBytes == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
        ),
        body: AppErrorState(
          message: 'No fue posible preparar el PDF de este libro.',
          onRetry: _loadBook,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.titulo, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar en el libro',
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'Acercar',
            onPressed: () => _pdfViewerController.zoomLevel =
                (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            tooltip: 'Alejar',
            onPressed: () => _pdfViewerController.zoomLevel =
                (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          if (_searchResult.hasResult)
            Container(
              color: AppColors.darkBackground,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_searchResult.currentInstanceIndex}/'
                    '${_searchResult.totalInstanceCount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white),
                    onPressed: () => _searchResult.previousInstance(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white),
                    onPressed: () => _searchResult.nextInstance(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      _searchResult.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: SfPdfViewer.memory(
              pdfBytes,
              controller: _pdfViewerController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoaded: (details) {
                setState(() => _totalPages = details.document.pages.count);
                if (_currentPage > 1 && _currentPage <= _totalPages) {
                  _pdfViewerController.jumpToPage(_currentPage);
                } else {
                  _currentPage = 1;
                }
              },
              onDocumentLoadFailed: (details) {
                setState(() {
                  _errorMessage =
                      'No fue posible abrir el PDF de este libro: '
                      '${details.description}';
                });
              },
              onPageChanged: (details) {
                setState(() => _currentPage = details.newPageNumber);
                _saveProgress(details.newPageNumber);
              },
            ),
          ),
          Container(
            color: AppColors.darkBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    book.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_totalPages > 0)
                  Text(
                    'Pág. $_currentPage de $_totalPages',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
