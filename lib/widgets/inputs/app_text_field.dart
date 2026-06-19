import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

// ─── Campo de senha com indicador de força ─────────────────────────────────
class PasswordStrengthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final int strength; // 0-4
  final String? Function(String?)? validator;

  const PasswordStrengthField({
    super.key,
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggleVisibility,
    required this.strength,
    this.validator,
  });

  Color get _barColor {
    if (strength <= 1) return AppColors.error;
    if (strength == 2) return AppColors.warning;
    if (strength == 3) return AppColors.info;
    return AppColors.success;
  }

  String get _label {
    if (strength == 0) return '';
    if (strength <= 1) return 'Fraca';
    if (strength == 2) return 'Razoável';
    if (strength == 3) return 'Boa';
    return 'Forte';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: controller,
          label: label,
          obscureText: !visible,
          validator: validator,
          keyboardType: TextInputType.visiblePassword,
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary),
            onPressed: onToggleVisibility,
          ),
        ),
        if (controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 4,
                  backgroundColor: AppColors.border,
                  color: _barColor,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_label,
                style: TextStyle(
                  fontSize: 12,
                  color: _barColor,
                  fontWeight: FontWeight.w500,
                )),
          ]),
        ],
      ],
    );
  }
}
