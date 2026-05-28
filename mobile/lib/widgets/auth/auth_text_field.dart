import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/themes/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final inputTheme = Theme.of(context).inputDecorationTheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      cursorColor: Theme.of(context).colorScheme.secondary,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textoPrincipal,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: inputTheme.filled,
        fillColor: inputTheme.fillColor,
        hintStyle: inputTheme.hintStyle,
        labelStyle: inputTheme.labelStyle,
        prefixIconColor: inputTheme.prefixIconColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputTheme.border,
        enabledBorder: inputTheme.enabledBorder,
        focusedBorder: inputTheme.focusedBorder,
        errorBorder: inputTheme.errorBorder,
        focusedErrorBorder: inputTheme.focusedErrorBorder,
        errorStyle: inputTheme.errorStyle,
      ),
      validator: validator,
    );
  }
}
