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

  static bool get _isConfigured =>
      _cloudName != 'SEU_CLOUD_NAME' &&
      _uploadPreset != 'SEU_UPLOAD_PRESET' &&
      _cloudName.isNotEmpty &&
      _uploadPreset.isNotEmpty;

  static Future<String> upload(File file, {required String folder}) async {
    // Sem credenciais configuradas o upload é impossível — retorna ''
    // e a UI avisa. Veja as instruções no topo deste arquivo.
    if (!_isConfigured) return '';

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
