# EURO CARS — Feature-Preservation Checklist

Written **before any code was changed**, from a full read of the uploaded project
(`al-euro-main`: Next.js 14 + Supabase backend/web, Expo client, Flutter client, SQL, CI).
Baseline = git commit `main` (`Baseline: original al-euro-main snapshot…`). All work happens on branch
`improve/flutter-complete`; the original zip and its extracted copy are never modified.

**Rule for this work:** nothing in sections A–E and H may be removed, disabled, replaced or broken.
Section F (existing Flutter client) lists what must keep working *and* be improved. Section G lists defects found
in the baseline that are fixed (they are bugs, not features).

Legend for the last column ("Verified by") is filled in at the end of the work (see section I).

---

## A. Roles and what each may do (server-enforced — must not change)

| ID | Rule | Source |
|----|------|--------|
| A-01 | Three roles exist: `workshop`, `marketer`, `admin` (DB check `users_role_check`). | `lib/status.ts`, SQL |
| A-02 | **Mobile clients (`client:"mobile"`) can only sign in as `workshop` or `marketer`; `admin` is web-only.** | `app/api/auth/route.ts` |
| A-03 | Workshop registration creates an **inactive** account (`is_active=false`) → "pending approval"; marketer registration is active immediately. | `app/api/auth/route.ts` |
| A-04 | Inactive account cannot log in (403 + `pendingApproval:true`) and cannot place orders / special requests (403). | auth, orders, special-requests |
| A-05 | Only `workshop` accounts may pay by **debt ledger** (`pay=debt`, 403 for marketers). Marketers may use `cod` and `sham`. | `app/api/orders/route.ts`, `app/cart/page.tsx` |
| A-06 | `/api/workshop/dashboard` → workshop only (403 otherwise); `/api/marketer/dashboard` → marketer only. | dashboards |
| A-07 | Admin accounts never create orders (403). Admin API is cookie-only behind middleware. | orders, `middleware.ts` |

## B. HTTP API contract (every route stays byte-compatible)

| ID | Route | Contract the clients rely on |
|----|-------|------------------------------|
| B-01 | `POST /api/auth` login | body `{mode:"login", client:"mobile", role, phone, password}` → `{ok, user, accessToken}`; errors 400/401/403/404 with Arabic `error`. |
| B-02 | `POST /api/auth` register | body `{mode:"register", client:"mobile", role, name, phone, password, license?, city?, spec?, refCode?, refSignature?}`; workshop → `{ok, pendingApproval, message}`; marketer → `{ok, user, accessToken}`. Password ≥ 4 chars; workshop needs license+city+spec. |
| B-03 | `GET /api/auth` | cookie `euro_session` only → `{user}` or `{user:null}` (always HTTP 200). |
| B-04 | `PUT /api/auth` | cookie `euro_session` only; body `{name?, city?, newPassword?}` (name 2–100, city ≤ 80, password 4–128) → `{ok, user}`. |
| B-05 | `DELETE /api/auth` | clears cookie. |
| B-06 | `GET /api/parts` | `Authorization: Bearer` or cookie → `{parts:[{id,name,brand,pn,price,stock,model,years,altGrade,branch,image}]}`. |
| B-07 | `POST /api/orders` | multipart: `items` (JSON `{partId: qty}`, qty int 1–100, ≤ 50 lines), `pay` (`sham|cod|debt`), `receipt` (image, **required for sham**, ≤ 5 MB JPG/PNG/WebP) → `{ok, orderId, orderNumber, pay, total}`. Prices/stock/total always computed server-side. |
| B-08 | `GET /api/orders` | caller's last 30 orders: `id, order_number, total_amount, pay_method, status, status_note, created_at, items`. |
| B-09 | `POST /api/special-requests` | multipart: `brand` (one of BRANDS or `أخرى`), `otherBrand` (required if `أخرى`), `partName` (required), `partNumber`, `notes`, `image?` → `{ok, id}`. |
| B-10 | `GET /api/special-requests` | caller's last 30 requests incl. `quoted_price`, `status`, `admin_note`. |
| B-11 | `GET /api/workshop/dashboard` | `{user:{id,name,tier,debt_limit,debt_balance,cashback_balance}, orders[≤100], ledger[≤100]}`. |
| B-12 | `GET /api/marketer/dashboard` | `{marketer:{name,code,referralUrl}, workshops, commissions:{available,held,paid,total}}`. |
| B-13 | `GET/PUT /api/account/avatar` | Bearer or cookie; PUT raw `image/jpeg` ≤ 1.5 MB (JPEG magic bytes enforced); GET streams the user's avatar. |
| B-14 | Admin API `/api/admin/*` (accounts, commissions, ledger, orders, orders/[id], orders/[id]/status, overview, parts, parts/[id], parts/upload, payments, requests, requests/[id], reset-password) | unchanged; cookie + role check + DB re-check (`requireAdmin`). |
| B-15 | `POST /api/password-reset/admin`, `POST /api/admin/reset-password` | admin recovery with `ADMIN_PASSWORD_RESET_TOKEN`; unchanged. |
| B-16 | Session token | `base64url(json).hmac-sha256`, 30-day lifetime, accepted from cookie **or** `Authorization: Bearer`. Same format for cookie and mobile `accessToken`. |

## C. Database (Supabase) — no schema change allowed

| ID | Item |
|----|------|
| C-01 | Tables: `users`, `parts`, `orders`, `special_requests`, `debt_ledger`, `marketer_commissions`. Only column added by setup SQL: `orders.status_note`. |
| C-02 | CHECK constraints: order status `pending/approved/shipped/delivered/cancelled`; pay method `sham/cod/debt`; special status `new/priced/ordered/completed/cancelled`; ledger `debit/payment`; commission `held/available/paid`; tier `Bronze/Silver/Gold`. |
| C-03 | Atomic functions (service-role only): `admin_set_order_status`, `admin_record_debt_payment`, `admin_mark_commissions_paid`, `admin_overview`. |
| C-04 | Storage buckets: private `receipts`, `special-requests`, `avatars`; public `parts-images` (auto-created on first upload). |
| C-05 | Setup scripts `supabase/admin_full_setup.sql`, `fix_commission_release.sql`, `setup/*`, `setup-parts/*` untouched. |

## D. Business rules the clients must respect

| ID | Rule |
|----|------|
| D-01 | Price, stock and totals are authoritative on the server; the client only sends `{partId: qty}`. |
| D-02 | Debt orders do **not** change `debt_balance` until an admin approves; the client shows available credit = `debt_limit − debt_balance` and a debt limit of 0 means "not allowed yet". |
| D-03 | Debt counter: 30 days from the last `debit` ledger row whose `balance_after > 0`. |
| D-04 | Marketer commission = 2 % of a **delivered** order of a referred workshop; `held` for debt orders until the workshop's balance is 0, `available` otherwise. |
| D-05 | Referral links are HMAC-signed (`ref` + `sig`); the signature is sent as `refSignature` and the code must not be edited when it came from a signed link. |
| D-06 | Rejection/cancellation reason lives in `orders.status_note` and is shown to the customer; admin reply to a special request lives after the marker `[ملاحظة الإدارة]` (already split server-side as `admin_note`). |
| D-07 | Status vocabularies/labels (Arabic): see `lib/status.ts` (`ORDER_STATUS_LABEL`, `PAY_METHOD_LABEL`, `SPECIAL_STATUS_LABEL`, `COMMISSION_STATUS_LABEL`, `TIER_LABEL`, `LEDGER_TX_LABEL`). |
| D-08 | Out-of-stock parts cannot be added to the cart and point the user to a special request. |
| D-09 | Syrian governorate list and car brand lists used by registration / special requests (`lib/data.ts`, `app/login/page.tsx`). |

## E. Web app (Next.js) — untouched by this work

| ID | Feature |
|----|---------|
| E-01 | Login / register (workshop with license, governorate, brand specialties, optional signed marketer link; marketer instant). Pending-approval screen. |
| E-02 | Catalog with search, brand filter, product details (compatibility, alt grade), add to cart, "request it" for out-of-stock. |
| E-03 | Cart + checkout (sham receipt upload, cod, debt for workshops), order confirmation with order number. |
| E-04 | Special requests with photo. |
| E-05 | Account: profile edit (name, governorate, password), avatar crop/upload, "my orders", "my special requests" (quote + admin note + cancellation reason), WhatsApp support link, developer credit, logout. |
| E-06 | Workshop dashboard (cashback, debt + 30-day counter, tier estimate, cash vs debt orders, ledger). |
| E-07 | Marketer dashboard (signed referral link, copy, WhatsApp share, commissions held/available/paid, referred workshops). |
| E-08 | Dark/light theme. |
| E-09 | Admin: overview, accounts, payments queue, orders (+print invoice), special requests, ledger, parts CRUD (+image upload), commissions, admin login/reset-password. |

## F. Existing mobile clients

### F-1 Expo app (`mobile/`) — untouched; used as functional reference
| ID | Feature |
|----|---------|
| F-01 | Login (workshop/marketer), catalog+search, cart (cod, debt for workshop), orders list, **special request with photo**, account (marketer code/referral link/commissions). |

### F-2 Flutter app (`flutter_app/`) — preserved **and** upgraded
| ID | Existing behaviour (must keep working) |
|----|-----------------------------------------|
| F-02 | `EuroApp` root widget with `const` constructor; shows a `CircularProgressIndicator` while restoring the session (existing widget test relies on it). |
| F-03 | API base `https://al-euro-cdzo.onrender.com`, overridable with `--dart-define=EURO_API_URL=…`. |
| F-04 | Session kept in Android secure storage under keys `token` and `user` (**keys kept so installed sessions survive the update**). |
| F-05 | Login: role switch (workshop / marketer), phone + password, `POST /api/auth` (`client:"mobile"`), 30 s+ timeout, Arabic errors. |
| F-06 | Logout (app bar and account) clears the session. |
| F-07 | Bottom navigation: Catalog · Cart · Orders · Account. |
| F-08 | Catalog from `GET /api/parts`; search over name/brand/OEM/model; pull-to-refresh; quantity stepper capped by stock; empty state. |
| F-09 | Cart with totals; payment `cod` for everyone, `sham` and `debt` options; debt only for workshops. |
| F-10 | Order submit = multipart `items` + `pay`, Bearer auth; success shows order number and jumps to Orders. |
| F-11 | Orders list from `GET /api/orders`. |
| F-12 | Account from `/api/workshop/dashboard` (tier, debt limit, balance) or `/api/marketer/dashboard` (code, commissions). |
| F-13 | Arabic RTL, dark theme, brand colours (blue `#0A84FF`, crimson `#8D2637`). |
| F-14 | `flutter_app/test/widget_test.dart` (startup loading state) keeps passing. |
| F-15 | Dependencies already declared stay: `http`, `flutter_secure_storage`, `image_picker`, `cupertino_icons`. |

## G. Defects found in the baseline Flutter client (fixed, not "features")

| ID | Defect | Evidence |
|----|--------|----------|
| G-01 | No `android/` folder is committed; CI runs `flutter create` and nothing adds `android.permission.INTERNET` to the **main** manifest (Flutter templates only add it to debug/profile) → a release APK may be unable to reach the API. | `.github/workflows/flutter-android.yml` |
| G-02 | "شام كاش" button can never succeed: API requires a `receipt` image, the app never sends one (`image_picker` is declared but unused). | `main.dart` `sendOrder`, `orders/route.ts` |
| G-03 | Marketer "العمولات" prints the raw map (`{available: …}`); referral link, held/paid, workshop count never shown. | `main.dart` `accountPage` |
| G-04 | Startup `secure.read` is not guarded: a keystore error (e.g. after backup-restore) leaves the spinner forever. | `main.dart` `restore` |
| G-05 | Expired/invalid token (30-day) → every call fails with an error banner, no automatic return to login. | `main.dart` `api` |
| G-06 | `jsonDecode` on non-JSON replies (Render cold start 502 HTML, proxy errors) surfaces raw `FormatException`; timeouts (30 s) are shorter than a Render cold start. | `main.dart` |
| G-07 | Order status shown as raw enum (`pending`…); pay method, date, items, rejection reason (`status_note`) not shown. | `ordersPage` |
| G-08 | Success message rendered in the red error banner. | `sendOrder` |
| G-09 | Special requests (backend + web + Expo) are missing from the Flutter client. | — |
| G-10 | Registration (workshop/marketer, signed referral) missing. | — |
| G-11 | Profile edit / password change / avatar / support / theme missing (web has them). | — |
| G-12 | Debt option offered without checking `debt_limit`/available credit (server rejects). | `cartPage` |
| G-13 | Release APK is signed with a throw-away debug key generated per CI run → installs cannot be upgraded in place. | workflow |
| G-14 | Workflow only runs on branch `feat/flutter-native-app` or manually, and never inspects permissions / version / ABI list beyond a `grep`. | workflow |
| G-15 | No `Localizations` delegates (system menus/pickers not Arabic); manual `Directionality` wrappers instead. | `main.dart` |
| G-00 | `flutter_app/lib/main.dart` did not compile (two missing closing parentheses), so the original Flutter app could never build. | baseline `main.dart` |
| G-16 | `package:http` falls back to Latin-1 when the server sends no charset, which garbles every Arabic message if `Response.body` is used. The new client decodes `bodyBytes` as UTF-8 and sends UTF-8 bytes. | `core/api_client.dart` |
| G-17 | The baseline `test/widget_test.dart` used `CircularProgressIndicator` without importing Material, so it could not compile. Replaced by a complete test suite. | baseline test |
| G-18 | Found while writing tests for the rebuilt client and fixed before release: a malformed pasted invitation link (`%ZZ`, a lone `%`, non-ASCII text) made `Uri.splitQueryString` throw `ArgumentError`, which would have left the registration screen stuck on "busy". | `core/referral.dart`, `test/referral_test.dart` |

## H. CI/CD workflows

| ID | Workflow | Must keep |
|----|----------|-----------|
| H-01 | `.github/workflows/next-build.yml` | unchanged |
| H-02 | `.github/workflows/android-native.yml` (Expo) | unchanged |
| H-03 | `.github/workflows/flutter-android.yml` | still: Flutter stable, `flutter create` platform generation, analyze, test, ARM32+ARM64 release build, `unzip -t`, `apksigner verify`, ABI check, upload artifact only after checks. **Extended**, never weakened. |

## I. Verification matrix (final, honest)

Legend. **Static** = every Dart file parses, and every identifier, import, constructor and call (named / required /
positional arguments) was resolved against the real Flutter 3.47.7, Dart 3.13 and package sources (done in the
sandbox). **Tests** = covered by the test suite in `flutter_app/test` (written, **not executed** here). **CI** = the
workflow runs analyze, tests, the release build and the APK checks on a real Flutter toolchain.

The sandbox has no Flutter, Dart or Android SDK and cannot download them, so `flutter analyze`, `flutter test`, the
release build and the APK integrity / architecture checks were **not run here**. Nothing below is claimed as passed
unless it says so.

| Area | Preserved / delivered | Static | Tests (not run here) |
|------|----------------------|--------|-----------------------|
| A. Roles: workshop and marketer sign in; admin refused in the app | yes | yes | `app_state_test` (admin session and admin login rejected) |
| A. Workshop registration waits for approval; marketer registration instant | yes | yes | `app_state_test` |
| B. `POST /api/auth` login and register, `client: mobile`, Bearer token | yes | yes | `app_state_test`, `api_client_test` |
| B. `GET`/`PUT /api/auth` cookie-only → Cookie header added | yes | yes | `api_client_test` |
| B. `GET /api/parts`, `/api/orders`, `/api/special-requests` | yes | yes | `app_state_test` |
| B. `POST /api/orders` multipart (`items`, `pay`, `receipt`) | yes | yes | `app_state_test` |
| B. `POST /api/special-requests` multipart with photo | yes | yes | `app_state_test` |
| B. Dashboards `/api/workshop/dashboard`, `/api/marketer/dashboard` | yes | yes | `app_state_test`, `models_test` |
| B. Avatar `GET`/`PUT /api/account/avatar` (JPEG ≤ 1.5 MB) | yes | yes | `api_client_test`, `app_state_test` |
| D. Limits: 100 per line, 50 lines, stock cap, 5 MB images | yes | yes | `app_state_test`, `models_test` |
| D. Debt only for workshops, checked against limit | yes | yes | `cart_test`, `app_state_test` |
| D. Prices and totals computed by the server (only ids and quantities sent) | yes | yes | `app_state_test` |
| F-08..F-12 catalog, cart, order, orders, dashboard | yes | yes | unit tests + `widget_test` smoke test of every tab for both roles |
| F-13 Arabic RTL, dark theme, brand colours | yes (plus light theme) | yes | `widget_test` |
| F-14 original startup test | replaced by a larger suite that still checks the startup spinner | yes | `widget_test` |
| F-15 dependencies kept (`http`, `flutter_secure_storage`, `image_picker`, `cupertino_icons`), `url_launcher` and `flutter_localizations` added | yes | yes | — |
| G-01..G-18 defects | fixed | yes | see tests named above |
| H-01, H-02 workflows | untouched | — | — |
| H-03 `flutter-android.yml` | extended: Java 17, pinned Flutter 3.47.x, Android patch step, test and analyze gates, APK verification script, optional release signing | YAML parsed | CI only |
| Android project generation and patch (`prepare_android.py`) | INTERNET permission, label, `allowBackup=false`, `<queries>`, minSdk ≥ 23, icons, optional signing | tested here on the real Flutter 3.47.7 Android templates, twice (idempotent) | CI only |
| `flutter analyze` | — | **not run** | CI only |
| `flutter test` | — | **not run** | CI only |
| Android release build | — | **not run** | CI only |
| APK integrity and architectures | script written and dry-run on a stub archive | **not run on a real APK** | CI only |

Not ported on purpose: the web account page's device-local e-mail field (not an API feature) and the avatar crop
tool (replaced by the system picker plus a preview; the app resizes and sends a JPEG).
