/// Excepción de dominio unificada para toda la aplicación.
///
/// Los servicios (capa `data`) capturan excepciones de bajo nivel
/// (de Supabase, de red, etc.) y las traducen a [AppException] con un
/// mensaje ya listo para mostrarse al usuario final en español,
/// evitando que la UI dependa de detalles de implementación del
/// backend.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
