// Shared glass surfaces, section headings and label/value rows.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/palette.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius corners = BorderRadius.circular(radius);
    final EdgeInsetsGeometry? outer = margin;

    final Widget surface;
    if (color != null || !dark) {
      surface = Material(
        color: color ?? p.panel,
        shape: RoundedRectangleBorder(
          borderRadius: corners,
          side: BorderSide(color: borderColor ?? p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
    } else {
      surface = Container(
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(color: borderColor ?? p.line),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x17FFFFFF), Color(0x08FFFFFF)],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8)),
            BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 0, offset: Offset(0, -1)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            color: Colors.transparent,
            child: onTap == null
                ? Padding(padding: padding, child: child)
                : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
          ),
        ),
      );
    }

    return outer == null ? surface : Padding(padding: outer, child: surface);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Widget? end = trailing;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: p.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          if (end != null) end,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.ltr = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool ltr;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: p.muted, fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: TextStyle(
                color: valueColor ?? p.text,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(text, style: TextStyle(color: p.text, fontSize: 13, height: 1.6)),
        ),
      ),
    );
  }
}
