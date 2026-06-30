import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cep_service.dart';

enum _CepStatus { idle, loading, success, error }

/// Campo de CEP com busca automática de endereço (ViaCEP).
/// Ao digitar 8 números, busca automaticamente e chama [onAddressFound]
/// com o resultado, para que a tela preencha rua/bairro/cidade/estado.
class CepInputField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(CepResult result) onAddressFound;
  final String? Function(String?)? validator;

  const CepInputField({
    super.key,
    required this.controller,
    required this.onAddressFound,
    this.validator,
  });

  @override
  State<CepInputField> createState() => _CepInputFieldState();
}

class _CepInputFieldState extends State<CepInputField> {
  final _cepService = CepService();
  _CepStatus _status = _CepStatus.idle;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final clean = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 8) {
      _search(clean);
    } else if (_status != _CepStatus.idle) {
      setState(() {
        _status = _CepStatus.idle;
        _errorText = null;
      });
    }
  }

  Future<void> _search(String cep) async {
    setState(() {
      _status = _CepStatus.loading;
      _errorText = null;
    });

    try {
      final result = await _cepService.fetchAddressByCep(cep);
      if (!mounted) return;
      setState(() => _status = _CepStatus.success);
      widget.onAddressFound(result);
    } on CepException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _CepStatus.error;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _CepStatus.error;
        _errorText = 'Erro ao buscar o CEP.';
      });
    }
  }

  Widget? get _suffixIcon {
    switch (_status) {
      case _CepStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _CepStatus.success:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case _CepStatus.error:
        return const Icon(Icons.error_outline, color: AppColors.error);
      case _CepStatus.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
            _CepMaskFormatter(),
          ],
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _suffixIcon,
          ),
        ),
        if (_status == _CepStatus.error && _errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(_errorText!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        if (_status == _CepStatus.success)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Endereço encontrado!',
                style: TextStyle(color: AppColors.success, fontSize: 12)),
          ),
      ],
    );
  }
}

/// Aplica a máscara 00000-000 enquanto o usuário digita.
class _CepMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length > 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Card somente leitura que exibe o endereço já preenchido,
/// usado abaixo do campo de CEP nas telas de cadastro.
class AddressPreviewCard extends StatelessWidget {
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  const AddressPreviewCard({
    super.key,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (street.isEmpty && neighborhood.isEmpty && city.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_outlined, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (street.isNotEmpty)
                  Text(street,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (neighborhood.isNotEmpty) neighborhood,
                    if (city.isNotEmpty) city,
                    if (state.isNotEmpty) state,
                  ].join(' — '),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
