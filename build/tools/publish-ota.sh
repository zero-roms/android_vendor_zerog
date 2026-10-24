#!/bin/bash
#
# Publish a signed ZeroS OTA zip for LineageOS's Updater (Phase 3B).
#
#   publish-ota.sh [--dry-run] <ZeroS-*.zip>
#
# Run on the Mac after sign-zeros.sh's output is copied back and verified.
# Settings come from $ZEROS_OTA_ENV (default ~/rom-keys/zeros-ota.env, never
# in git), which sets:
#   ZEROS_OTA_BUCKET  Cloud Storage bucket
#   ZEROS_OTA_PREFIX  unlisted path prefix (random)
#   ZEROS_OTA_KEEP    builds kept in the index (optional, default 2)
# The matching build setting is
#   ZEROS_UPDATER_URI=https://storage.googleapis.com/<bucket>/<prefix>/{device}/{type}.json
# The bucket grants anonymous users storage.objects.get only (no listing), so
# files are reachable only by their exact address.
#
# Checks the zip (its OTA certificate must be ZeroS's release key, its SHA-256
# must match the .sha256sum written by sign-zeros.sh), uploads it, then
# rewrites the device's index (newest first) and deletes zips that dropped out
# of it. The index goes up after the zip, so it never points at a missing file.
# --dry-run does all the checks and prints the new index without writing.
#
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

dry_run=false
if [ "${1:-}" = "--dry-run" ]; then
    dry_run=true
    shift
fi
if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    echo "usage: $0 [--dry-run] <ZeroS-*.zip>" >&2
    exit 2
fi
zip=$1
name=$(basename "$zip")

env_file=${ZEROS_OTA_ENV:-$HOME/rom-keys/zeros-ota.env}
keys=${ZEROS_KEYS:-$HOME/rom-keys/zeros}
# shellcheck disable=SC1090
. "$env_file"
: "${ZEROS_OTA_BUCKET:?not set in $env_file}" "${ZEROS_OTA_PREFIX:?not set in $env_file}"
keep=${ZEROS_OTA_KEEP:-2}

G=${GCLOUD:-$(command -v gcloud || echo /opt/homebrew/share/google-cloud-sdk/bin/gcloud)}
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }
certfp() { openssl x509 -noout -fingerprint -sha256 | cut -d= -f2 | tr -d : | tr A-F a-f; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "==> Checking $name"
unzip -p "$zip" META-INF/com/android/metadata > "$work/metadata"
got=$(unzip -p "$zip" META-INF/com/android/otacert | certfp)
want=$(certfp < "$keys/releasekey.x509.pem")
if [ "$got" != "$want" ]; then
    echo "FAILED: the zip's OTA certificate is not ZeroS's release key" >&2
    exit 1
fi
sum=$(sha256 "$zip")
if [ -f "$zip.sha256sum" ] && [ "$(cut -d' ' -f1 "$zip.sha256sum")" != "$sum" ]; then
    echo "FAILED: SHA-256 differs from $name.sha256sum" >&2
    exit 1
fi
size=$(wc -c < "$zip" | tr -d ' ')

meta() { sed -n "s/^$1=//p" "$work/metadata" | tr -d ' '; }
device=$(meta pre-device | cut -d, -f1)
timestamp=$(meta post-timestamp)
sdk=$(meta post-sdk-level)
patch=$(meta post-security-patch-level)
version=$(echo "$name" | sed -n 's/^Zero[A-Z]*-\([0-9]*\.[0-9]*\.[0-9]*\)-.*/\1/p')
# ZeroS-<version>-<date>-<type>-<device>.zip; the Updater compares type with
# ro.lineage.releasetype, ignoring case
type=$(echo "$name" | awk -F- 'NF >= 5 {print tolower($(NF-1))}')
for v in device timestamp sdk patch version type; do
    if [ -z "${!v}" ]; then
        echo "FAILED: could not read $v from $name" >&2
        exit 1
    fi
done

base="gs://$ZEROS_OTA_BUCKET/$ZEROS_OTA_PREFIX/$device"
public="https://storage.googleapis.com/$ZEROS_OTA_BUCKET/$ZEROS_OTA_PREFIX/$device"
index="$type.json"
echo "    ZeroS $version for $device ($type), built $(date -u -r "$timestamp" '+%Y-%m-%d %H:%M UTC' 2>/dev/null || date -u -d "@$timestamp"), SDK $sdk, patch $patch, $size bytes"

# Current index; only a missing one counts as empty, any other error stops
# here so that a failed read never drops published builds
if ! "$G" storage cat "$base/$index" > "$work/old.json" 2> "$work/cat.err"; then
    if grep -qiE 'not found|matched no objects|no urls matched|does not exist' "$work/cat.err"; then
        echo "[]" > "$work/old.json"
    else
        cat "$work/cat.err" >&2
        echo "FAILED: could not read the current index" >&2
        exit 1
    fi
fi

python3 -I - "$work/old.json" "$work/new.json" "$work/drop.txt" "$keep" \
    "$timestamp" "$type" "$version" "$name" "$patch" "$sdk" "$sum" "$size" "$public/$name" <<'EOF'
import json, sys
old_path, new_path, drop_path, keep = sys.argv[1:5]
ts, typ, version, name, patch, sdk, sha, size, url = sys.argv[5:14]
entry = {
    "datetime": int(ts),
    "files": [{
        "filename": name,
        "os_patch_level": patch,
        "os_sdk_level": int(sdk),
        "sha256": sha,
        "size": int(size),
        "url": url,
    }],
    "type": typ,
    "version": version,
}
old = json.load(open(old_path))
builds = [b for b in old if b["files"][0]["filename"] != name and b["datetime"] != entry["datetime"]]
builds.append(entry)
builds.sort(key=lambda b: b["datetime"], reverse=True)
kept, dropped = builds[:int(keep)], builds[int(keep):]
json.dump(kept, open(new_path, "w"), indent=2)
with open(drop_path, "w") as f:
    for b in dropped:
        f.write(b["files"][0]["filename"] + "\n")
EOF

echo "==> New index ($index):"
cat "$work/new.json"
echo
if [ -s "$work/drop.txt" ]; then
    echo "==> Dropping: $(tr '\n' ' ' < "$work/drop.txt")"
fi

if $dry_run; then
    echo "==> Dry run: nothing uploaded"
    exit 0
fi

echo "==> Uploading $name"
"$G" storage cp --content-type=application/zip "$zip" "$base/$name"
echo "==> Uploading index"
"$G" storage cp --content-type=application/json --cache-control="no-cache, max-age=0" \
    "$work/new.json" "$base/$index"
while read -r old_name; do
    [ -n "$old_name" ] && "$G" storage rm "$base/$old_name"
done < "$work/drop.txt"

echo "==> Verifying public access"
curl -fsS "$public/$index" | python3 -I -c 'import json,sys; b=json.load(sys.stdin)[0]; print("    index:", b["version"], b["files"][0]["filename"])'
got_size=$(curl -fsSI "$public/$name" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}')
if [ "$got_size" != "$size" ]; then
    echo "FAILED: public zip size $got_size, expected $size" >&2
    exit 1
fi
echo "    zip: $got_size bytes, reachable"
echo "==> Published ZeroS $version"
