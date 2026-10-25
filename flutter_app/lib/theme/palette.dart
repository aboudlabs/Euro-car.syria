// Colour tokens aligned with the EURO Next.js site's shared CSS variables.
import 'package:flutter/material.dart';

import '../core/labels.dart';

class Palette {
  const Palette({
    required this.bg,
    required this.panel,
    required this.panelAlt,
    required this.plate,
    required this.line,
    required this.text,
    required this.muted,
    required this.primary,
    required this.brand,
    required this.ok,
    required this.warn,
    required this.err,
  });

  final Color bg;
  final Color panel;
  final Color panelAlt;
  final Color plate;
  final Color line;
  final Color text;
  final Color muted;
  final Color primary;
  final Color brand;
  final Color ok;
  final Color warn;
  final Color err;

  // Mirrors app/globals.css: html.dark tokens.
  static const Palette dark = Palette(
    bg: Color(0xFF06080E),
    panel: Color(0x0FFFFFFF), // white at ~6% for glass surfaces
    panelAlt: Color(0x59000000), // black at ~35% for inset fields
    plate: Color(0x66000000),
    line: Color(0x26FFFFFF), // white at ~15%
    text: Color(0xFFFFFFFF),
    muted: Color(0x99FFFFFF), // white at ~60%
    primary: Color(0xFF0A84FF),
    brand: Color(0xFF8D2637),
    ok: Color(0xFF30D158),
    warn: Color(0xFFFF9F0A),
    err: Color(0xFFFF453A),
  );

  // Mirrors the website's light-theme tokens.
  static const Palette light = Palette(
    bg: Color(0xFFEEF3F9),
    panel: Color(0xFFFFFFFF),
    panelAlt: Color(0xFFFFFFFF),
    plate: Color(0xFFF6F8FC),
    line: Color(0xFFD5DEEA),
    text: Color(0xFF0F172A),
    muted: Color(0xFF475569),
    primary: Color(0xFF007AFF),
    brand: Color(0xFF8D2637),
    ok: Color(0xFF15803D),
    warn: Color(0xFFB45309),
    err: Color(0xFFB91C1C),
  );

  static Palette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  Color toneColor(StatusTone tone) {
    switch (tone) {
      case StatusTone.waiting:
        return warn;
      case StatusTone.progress:
        return primary;
      case StatusTone.success:
        return ok;
      case StatusTone.danger:
        return err;
    }
  }
}

const String appFont = 'Tajawal';
const String codeFont = 'monospace';
