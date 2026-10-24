// The root widget: owns the application state, applies the theme and decides which area to show
// (startup spinner, sign-in / registration, or the main app).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/session_store.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/home/home_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';
import 'widgets/part_plate.dart';

class EuroApp extends StatefulWidget {
  /// [store] and [httpClient] exist so tests can run the whole app without a device or a network.
  const EuroApp({super.key, this.store, this.httpClient});

  final SessionStore? store;
  final http.Client? httpClient;

  @override
  State<EuroApp> createState() => _EuroAppState();
}

class _EuroAppState extends State<EuroApp> {
  late final AppState _state;
  late final ThemeData _lightTheme;
  late final ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    _lightTheme = buildTheme(Brightness.light);
    _darkTheme = buildTheme(Brightness.dark);
    _state = AppState(
      api: ApiClient(baseUrl: apiBase, client: widget.httpClient),
      store: widget.store ?? SecureSessionStore(),
    );
    unawaited(_state.restore());
  }

  @override
  void dispose() {
    _state.dispose();
    _state.api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            title: 'EURO CARS',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: _state.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const <Locale>[Locale('ar')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: _withSystemBars,
            home: const _Gate(),
          );
        },
      ),
    );
  }

  /// Keeps the status and navigation bars readable in both themes.
  Widget _withSystemBars(BuildContext context, Widget? child) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Palette p = dark ? Palette.dark : Palette.light;
    final SystemUiOverlayStyle style = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: p.panel,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// Chooses the area to show from the session status.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    switch (state.status) {
      case SessionStatus.restoring:
        return const _Splash();
      case SessionStatus.signedOut:
        return const AuthFlow();
      case SessionStatus.signedIn:
        return const HomeShell();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandMark(size: 26),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
