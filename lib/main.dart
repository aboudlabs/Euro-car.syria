// EURO CARS - native app for workshops and marketers.
//
// The application itself lives in app.dart; EuroApp is re-exported here so that `package:euro_cars/main.dart`
// keeps providing it (the widget test and any tooling that imported it before keep working).

import 'package:flutter/material.dart';

import 'app.dart';

export 'app.dart' show EuroApp;

void main() => runApp(const EuroApp());
