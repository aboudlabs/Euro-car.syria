// A compact search box with a clear button (used by the catalog).

import 'package:flutter/material.dart';

import '../theme/palette.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final OutlineInputBorder normal = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: p.line),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: p.text, fontSize: 16),
      cursorColor: p.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.8), fontSize: 15),
        prefixIcon: Icon(Icons.search_rounded, color: p.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: 'مسح البحث',
                icon: Icon(Icons.close_rounded, color: p.muted),
              ),
        filled: true,
        fillColor: p.panelAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: normal,
        enabledBorder: normal,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
      ),
    );
  }
}
