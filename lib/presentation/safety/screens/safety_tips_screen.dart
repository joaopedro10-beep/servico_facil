import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/firestore_datasource.dart';

/// Tela de dicas de segurança.
/// Os dados são carregados do Firestore (coleção `safety_tips`)
/// para que o conteúdo possa ser atualizado remotamente sem
/// publicar uma nova versão do app.
/// Estrutura do documento: { title, body, icon_name, color_hex, order }
class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  final _ds = Get.find<FirestoreDatasource>();

  List<_TipData> _tips = [];
  bool _loading = true;
  String? _error;

  // Fallback hardcoded caso Firestore não tenha dados ou falhe
  static const _fallback = [
    _TipData(
      icon: Icons.phone_android_outlined,
      title: 'Solicite sempre pelo app',
      body: 'Nunca combine serviços fora do aplicativo. Isso protege você e o profissional.',
      color: AppColors.info,
    ),
    _TipData(
      icon: Icons.verified_outlined,
      title: 'Verifique o badge',
      body: 'Prefira profissionais com o badge azul "Verificado". O documento foi conferido pela nossa equipe.',
      color: AppColors.primary,
    ),
    _TipData(
      icon: Icons.payments_outlined,
      title: 'Não pague antes de concluir',
      body: 'Só efetue pagamentos após confirmar que o serviço foi concluído. Nunca pague em dinheiro antes de começar.',
      color: AppColors.success,
    ),
    _TipData(
      icon: Icons.rate_review_outlined,
      title: 'Avalie após o serviço',
      body: 'Sua avaliação ajuda outros usuários a escolherem bons profissionais e melhora a plataforma.',
      color: AppColors.warning,
    ),
    _TipData(
      icon: Icons.support_agent_outlined,
      title: 'Entre em contato conosco',
      body: 'Em caso de problema, acione o suporte pelo app. Estamos disponíveis 24h para ajudar.',
      color: AppColors.error,
    ),
    _TipData(
      icon: Icons.lock_outlined,
      title: 'Proteja seus dados',
      body: 'Nunca compartilhe sua senha ou dados de pagamento com ninguém, nem com o profissional.',
      color: AppColors.primaryDark,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await _ds.getSafetyTips();
      if (snap.isNotEmpty) {
        final parsed = snap
            .whereType<Map<String, dynamic>>()
            .map((m) => _TipData.fromMap(m))
            .toList();
        setState(() { _tips = parsed.isNotEmpty ? parsed : _fallback; _loading = false; });
      } else {
        // Sem dados no Firestore — usa fallback
        setState(() { _tips = _fallback; _loading = false; });
      }
    } catch (e) {
      // Falha de rede — usa fallback silenciosamente
      setState(() { _tips = _fallback; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicas de segurança'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: _loadFromFirestore,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Banner informativo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sua segurança é nossa prioridade. Siga estas dicas para ter uma experiência tranquila.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              height: 1.4),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  ..._tips.map((tip) => _TipCard(tip: tip)),
                ],
              ),
            ),
    );
  }
}

// ─── Modelo de dica ───────────────────────────────────────────────────────────
class _TipData {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TipData({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  /// Constrói a partir de um documento Firestore.
  /// Campos esperados: title (String), body (String),
  /// icon_name (String — nome do ícone Material), color_hex (String — '#RRGGBB')
  factory _TipData.fromMap(Map<String, dynamic> map) {
    return _TipData(
      icon: _iconFromName(map['icon_name'] as String? ?? 'shield_outlined'),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      color: _colorFromHex(map['color_hex'] as String? ?? '#1D9E75'),
    );
  }

  static IconData _iconFromName(String name) {
    const map = {
      'phone_android_outlined':  Icons.phone_android_outlined,
      'verified_outlined':       Icons.verified_outlined,
      'payments_outlined':       Icons.payments_outlined,
      'rate_review_outlined':    Icons.rate_review_outlined,
      'support_agent_outlined':  Icons.support_agent_outlined,
      'lock_outlined':           Icons.lock_outlined,
      'shield_outlined':         Icons.shield_outlined,
      'warning_outlined':        Icons.warning_amber_outlined,
      'report_outlined':         Icons.report_outlined,
    };
    return map[name] ?? Icons.info_outlined;
  }

  static Color _colorFromHex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ─── Card de dica ─────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final _TipData tip;
  const _TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: tip.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis, maxLines: 2),
                const SizedBox(height: 4),
                Text(tip.body,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45),
                    overflow: TextOverflow.ellipsis, maxLines: 5),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
