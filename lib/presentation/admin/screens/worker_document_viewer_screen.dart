import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/worker_model.dart';
import '../../../../presentation/admin/admin_theme.dart';
import '../../../../presentation/admin/controllers/admin_controller.dart';

/// Tela de visualização de documentos do prestador pelo admin (item 1.3).
/// Abre as imagens enviadas pelo prestador. Caso alguma foto não esteja
/// legível, o admin pode solicitar novos documentos diretamente desta tela.
class WorkerDocumentViewerScreen extends StatefulWidget {
  const WorkerDocumentViewerScreen({super.key});

  @override
  State<WorkerDocumentViewerScreen> createState() =>
      _WorkerDocumentViewerScreenState();
}

class _WorkerDocumentViewerScreenState
    extends State<WorkerDocumentViewerScreen> {
  late final WorkerModel worker;
  late final AdminController ctrl;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    worker = Get.arguments as WorkerModel;
    ctrl   = Get.find<AdminController>();
  }

  // Monta a lista de documentos disponíveis
  List<_DocItem> get _docs {
    final items = <_DocItem>[];
    if (worker.documentUrl != null && worker.documentUrl!.isNotEmpty) {
      items.add(_DocItem('RG / CNH', worker.documentUrl!, Icons.badge_rounded));
    }
    for (int i = 0; i < worker.portfolioUrls.length; i++) {
      items.add(_DocItem(
        i == 0 ? 'Selfie para validação' : 'Foto ${i + 1}',
        worker.portfolioUrls[i],
        i == 0 ? Icons.camera_alt_rounded : Icons.image_rounded,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final docs = _docs;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: AdminTheme.primaryDark,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Documentos — ${worker.name}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          Text('${docs.length} documento(s) enviado(s)',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          // Botão solicitar novos documentos (1.3)
          TextButton.icon(
            onPressed: () => _requestNewDocs(context),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            label: const Text('Pedir novos docs',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: docs.isEmpty
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_off_rounded,
                    size: 56, color: Colors.white30),
                SizedBox(height: 12),
                Text('Nenhum documento enviado.',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ]),
            )
          : Column(children: [
              // Visualizador principal
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.network(
                      docs[_selectedIndex].url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AdminTheme.primary),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              size: 64, color: Colors.white30),
                          SizedBox(height: 8),
                          Text('Imagem não disponível',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Label do documento atual
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(docs[_selectedIndex].icon,
                      color: AdminTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(docs[_selectedIndex].label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${_selectedIndex + 1} / ${docs.length}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ]),
              ),

              // Miniaturas
              if (docs.length > 1)
                Container(
                  height: 80,
                  color: Colors.black,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final sel = i == _selectedIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          width: 64,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? AdminTheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              docs[i].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white10,
                                child: const Icon(Icons.image_rounded,
                                    color: Colors.white30),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Botões de ação
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black87,
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _requestNewDocs(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.amberLight,
                          side: BorderSide(
                              color: AdminTheme.amberLight.withOpacity(0.5)),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Solicitar novos documentos',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          ctrl.approveWorker(worker);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.green,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: const Text('Aprovar cadastro',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }

  Future<void> _requestNewDocs(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Solicitar novos documentos'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Informe o motivo para ${worker.name} enviar novos documentos:',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ex: Documento ilegível, foto fora de foco, selfie inválida...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.amberLight),
            child: const Text('Solicitar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && reasonCtrl.text.trim().isNotEmpty) {
      // Chama requestDocuments do admin controller
      // Isso altera verificationStatus para 'documentsRequired'
      // e notifica o prestador
      await ctrl.requestDocuments(worker, reason: reasonCtrl.text.trim());
      if (context.mounted) Get.back();
    }
  }
}

class _DocItem {
  final String label;
  final String url;
  final IconData icon;
  const _DocItem(this.label, this.url, this.icon);
}
