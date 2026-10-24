// The top bar of screens that are opened on top of the tabs (part details, special request).

import 'package:flutter/material.dart';

import '../theme/palette.dart';

PreferredSizeWidget buildScreenBar(
  BuildContext context,
  String title, {
  List<Widget> actions = const <Widget>[],
}) {
  final Palette p = Palette.of(context);
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
    ),
    backgroundColor: p.bg,
    foregroundColor: p.text,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: false,
    actions: actions,
  );
}
