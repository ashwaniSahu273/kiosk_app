import 'package:flutter/material.dart';

/// A themed text field for kiosk forms (Requirement 10.6).
///
/// Wraps a [TextFormField] with a consistent kiosk look: a [label], an optional
/// leading [prefixIcon], password masking via [obscureText], a [validator] hook
/// for form-level validation, and an [errorText] slot for per-field validation
/// messages surfaced by a controller (e.g. the login per-field validation in
/// Requirement 1.6). Colors and typography derive from the active [ThemeData].
class KioskTextField extends StatelessWidget {
  const KioskTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.validator,
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  /// Floating label shown above the field.
  final String label;

  /// Controller for the field's text value.
  final TextEditingController? controller;

  /// When true, characters are masked (used for passwords).
  final bool obscureText;

  /// Optional form validator hook. Returns null when valid.
  final FormFieldValidator<String>? validator;

  /// Per-field error message; when non-null the field renders in its error
  /// state with this text. Lets a controller drive inline validation
  /// independently of the [Form] validator.
  final String? errorText;

  /// Optional placeholder text shown when the field is empty.
  final String? hintText;

  /// Optional leading icon.
  final IconData? prefixIcon;

  /// Keyboard type (e.g. [TextInputType.emailAddress]).
  final TextInputType? keyboardType;

  /// Action button shown on the soft keyboard.
  final TextInputAction? textInputAction;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called whenever the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field grabs focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      autovalidateMode: AutovalidateMode.disabled,
      style: theme.textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
    );
  }
}
