# EURO CARS — Flutter Android

Native Flutter client (Arabic, RTL, dark and light themes) for the existing EURO CARS platform. It talks to the
current Next.js API (`https://al-euro-cdzo.onrender.com`) with the signed mobile session token kept in Android secure
storage. It never connects to Supabase directly. The admin role is web only: an admin account cannot sign in here.

## What the app does

| Area | Workshop | Marketer |
|------|----------|----------|
| Sign-in / registration | sign-in; registration waits for admin approval; optional signed referral link | sign-in; registration is instant |
| Catalog | search by name, brand, OEM number (any separators), model, years, branch; brand chips; stock badges | same |
| Cart and orders | quantity limits (stock, 100 per line, 50 lines); pay by cash on delivery, Sham Cash (receipt photo) or the debt ledger (credit checked against the limit) | cash on delivery and Sham Cash only |
| Orders | status, payment, items, rejection reason; special requests with a photo | same |
| Dashboard | tier estimate and progress, debt balance and 30-day window, cashback, ledger | referral code and share link, workshops, commissions (available / held / paid) |
| Account | edit name and governorate, change password, profile photo, theme, support (WhatsApp), sign-out | same |

The server stays the authority for prices, stock, totals, roles and limits; the app only sends part ids and quantities.

## Layout

```
lib/core      API client, models, cart rules, search, formatting, session store (no Flutter widgets)
lib/state     AppState: one ChangeNotifier for session, catalog, cart, orders, dashboards, profile
lib/theme     palette and ThemeData (dark and light)
lib/widgets   shared inputs, panels, pickers, feedback
lib/screens   auth, home shell, catalog, cart, orders, special request, dashboard, account
test          unit tests (core + AppState with a scripted server) and widget tests
tool          prepare_android.py, verify_apk.sh, make_icons.py
branding      launcher icons and launch background copied into the generated Android project
```

## Build

The Android folder is generated, not committed. With Flutter 3.47 (stable) and JDK 17:

```sh
cd flutter_app
flutter create --platforms=android --org com.eurocars --project-name euro_cars .
python3 tool/prepare_android.py          # INTERNET permission, label, icons, optional signing
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
bash tool/verify_apk.sh build/app/outputs/flutter-apk/app-release.apk
```

Use another API with `--dart-define=EURO_API_URL=https://your-api.example.com`.

`prepare_android.py` is needed: Flutter's template only grants the INTERNET permission to debug and profile builds, so
without it a release APK cannot reach the server.

## Continuous integration

`.github/workflows/flutter-android.yml` runs the steps above on every push to `improve/flutter-complete` and
`feat/flutter-native-app`, on pull requests and manually. `flutter analyze` and `flutter test` are gates (the workflow
fails if either fails) but do not stop the build, so the APK and its report can still be inspected. The APK is uploaded
only after `verify_apk.sh` passed: archive integrity, Android signature, package name, label, INTERNET permission,
minSdk, exactly the architectures `armeabi-v7a` and `arm64-v8a`, engine and Dart libraries, the bundled font, zip
alignment, and a SHA-256 file.

### Release signing

Without secrets the APK is signed with the debug key: it installs, but updates only work between builds made with the
same key, and it is not for the Play Store. To sign with your own key, create a keystore and add these repository
secrets: `ANDROID_KEYSTORE_BASE64` (`base64 -w0 release.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. Locally, put `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`)
next to the generated project; keep both files out of git.

## Notes

* The hosted API sleeps when idle, so reads are retried once and timeouts are generous. Orders are never resent
  automatically after a dropped connection: the app tells the user to check "طلباتي" first.
* The saved session keeps the keys `token` and `user`, so an installed session survives the update.
* `GET` and `PUT /api/auth` only read the session cookie, so those two calls also send `Cookie: euro_session=<token>`.
  Letting the server accept the Bearer token there would be a small backend improvement (not required).
* Fonts: Tajawal (SIL Open Font License, `assets/fonts/OFL.txt`).
