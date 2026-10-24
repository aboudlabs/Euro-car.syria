// Cards for the orders tab: a placed order (expandable list of its parts) and a special request.

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/models.dart';
import '../../theme/palette.dart';
import '../../widgets/feedback.dart';
import '../../widgets/panel.dart';
import '../../widgets/part_plate.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Order order = widget.order;
    final bool hasItems = order.items.isNotEmpty;
    final String? note = order.statusNote;

    int units = 0;
    for (final OrderLine line in order.items) {
      units += line.qty;
    }

    return Panel(
      onTap: hasItems ? () => setState(() => _open = !_open) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'طلب ${order.label}',
                  style: TextStyle(color: p.text, fontSize: 16.5, fontWeight: FontWeight.w900),
                ),
              ),
              StatusChip(
                label: orderStatusLabel(order.status),
                tone: statusTone(order.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatDate(order.createdAt)} · ${payMethodLabel(order.payMethod)}',
            style: TextStyle(color: p.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                formatUsd(order.total),
                style: TextStyle(color: p.text, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (hasItems) ...<Widget>[
                Text(
                  units == 1 ? 'قطعة واحدة' : '$units قطع',
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: p.muted,
                ),
              ],
            ],
          ),
          if (order.isCancelled && note != null && note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            NoteBox(text: 'السبب: $note', color: p.err),
          ],
          if (_open && hasItems) ...<Widget>[
            const SizedBox(height: 8),
            Divider(color: p.line),
            for (final OrderLine line in order.items) _OrderLineRow(line: line),
          ],
        ],
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.name,
                  style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (line.oemNumber.isNotEmpty) PartNumberPlate(number: line.oemNumber),
                    if (line.brand.isNotEmpty)
                      Text(line.brand, style: TextStyle(color: p.muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatUsd(line.lineTotal),
                style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              Text(
                '${line.qty} × ${formatUsd(line.unitPrice)}',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request});

  final SpecialRequest request;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final double? price = request.quotedPrice;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  request.partName,
                  style: TextStyle(color: p.text, fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(
                label: specialStatusLabel(request.status),
                tone: statusTone(request.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.brandLabel} · ${formatDate(request.createdAt)}',
            style: TextStyle(color: p.muted, fontSize: 13),
          ),
          if (price != null && price > 0) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text('السعر المقترح', style: TextStyle(color: p.muted, fontSize: 14)),
                const Spacer(),
                Text(
                  formatUsd(price),
                  style: TextStyle(color: p.primary, fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
          if (request.adminNote.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            NoteBox(text: 'ملاحظة الإدارة: ${request.adminNote}', color: p.primary),
          ],
        ],
      ),
    );
  }
}
