// Colour tokens. They come from the web app (dark: #07090E canvas with #0A84FF actions and the #8D2637
// brand crimson; light: #EEF3F9 canvas with #007AFF actions). Status colours are darker in the light theme
// so text on white keeps enough contrast.

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

  /// Screen background.
  final Color bg;

  /// Cards and sheets.
  final Color panel;

  /// Inputs and inset areas.
  final Color panelAlt;

  /// The engraved plate that carries part numbers.
  final Color plate;
  final Color line;
  final Color text;
  final Color muted;
  final Color primary;

  /// EURO CARS crimson, used sparingly (logo, plate edge).
  final Color brand;
  final Color ok;
  final Color warn;
  final Color err;

  static const Palette dark = Palette(
    bg: Color(0xFF07090E),
    panel: Color(0xFF11151E),
    panelAlt: Color(0xFF0B0E15),
    plate: Color(0xFF0D1118),
    line: Color(0xFF293141),
    text: Color(0xFFEAF0F8),
    muted: Color(0xFF9AA6B7),
    primary: Color(0xFF0A84FF),
    brand: Color(0xFFB03047),
    ok: Color(0xFF30D158),
    warn: Color(0xFFFF9F0A),
    err: Color(0xFFFF453A),
  );

  static const Palette light = Palette(
    bg: Color(0xFFEEF3F9),
    panel: Color(0xFFFFFFFF),
    panelAlt: Color(0xFFF3F6FB),
    plate: Color(0xFFF6F8FC),
    line: Color(0xFFD5DEEA),
    text: Color(0xFF0F172A),
    muted: Color(0xFF566377),
    primary: Color(0xFF0068D6),
    brand: Color(0xFF8D2637),
    ok: Color(0xFF1B8A3E),
    warn: Color(0xFFB45309),
    err: Color(0xFFC62828),
  );

  static Palette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Colour that stands for a status tone.
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

/// Fonts: Tajawal is bundled; numbers and codes use the platform monospace face.
const String appFont = 'Tajawal';
const String codeFont = 'monospace';
