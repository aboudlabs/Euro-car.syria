// Basic surfaces: a bordered panel, a section heading and a label / value row.

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// A flat bordered surface. Tappable when [onTap] is given.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 14,
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
    final Widget content = Padding(padding: padding, child: child);
    final Widget surface = Material(
      color: color ?? p.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    final EdgeInsetsGeometry? outer = margin;
    if (outer == null) {
      return surface;
    }
    return Padding(padding: outer, child: surface);
  }
}

/// A heading above a group of content, with an optional trailing widget.
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

/// One label with its value, used in summaries.
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

  /// Force left-to-right for phone numbers, codes and links.
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

/// A tinted box with a short message, used for the admin's notes and cancellation reasons.
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
