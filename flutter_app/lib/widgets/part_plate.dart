// The part-number plate and the brand mark. The plate is the app's signature element: every OEM number is
// shown on a small engraved plate with a crimson edge, the way parts are labelled on the shelf.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';

class PartNumberPlate extends StatelessWidget {
  const PartNumberPlate({super.key, required this.number, this.large = false});

  final String number;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final String text = number.trim().isEmpty ? '—' : number.trim();
    final double stripeHeight = large ? 32 : 24;

    final Widget plate = Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.plate,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 4,
              height: stripeHeight,
              decoration: BoxDecoration(
                color: p.brand,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: 4),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: codeFont,
                    fontWeight: FontWeight.w700,
                    fontSize: large ? 16 : 12.5,
                    letterSpacing: 0.8,
                    color: p.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: 'رقم القطعة $text',
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ رقم القطعة')),
          );
        },
        child: plate,
      ),
    );
  }
}

/// "EURO CARS" on a plate with the crimson edge.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.plate,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: p.line, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: size * 0.22,
              height: size * 1.7,
              decoration: BoxDecoration(
                color: p.brand,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(size * 0.24)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.2),
              child: Text(
                'EURO CARS',
                style: TextStyle(
                  fontFamily: appFont,
                  fontWeight: FontWeight.w900,
                  fontSize: size,
                  letterSpacing: size * 0.09,
                  color: p.text,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
