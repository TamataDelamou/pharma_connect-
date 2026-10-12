import 'package:flutter/material.dart';

import '../../theme/spacing.dart';
import '../../theme/palette.dart';

class GlassInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool isError;
  final String? errorText;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  // Phase 4 (module marketplace) : offer_create_screen.dart appelait
  // GlassInput(validator: ...) en supposant l'API d'un TextFormField brut -
  // paramètre jamais exposé par ce widget partagé, défaut de compilation,
  // jamais détecté faute de compilateur exécuté à la clôture du Module 13/
  // B2B. Ajouté en pass-through vers le TextFormField interne (additif,
  // nullable, aucun changement pour les 38 appelants existants qui ne le
  // passent pas).
  final FormFieldValidator<String>? validator;

  // C260 : validation au clavier (touche « Rechercher »), en pass-through
  // vers le TextFormField interne ; additif, aucun changement pour les
  // appelants qui ne les passent pas.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const GlassInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.isError = false,
    this.errorText,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.initialValue,
    this.validator,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          enabled: !isDisabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          validator: validator,
          style: context.text.body1.copyWith(
            color: isDisabled ? context.palette.textSecondary : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.body2.copyWith(
              color: context.palette.textHint,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isError
                        ? context.palette.danger
                        : context.palette.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: isError
                          ? context.palette.danger
                          : context.palette.textSecondary,
                      size: 20,
                    ),
                    onPressed: onSuffixPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            errorText: isError ? errorText : null,
            errorStyle: context.text.body2.copyWith(
              color: context.palette.danger,
            ),
            filled: true,
            fillColor: isDisabled
                ? context.palette.surfaceDisabled
                : context.palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? context.palette.danger
                    : context.palette.border,
                width: isError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? context.palette.danger
                    : context.palette.border,
                width: isError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(
                color: isError
                    ? context.palette.danger
                    : context.palette.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(color: context.palette.danger, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                PharmaConnectSpacing.radiusMd,
              ),
              borderSide: BorderSide(color: context.palette.danger, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (errorText != null && !isError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ],
      ],
    );
  }
}
