import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'supabase_client_service.dart';

/// Servicio responsable de subir archivos binarios (portadas y PDFs
/// de libros) a Supabase Storage y devolver su URL pública.
///
/// Usado por el panel de administrador al agregar o editar libros.
/// Los dos buckets reales del proyecto (`portadas` y `libros-pdf`)
/// son públicos, por lo que basta con `getPublicUrl` tras la subida.
///
/// Trabaja siempre con bytes (`Uint8List`) en lugar de `dart:io File`
/// para que funcione igual en Flutter Web, Android e iOS: `file_picker`
/// puede devolver los bytes del archivo elegido en las tres
/// plataformas (con `withData: true`), mientras que `dart:io.File` no
/// existe en Web.
class StorageService {
  final SupabaseClient _client = SupabaseClientService.client;
  final Uuid _uuid = const Uuid();

  /// Sube la portada de un libro y devuelve su URL pública.
  Future<String> uploadBookCover({
    required Uint8List bytes,
    required String originalFileName,
  }) {
    return _uploadBytes(
      bucket: AppConstants.bucketCovers,
      bytes: bytes,
      originalFileName: originalFileName,
    );
  }

  /// Sube el archivo PDF del libro y devuelve su URL pública.
  Future<String> uploadBookFile({
    required Uint8List bytes,
    required String originalFileName,
  }) {
    return _uploadBytes(
      bucket: AppConstants.bucketFiles,
      bytes: bytes,
      originalFileName: originalFileName,
    );
  }

  Future<String> _uploadBytes({
    required String bucket,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    try {
      final extension =
          originalFileName.contains('.') ? originalFileName.split('.').last : 'bin';
      final fileName = '${_uuid.v4()}.$extension';

      await _client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      throw AppException('No fue posible subir el archivo: $e');
    }
  }

  /// Elimina un archivo del bucket dado a partir de su nombre.
  Future<void> deleteFile({
    required String bucket,
    required String fileName,
  }) async {
    try {
      await _client.storage.from(bucket).remove([fileName]);
    } catch (e) {
      throw AppException('No fue posible eliminar el archivo: $e');
    }
  }
}
