#!/usr/bin/env bash
# Verifies a built release APK before it is handed to anyone:
#   * the ZIP archive is intact,
#   * it carries a valid Android signature (v2 or v3),
#   * package name, app label, INTERNET permission and SDK levels are what the app needs,
#   * it contains native code for exactly the supported CPU architectures (armeabi-v7a and arm64-v8a),
#   * the Dart code, the Flutter engine and the bundled Arabic font are inside,
#   * ZIP alignment is correct,
# and finally writes the SHA-256 next to the APK.
#
# Usage: tool/verify_apk.sh path/to/app-release.apk
# Environment (optional): EXPECTED_PACKAGE, EXPECTED_LABEL, EXPECTED_ABIS, ANDROID_HOME / ANDROID_SDK_ROOT.
set -uo pipefail

APK="${1:?usage: verify_apk.sh path/to/app-release.apk}"
EXPECTED_PACKAGE="${EXPECTED_PACKAGE:-com.eurocars.euro_cars}"
EXPECTED_LABEL="${EXPECTED_LABEL:-EURO CARS}"
EXPECTED_ABIS="${EXPECTED_ABIS:-armeabi-v7a arm64-v8a}"

failures=0
report="$(mktemp)"

say() { printf '%s\n' "$*" | tee -a "$report"; }
pass() { say "PASS  $*"; }
warn() { say "WARN  $*"; }
fail() { say "FAIL  $*"; failures=$((failures + 1)); }

if [ ! -s "$APK" ]; then
  echo "FAIL  $APK does not exist or is empty" >&2
  exit 1
fi

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
tools_dir=""
if [ -n "$sdk" ] && [ -d "$sdk/build-tools" ]; then
  tools_dir="$(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
fi
tool() { [ -n "$tools_dir" ] && [ -x "$tools_dir/$1" ] && echo "$tools_dir/$1"; }

say "APK: $APK"
say "Size: $(stat -c %s "$APK") bytes"
say "Build tools: ${tools_dir:-not found}"
say ""

# 1. Archive integrity
if unzip -tq "$APK" >/dev/null 2>&1; then
  pass "ZIP archive is intact (unzip -t)"
else
  fail "ZIP archive is damaged (unzip -t)"
fi

entries="$(unzip -Z1 "$APK" 2>/dev/null || true)"
has_entry() { printf '%s\n' "$entries" | grep -qx -- "$1"; }

# 2. Signature
apksigner="$(tool apksigner || true)"
if [ -z "$apksigner" ]; then
  fail "apksigner not found, the signature cannot be verified"
else
  signer_output="$("$apksigner" verify --verbose --print-certs "$APK" 2>&1)"
  signer_status=$?
  printf '%s\n' "$signer_output" >>"$report"
  if [ "$signer_status" -ne 0 ]; then
    fail "apksigner verify failed"
  elif printf '%s\n' "$signer_output" | grep -Eq 'Verified using v(2|3) scheme \(APK Signature Scheme v(2|3)\): true'; then
    pass "signature verifies (APK Signature Scheme v2/v3)"
  else
    fail "apksigner reported success but neither the v2 nor the v3 scheme is verified"
  fi
  if printf '%s\n' "$signer_output" | grep -qi 'Android Debug'; then
    warn "signed with the DEBUG key: installable, but add android/key.properties for a release key"
  fi
fi

# 3. Manifest facts
aapt2="$(tool aapt2 || true)"
if [ -z "$aapt2" ]; then
  fail "aapt2 not found, the manifest cannot be inspected"
else
  badging="$("$aapt2" dump badging "$APK" 2>&1)"
  printf '%s\n' "$badging" >>"$report"
  package="$(printf '%s\n' "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)"
  version="$(printf '%s\n' "$badging" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p" | head -n 1)"
  code="$(printf '%s\n' "$badging" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" | head -n 1)"
  min_sdk="$(printf '%s\n' "$badging" | sed -n "s/^sdkVersion:'\([^']*\)'.*/\1/p" | head -n 1)"
  target_sdk="$(printf '%s\n' "$badging" | sed -n "s/^targetSdkVersion:'\([^']*\)'.*/\1/p" | head -n 1)"
  label="$(printf '%s\n' "$badging" | sed -n "s/^application-label:'\([^']*\)'.*/\1/p" | head -n 1)"

  [ "$package" = "$EXPECTED_PACKAGE" ] && pass "package is $package" || fail "package is '$package', expected '$EXPECTED_PACKAGE'"
  [ "$label" = "$EXPECTED_LABEL" ] && pass "app label is '$label'" || fail "app label is '$label', expected '$EXPECTED_LABEL'"
  say "INFO  version $version ($code), minSdk $min_sdk, targetSdk $target_sdk"
  if [ -n "$min_sdk" ] && [ "$min_sdk" -ge 23 ] 2>/dev/null; then
    pass "minSdk $min_sdk is at least 23"
  else
    fail "minSdk '$min_sdk' is below 23 or unknown"
  fi
  if printf '%s\n' "$badging" | grep -q "^uses-permission: name='android.permission.INTERNET'"; then
    pass "INTERNET permission is present (without it the release app has no network)"
  else
    fail "INTERNET permission is missing"
  fi
  if printf '%s\n' "$badging" | grep -q "^uses-permission: name='android.permission.READ_EXTERNAL_STORAGE'"; then
    warn "READ_EXTERNAL_STORAGE is requested, which the app does not need"
  fi

  # 4. Supported architectures (as the manifest tool sees them)
  native="$(printf '%s\n' "$badging" | sed -n "s/^native-code: //p" | tr -d "'")"
  say "INFO  native-code: ${native:-none}"
  for abi in $EXPECTED_ABIS; do
    case " $native " in
      *" $abi "*) pass "native code for $abi is declared" ;;
      *) fail "native code for $abi is missing" ;;
    esac
  done
  for abi in $native; do
    case " $EXPECTED_ABIS " in
      *" $abi "*) ;;
      *) warn "unexpected architecture $abi is included" ;;
    esac
  done
fi

# 5. What must be inside the archive
for abi in $EXPECTED_ABIS; do
  for lib in libflutter.so libapp.so; do
    if has_entry "lib/$abi/$lib"; then
      pass "lib/$abi/$lib is present"
    else
      fail "lib/$abi/$lib is missing"
    fi
  done
done
for entry in classes.dex AndroidManifest.xml \
  assets/flutter_assets/assets/fonts/Tajawal-Regular.ttf \
  assets/flutter_assets/assets/fonts/Tajawal-Bold.ttf; do
  if has_entry "$entry"; then
    pass "$entry is present"
  else
    fail "$entry is missing"
  fi
done

# 6. ZIP alignment (and, informational, the 16 KB page alignment Google Play asks for on new apps)
zipalign="$(tool zipalign || true)"
if [ -z "$zipalign" ]; then
  warn "zipalign not found, alignment was not checked"
else
  if "$zipalign" -c 4 "$APK" >/dev/null 2>&1; then
    pass "ZIP alignment is correct (zipalign -c 4)"
  else
    fail "ZIP alignment check failed (zipalign -c 4)"
  fi
  if "$zipalign" -c -P 16 4 "$APK" >/dev/null 2>&1; then
    pass "native libraries are 16 KB aligned"
  else
    warn "16 KB page alignment could not be confirmed (needs build-tools 35.0.0 or newer)"
  fi
fi

# 7. Checksum
sha="$(sha256sum "$APK" | cut -d ' ' -f 1)"
printf '%s  %s\n' "$sha" "$(basename "$APK")" >"$APK.sha256"
say ""
say "SHA-256: $sha"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### APK verification"
    echo '```'
    cat "$report"
    echo '```'
  } >>"$GITHUB_STEP_SUMMARY"
fi
cp "$report" "$APK.verification.txt"

if [ "$failures" -ne 0 ]; then
  echo "verify_apk.sh: $failures check(s) failed" >&2
  exit 1
fi
echo "verify_apk.sh: all checks passed"
