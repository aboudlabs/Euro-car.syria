// Text fields, buttons, quantity stepper and avatar.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/text_utils.dart';
import '../theme/palette.dart';

/// A text field with the app's look. Labels sit above the field (not floating) so long Arabic labels never get cut.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.ltr = false,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.autofillHints,
    this.focusNode,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int maxLines;

  /// Left-to-right text for phone numbers, codes and links.
  final bool ltr;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final OutlineInputBorder normal = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.line),
    );
    final IconData? leading = icon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          obscureText: obscureText,
          autofillHints: autofillHints,
          textDirection: ltr ? TextDirection.ltr : null,
          textAlign: ltr ? TextAlign.left : TextAlign.start,
          style: TextStyle(color: p.text, fontSize: 16),
          cursorColor: p.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.75), fontSize: 15),
            prefixIcon: leading == null ? null : Icon(leading, color: p.muted, size: 21),
            suffixIcon: suffix,
            counterText: '',
            filled: true,
            fillColor: p.panelAlt,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: normal,
            enabledBorder: normal,
            disabledBorder: normal,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field with a show / hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      icon: Icons.lock_outline_rounded,
      obscureText: _hidden,
      ltr: true,
      maxLength: 128,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      suffix: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        tooltip: _hidden ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: p.muted,
          size: 21,
        ),
      ),
    );
  }
}

/// Main action button. Shows a spinner while [busy] and ignores taps until it finishes.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final IconData? leading = icon;
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: appFont, fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  Icon(leading, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );
  }
}

/// Secondary (outlined) action button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final IconData? leading = icon;
    final Color tint = color ?? p.text;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: tint,
        side: BorderSide(color: color ?? p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: appFont, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            Icon(leading, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Minus / quantity / plus control with large touch targets for use with work gloves.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;

  /// Null disables the plus button (maximum reached).
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepButton(icon: Icons.add_rounded, tooltip: 'زيادة الكمية', onTap: onIncrement),
        SizedBox(
          width: 44,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        _StepButton(icon: Icons.remove_rounded, tooltip: 'إنقاص الكمية', onTap: onDecrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.panelAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: enabled ? p.text : p.muted.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

/// The user's photo, or their initials when there is none.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.bytes, this.size = 64});

  final String name;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Uint8List? photo = bytes;
    final String initials = initialsOf(name);
    final Widget fallback = Center(
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, color: p.muted, size: size * 0.5)
          : Text(
              initials,
              style: TextStyle(
                color: p.text,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: p.panelAlt,
          child: photo == null
              ? fallback
              : Image.memory(
                  photo,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stack) => fallback,
                ),
        ),
      ),
    );
  }
}
