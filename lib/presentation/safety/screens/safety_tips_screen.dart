import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  static const _tips = [
    _Tip(
      icon: Icons.phone_android_outlined,
      title: 'Solicite sempre pelo app',
      body:
          'Nunca combine serviços fora do aplicativo. Isso protege você e o profissional.',
      color: AppColors.info,
    ),
    _Tip(
      icon: Icons.verified_outlined,
      title: 'Verifique o badge',
      body:
          'Prefira profissionais com o badge azul "Verificado". Isso indica que o documento foi conferido pela nossa equipe.',
      color: AppColors.primary,
    ),
    _Tip(
      icon: Icons.payments_outlined,
      title: 'Não pague antes de concluir',
      body:
          'Só efetue pagamentos após confirmar que o serviço foi concluído. Nunca pague em dinheiro antes de começar.',
      color: AppColors.success,
    ),
    _Tip(
      icon: Icons.chat_outlined,
      title: 'Use o chat do app',
      body:
          'Mantenha toda a comunicação dentro do app. Conversas fora não têm proteção em caso de disputas.',
      color: AppColors.statusInProgress,
    ),
    _Tip(
      icon: Icons.star_outline,
      title: 'Avalie após o serviço',
      body:
          'Suas avaliações ajudam outros usuários a escolher bons profissionais e mantêm a qualidade da plataforma.',
      color: Colors.amber,
    ),
    _Tip(
      icon: Icons.flag_outlined,
      title: 'Denuncie comportamento suspeito',
      body:
          'Se perceber algo errado — cobrança fora do app, ameaças ou comportamento inadequado — use o botão Denunciar imediatamente.',
      color: AppColors.error,
    ),
    _Tip(
      icon: Icons.location_on_outlined,
      title: 'Informe o endereço correto',
      body:
          'Forneça o endereço exato do serviço. Em caso de problema, isso facilita qualquer verificação necessária.',
      color: AppColors.warning,
    ),
    _Tip(
      icon: Icons.people_outline,
      title: 'Não fique sozinho(a)',
      body:
          'Se possível, tenha alguém de confiança presente durante serviços de profissionais que você ainda não conhece.',
      color: AppColors.statusPending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dicas de segurança')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sua segurança é prioridade',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'Siga estas orientações para uma experiência segura.',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tips
          ..._tips.map((tip) => _TipCard(tip: tip)),

          const SizedBox(height: 8),

          // Rodapé
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent_outlined,
                    color: AppColors.textSecondary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Em caso de emergência, entre em contato com as autoridades locais (190/193) e depois reporte pelo app.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Tip(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color});
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: tip.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tip.body,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
