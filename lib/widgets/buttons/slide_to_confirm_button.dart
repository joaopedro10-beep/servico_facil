import 'package:flutter/material.dart';

/// Botão deslizante grande estilo 99 Motorista.
///
/// Não é um toggle: serve exclusivamente para avançar o andamento do
/// serviço. A ação [onConfirmed] só dispara quando o prestador arrasta o
/// polegar até o FINAL da pista. Se soltar antes, o botão volta suavemente
/// ao início.
///
/// Uso:
/// ```dart
/// SlideToConfirmButton(
///   label: 'Arraste para informar chegada ao cliente',
///   color: const Color(0xFF1D9E75),
///   onConfirmed: controller.confirmArrival,
/// )
/// ```
class SlideToConfirmButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final Future<void> Function() onConfirmed;

  const SlideToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = const Color(0xFF1D9E75),
    this.icon = Icons.chevron_right_rounded,
    this.enabled = true,
    this.loading = false,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  static const _height = 60.0;
  static const _thumbSize = 52.0;

  double _drag = 0; // 0..1
  bool _busy = false;

  late final AnimationController _reset = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() {
      setState(() => _drag = _resetTween.value);
    });
  late Animation<double> _resetTween =
      Tween<double>(begin: 0, end: 0).animate(_reset);

  @override
  void dispose() {
    _reset.dispose();
    super.dispose();
  }

  void _snapBack() {
    _resetTween = Tween<double>(begin: _drag, end: 0).animate(
        CurvedAnimation(parent: _reset, curve: Curves.easeOutCubic));
    _reset.forward(from: 0);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.onConfirmed();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _drag = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading && !_busy;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final maxOffset = width - _thumbSize - 8;
      final offset = _drag * maxOffset;

      return Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: Container(
          height: _height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(color: widget.color.withOpacity(0.35)),
          ),
          child: Stack(alignment: Alignment.centerLeft, children: [
            // Preenchimento conforme arrasta
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              height: _height,
              width: offset + _thumbSize + 4,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.25 + 0.35 * _drag),
                borderRadius: BorderRadius.circular(_height / 2),
              ),
            ),

            // Texto central com leve fade conforme o progresso
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: (1 - _drag * 1.4).clamp(0.0, 1.0),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Polegar
            Positioned(
              left: 4 + offset,
              child: GestureDetector(
                onHorizontalDragUpdate: !active
                    ? null
                    : (d) => setState(() {
                          _drag = ((_drag * maxOffset + d.delta.dx) /
                                  maxOffset)
                              .clamp(0.0, 1.0);
                        }),
                onHorizontalDragEnd: !active
                    ? null
                    : (_) {
                        if (_drag >= 0.92) {
                          setState(() => _drag = 1);
                          _confirm();
                        } else {
                          _snapBack();
                        }
                      },
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: (_busy || widget.loading)
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(widget.icon,
                          color: Colors.white, size: 30),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
