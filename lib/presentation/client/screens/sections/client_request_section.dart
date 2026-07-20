import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../client_home_screen.dart' show CTheme;
import '../../controllers/client_controller.dart';

/// Tela de solicitação de serviço.
/// REGRA DE NEGÓCIO: o cliente NÃO escolhe o prestador.
/// Ele informa categoria, descrição, data/hora, endereço e fotos.
/// A plataforma envia para todos os prestadores disponíveis da categoria.
/// O primeiro que aceitar fica vinculado.
class ClientRequestSection extends StatefulWidget {
  final ClientController ctrl;
  const ClientRequestSection({super.key, required this.ctrl});

  @override
  State<ClientRequestSection> createState() => _ClientRequestSectionState();
}

class _ClientRequestSectionState extends State<ClientRequestSection> {
  int _step = 0; // 0=categoria 1=detalhes 2=confirmação

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: CTheme.primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Solicitar Serviço',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          // Steps indicator
          _StepBar(currentStep: _step),
        ]),
      ),

      // Conteúdo por step
      Expanded(
        child: Obx(() {
          if (widget.ctrl.submitSuccess.value) {
            return _SuccessView(ctrl: widget.ctrl,
                onNew: () {
                    widget.ctrl.clearForm();
                    setState(() => _step = 0);
                  });
          }
          switch (_step) {
            case 0: return _StepCategory(
                ctrl: widget.ctrl,
                onNext: () => setState(() => _step = 1));
            case 1: return _StepDetails(
                ctrl: widget.ctrl,
                onBack: () => setState(() => _step = 0),
                onNext: () => setState(() => _step = 2));
            case 2: return _StepConfirm(
                ctrl: widget.ctrl,
                onBack: () => setState(() => _step = 1));
            default: return _StepCategory(
                ctrl: widget.ctrl,
                onNext: () => setState(() => _step = 1));
          }
        }),
      ),
    ]);
  }
}

// ─── Barra de steps ───────────────────────────────────────────────────────────
class _StepBar extends StatelessWidget {
  final int currentStep;
  const _StepBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Serviço', 'Detalhes', 'Resumo'];
    return Row(children: labels.asMap().entries.map((e) {
      final i   = e.key;
      final lbl = e.value;
      final done = i < currentStep;
      final cur  = i == currentStep;
      return Expanded(
        child: Row(children: [
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done || cur
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: CTheme.primary, size: 16)
                    : Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cur
                                ? CTheme.primary
                                : Colors.white.withOpacity(0.6))),
              ),
            ),
            const SizedBox(height: 4),
            Text(lbl,
                style: TextStyle(
                    fontSize: 10, color: cur || done
                        ? Colors.white
                        : Colors.white60,
                    fontWeight: cur
                        ? FontWeight.w700 : FontWeight.w400),
                overflow: TextOverflow.ellipsis),
          ]),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < currentStep
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
            ),
        ]),
      );
    }).toList());
  }
}

// ─── Step 0 — Categoria ───────────────────────────────────────────────────────
class _StepCategory extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onNext;
  const _StepCategory({required this.ctrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Qual serviço você precisa?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: CTheme.textDark)),
        const SizedBox(height: 6),
        const Text('Selecione a categoria e os profissionais disponíveis serão notificados.',
            style: TextStyle(fontSize: 13, color: CTheme.textGray),
            overflow: TextOverflow.ellipsis, maxLines: 3),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: serviceCategories.map((cat) {
            return Obx(() {
              final sel = ctrl.selectedCategory.value == cat.name;
              return GestureDetector(
                onTap: () => ctrl.selectCategory(cat.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: sel ? CTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: sel ? CTheme.primary : CTheme.border,
                        width: sel ? 2 : 1),
                    boxShadow: sel ? [
                      BoxShadow(color: CTheme.primary.withOpacity(0.25),
                          blurRadius: 8, offset: const Offset(0, 3))
                    ] : const [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(cat.icon,
                          color: sel ? Colors.white : CTheme.primary,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(cat.name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : CTheme.textDark),
                            overflow: TextOverflow.ellipsis, maxLines: 2),
                      ),
                    ]),
                  ),
                ),
              );
            });
          }).toList(),
        ),
        const SizedBox(height: 24),

        Obx(() => ctrl.submitError.value.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CTheme.red.withOpacity(0.3)),
                ),
                child: Text(ctrl.submitError.value,
                    style: const TextStyle(color: CTheme.red, fontSize: 13),
                    overflow: TextOverflow.ellipsis, maxLines: 3),
              )
            : const SizedBox.shrink()),

        SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (ctrl.selectedCategory.value.isEmpty) {
                  ctrl.submitError.value = 'Selecione uma categoria.';
                  return;
                }
                ctrl.submitError.value = '';
                onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Continuar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Step 1 — Detalhes ────────────────────────────────────────────────────────
class _StepDetails extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _StepDetails({
    required this.ctrl,
    required this.onBack,
    required this.onNext,
  });


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Detalhes para ${ctrl.selectedCategory.value}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: CTheme.textDark),
            overflow: TextOverflow.ellipsis, maxLines: 2),
        const SizedBox(height: 16),

        // Descrição
        const Text('Descreva o serviço',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: CTheme.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.descriptionCtrl,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Descreva o que você precisa em detalhes...',
            hintStyle: const TextStyle(fontSize: 13, color: CTheme.textLight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: CTheme.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),



        // Fotos opcionais
        const Text('Fotos (opcional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: CTheme.textDark)),
        const SizedBox(height: 8),
        Obx(() => Row(children: [
          ...ctrl.photoFiles.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(e.value,
                    width: 72, height: 72, fit: BoxFit.cover),
              ),
              Positioned(
                top: 2, right: 2,
                child: GestureDetector(
                  onTap: () => ctrl.removePhoto(e.key),
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: CTheme.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
            ]),
          )),
          if (ctrl.photoFiles.length < 3)
            GestureDetector(
              onTap: ctrl.pickPhoto,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CTheme.border, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: CTheme.primary, size: 22),
                    SizedBox(height: 4),
                    Text('Adicionar',
                        style: TextStyle(fontSize: 9, color: CTheme.textGray)),
                  ],
                ),
              ),
            ),
        ])),
        const SizedBox(height: 24),

        Obx(() => ctrl.submitError.value.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CTheme.red.withOpacity(0.3)),
                ),
                child: Text(ctrl.submitError.value,
                    style: const TextStyle(color: CTheme.red, fontSize: 13),
                    overflow: TextOverflow.ellipsis, maxLines: 3),
              )
            : const SizedBox.shrink()),

        SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: const BorderSide(color: CTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Voltar',
                    style: TextStyle(color: CTheme.textGray)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.descriptionCtrl.text.trim().isEmpty) {
                    ctrl.submitError.value = 'Descreva o serviço.';
                    return;
                  }
                  ctrl.submitError.value = '';
                  onNext();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Continuar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Step 2 — Resumo e confirmação ────────────────────────────────────────────
class _StepConfirm extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onBack;
  const _StepConfirm({required this.ctrl, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirme sua solicitação',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: CTheme.textDark)),
          const SizedBox(height: 16),

          // Card resumo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CTheme.border),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              _ConfirmRow(Icons.category_rounded, 'Serviço',
                  ctrl.selectedCategory.value),
              const Divider(height: 20),
              _ConfirmRow(Icons.description_outlined, 'Descrição',
                  ctrl.descriptionCtrl.text.trim()),
              const Divider(height: 20),

              _ConfirmRow(Icons.location_on_outlined, 'Endereço',
                  ctrl.serviceAddress.value?.fullAddress ?? '—'),
              if (ctrl.photoFiles.isNotEmpty) ...[
                const Divider(height: 20),
                Row(children: [
                  const Icon(Icons.photo_library_outlined,
                      color: CTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Text('${ctrl.photoFiles.length} foto(s) anexada(s)',
                      style: const TextStyle(fontSize: 13,
                          color: CTheme.textGray),
                      overflow: TextOverflow.ellipsis),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // Aviso sobre a regra de negócio
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CTheme.primary.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: CTheme.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Após confirmar, os profissionais disponíveis serão notificados automaticamente. '
                    'O primeiro a aceitar será vinculado ao seu pedido.',
                    style: TextStyle(fontSize: 12, color: CTheme.primary,
                        height: 1.5),
                    overflow: TextOverflow.ellipsis, maxLines: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (ctrl.submitError.value.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CTheme.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CTheme.red.withOpacity(0.3)),
              ),
              child: Text(ctrl.submitError.value,
                  style: const TextStyle(color: CTheme.red, fontSize: 13),
                  overflow: TextOverflow.ellipsis, maxLines: 3),
            ),

          SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: const BorderSide(color: CTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Voltar',
                      style: TextStyle(color: CTheme.textGray)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: ctrl.isSubmitting.value
                      ? null : ctrl.submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: ctrl.isSubmitting.value
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmar e Enviar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
          ),
        ],
      )),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: CTheme.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: CTheme.textGray,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis, maxLines: 3),
        ]),
      ),
    ]);
  }
}

// ─── Tela de sucesso ──────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final ClientController ctrl;
  final VoidCallback onNew;
  const _SuccessView({required this.ctrl, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: CTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: CTheme.primary, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('Solicitação enviada!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: CTheme.textDark),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Os profissionais disponíveis foram notificados. '
              'Você receberá uma confirmação assim que alguém aceitar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: CTheme.textGray, height: 1.5),
              overflow: TextOverflow.ellipsis, maxLines: 5,
            ),
            const SizedBox(height: 32),
            SafeArea(
              top: false,
              child: Column(children: [
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: onNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Nova Solicitação',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
