import 'dart:io';

/// CloudinaryService — upload de imagens.
/// 
/// MODO OFFLINE: uploads desabilitados temporariamente.
/// Para ativar, preencha _cloudName e _uploadPreset com seus dados do
/// painel Cloudinary (cloudinary.com) e remova o return '' abaixo.
class CloudinaryService {
  CloudinaryService._();

  static const _cloudName    = 'SEU_CLOUD_NAME';
  static const _uploadPreset = 'SEU_UPLOAD_PRESET';

  static Future<String> upload(File file, {required String folder}) async {
    // TODO: preencher _cloudName e _uploadPreset para ativar uploads
    return '';
  }

  static Future<List<String>> uploadAll(
    List<File> files, {
    required String folder,
  }) async {
    // Retorna lista vazia enquanto Cloudinary não está configurado
    return List.filled(files.length, '');
  }
}
