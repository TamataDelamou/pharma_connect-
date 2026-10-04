import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/utils/validators.dart';
import '../models/phone_country.dart';
import '../../../core/theme/palette.dart';

/// Champ de saisie téléphone séparant l'indicatif pays du numéro local.
///
/// Émet un numéro E.164 strict via [onChanged] — `null` tant que la saisie
/// est incomplète ou invalide. La normalisation finale passe par
/// [Validators.normalizeE164], le même point unique déjà utilisé par
/// `AuthProvider.sendPhoneOtp`, pour ne pas dupliquer la règle E.164 du
/// portefeuille (KER-ID-02/03).
class PhoneInputField extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final bool isError;
  final String? errorText;

  const PhoneInputField({
    super.key,
    required this.onChanged,
    this.isError = false,
    this.errorText,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final _localController = TextEditingController();
  PhoneCountry _selectedCountry = PhoneCountry.supported.first;

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  String _cleanLocalNumber(String input) {
    var digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  void _emitChange() {
    final cleaned = _cleanLocalNumber(_localController.text);
    if (cleaned.length != _selectedCountry.localDigits) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(
      Validators.normalizeE164('${_selectedCountry.dialCode}$cleaned'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isError
        ? context.palette.danger
        : context.palette.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Numéro de téléphone', style: context.text.label),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountryPicker(borderColor),
            const SizedBox(width: 8),
            Expanded(child: _buildLocalNumberField(borderColor)),
          ],
        ),
        if (widget.isError && widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: context.text.body2.copyWith(color: context.palette.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildCountryPicker(Color borderColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PhoneCountry>(
          value: _selectedCountry,
          dropdownColor: context.palette.background,
          icon: Icon(
            Icons.expand_more,
            color: context.palette.textSecondary,
            size: 18,
          ),
          style: context.text.body1,
          items: PhoneCountry.supported.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Text('${country.flag} ${country.dialCode}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCountry = value;
              _localController.clear();
            });
            _emitChange();
          },
        ),
      ),
    );
  }

  Widget _buildLocalNumberField(Color borderColor) {
    return TextField(
      controller: _localController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_selectedCountry.localDigits + 1),
      ],
      style: context.text.body1,
      onChanged: (_) => _emitChange(),
      decoration: InputDecoration(
        counterText: '',
        hintText: '6XXXXXXXX (${_selectedCountry.localDigits} chiffres)',
        hintStyle: context.text.body2.copyWith(
          color: context.palette.textHint,
        ),
        filled: true,
        fillColor: context.palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaConnectSpacing.radiusMd),
          borderSide: BorderSide(
            color: widget.isError
                ? context.palette.danger
                : context.palette.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
