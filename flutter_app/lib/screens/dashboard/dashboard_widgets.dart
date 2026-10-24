// Building blocks shared by the workshop and marketer dashboards.

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/models.dart';
import '../../theme/palette.dart';
import '../../widgets/panel.dart';

/// A figure with an icon, a label and an optional explanation.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.accent,
    this.valueColor,
    this.borderColor,
    this.footer,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  /// Colour of the icon (defaults to the primary colour).
  final Color? accent;
  final Color? valueColor;
  final Color? borderColor;

  /// Extra content under the figure, for example a progress bar.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Color tint = accent ?? p.primary;
    final String? text = note;
    final Widget? extra = footer;
    return Panel(
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: tint, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: TextStyle(color: p.muted, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? p.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (text != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5)),
                ],
                if (extra != null) ...<Widget>[
                  const SizedBox(height: 10),
                  extra,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 8});

  /// From 0 to 1.
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final double clamped = value < 0 ? 0.0 : (value > 1 ? 1.0 : value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        color: color ?? p.primary,
        backgroundColor: p.panelAlt,
      ),
    );
  }
}

/// A titled group of orders (the workshop dashboard lists cash orders and debt orders separately).
class OrderGroup extends StatelessWidget {
  const OrderGroup({
    super.key,
    required this.title,
    required this.color,
    required this.orders,
    required this.total,
  });

  final String title;
  final Color color;
  final List<Order> orders;

  /// Sum of the orders shown.
  final double total;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: TextStyle(color: color, fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'لا توجد طلبات ضمن هذه الفئة حتى الآن.',
                style: TextStyle(color: p.muted, fontSize: 13.5),
              ),
            )
          else ...<Widget>[
            for (final Order order in orders)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'طلب ${order.label}',
                            style: TextStyle(
                              color: p.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${formatDate(order.createdAt)} · ${orderStatusLabel(order.status)}',
                            style: TextStyle(color: p.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatUsd(order.total),
                      style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            Divider(color: p.line),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'إجمالي الطلبات المعروضة: ${formatUsd(total)}',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
