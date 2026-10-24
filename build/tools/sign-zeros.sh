#!/bin/bash
#
# Sign a ZeroS build with the release keys and package it (from Phase 3A).
#
# Run on the build server from the top of the tree, in the shell where lunch
# ran, after:
#   m installclean && m target-files-package otatools
#
#   vendor/zeros/build/tools/sign-zeros.sh <key-dir>
#
# <key-dir> holds the keys made by ~/rom/tools/make-zeros-keys.sh on the Mac
# (HANDBOOK.md section 11). They are copied to /dev/shm for this step only and
# deleted afterwards; this script reads them in place and never copies, prints
# or keeps key material.
#
# Follows LineageOS's "Signing Builds" page for 24.0: every APK and APEX is
# re-signed with ZeroS's keys and recovery gets ZeroS's OTA key. Presigned
# apps (the Google set, Gboard, Cromite) keep their publishers' signatures.
# The APEX list comes from the key directory itself (one <name>.pem payload
# key per APEX), so it cannot drift from the keys.
#
# Output in $OUT/zeros-signed/:
#   ZeroS-<version>.zip and .sha256sum, recovery.img, boot.img, dtbo.img,
#   signed-target_files.zip (kept for incremental updates later)
#
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

KEYS=${1:?usage: sign-zeros.sh <key-dir>}
: "${OUT:?run lunch first (OUT is not set)}"

for f in releasekey platform shared media networkstack; do
    for ext in pk8 x509.pem; do
        [ -f "$KEYS/$f.$ext" ] || { echo "error: $KEYS/$f.$ext is missing" >&2; exit 1; }
    done
done

tf=$(ls -t "$OUT"/obj/PACKAGING/target_files_intermediates/*-target_files*.zip 2>/dev/null | head -n1)
[ -n "$tf" ] || { echo "error: no target files; run m target-files-package otatools" >&2; exit 1; }

work="$OUT/zeros-signed"
rm -rf "$work"
mkdir -p "$work"

# APKs inside APEXes and mainline modules that LineageOS signs with releasekey
apks="com.android.appsearch.apk.apk AdServicesApk.apk FederatedCompute.apk HalfSheetUX.apk
      HealthConnectBackupRestore.apk HealthConnectController.apk OsuLogin.apk
      SafetyCenterResources.apk ServiceConnectivityResources.apk ServiceUwbResources.apk
      ServiceWifiResources.apk TelecomServiceResources.apk TelecomUi.apk WebAppService.apk
      WifiDialog.apk"

args=()
for a in $apks; do
    args+=(--extra_apks "$a=$KEYS/releasekey")
done
n=0
for pem in "$KEYS"/*.pem; do
    case "$pem" in *.x509.pem) continue ;; esac
    name=$(basename "$pem" .pem)
    args+=(--extra_apks "$name.apex=$KEYS/$name"
           --extra_apex_payload_key "$name.apex=$KEYS/$name.pem")
    n=$((n + 1))
done

echo "==> Signing $(basename "$tf") (APEX keys: $n)"
sign_target_files_apks -o -d "$KEYS" "${args[@]}" "$tf" "$work/signed-target_files.zip"

version=$(unzip -p "$work/signed-target_files.zip" SYSTEM/build.prop | sed -n 's/^ro\.zeros\.version=//p')
[ -n "$version" ] || { echo "error: ro.zeros.version not found in the signed target files" >&2; exit 1; }
zip="$work/ZeroS-$version.zip"

echo "==> Packaging $(basename "$zip")"
ota_from_target_files -k "$KEYS/releasekey" --block --backup=true \
    "$work/signed-target_files.zip" "$zip"

echo "==> Extracting images"
img_from_target_files "$work/signed-target_files.zip" "$work/signed-img.zip"
unzip -o -q -j "$work/signed-img.zip" recovery.img boot.img dtbo.img -d "$work"
rm -f "$work/signed-img.zip"

(cd "$work" && sha256sum "$(basename "$zip")" > "$(basename "$zip").sha256sum" \
    && sha256sum recovery.img boot.img dtbo.img "$(basename "$zip")" > SHA256SUMS)

# Checks: recovery trusts ZeroS's release key, and the platform key really
# changed. Fingerprints only (public), never key material.
fp() { openssl x509 -noout -fingerprint -sha256 -in "$1" | cut -d= -f2 | tr -d : | tr A-F a-f; }
want_release=$(fp "$KEYS/releasekey.x509.pem")
got_ota=$(unzip -p "$work/signed-target_files.zip" SYSTEM/etc/security/otacerts.zip > "$work/.otacerts.zip" \
    && unzip -p "$work/.otacerts.zip" | openssl x509 -noout -fingerprint -sha256 | cut -d= -f2 | tr -d : | tr A-F a-f)
rm -f "$work/.otacerts.zip"
[ "$got_ota" = "$want_release" ] || { echo "error: OTA certificate is not ZeroS's release key" >&2; exit 1; }
echo "ok: OTA updates must be signed with ZeroS's release key ($want_release)"

if command -v apksigner >/dev/null; then
    unzip -p "$work/signed-target_files.zip" SYSTEM/framework/framework-res.apk > "$work/.framework-res.apk"
    got_platform=$(apksigner verify --print-certs "$work/.framework-res.apk" \
        | sed -n 's/.*certificate SHA-256 digest: //p' | head -n1)
    rm -f "$work/.framework-res.apk"
    [ "$got_platform" = "$(fp "$KEYS/platform.x509.pem")" ] \
        || { echo "error: framework-res.apk is not signed with ZeroS's platform key" >&2; exit 1; }
    echo "ok: system signed with ZeroS's platform key ($got_platform)"
fi

echo "==> Done: $work"
cat "$work/SHA256SUMS"
