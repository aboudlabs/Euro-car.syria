// The title area at the top of every main tab.

import 'package:flutter/material.dart';

import '../../theme/palette.dart';

class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final String? sub = subtitle;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (sub != null && sub.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
