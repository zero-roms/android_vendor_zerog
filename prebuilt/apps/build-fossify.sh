#!/bin/bash
#
# Build the Fossify apps ZeroS ships, from source, and place the unsigned
# APKs where prebuilt/apps/*/Android.bp expects them. The ROM build re-signs
# them with its default app key.
#
# SPDX-License-Identifier: Apache-2.0
#
# Usage: build-fossify.sh <dir-with-sources>
#   <dir-with-sources> holds the clones fossify-gallery/ and
#   fossify-file-manager/, checked out at the tags pinned below.
#
# Needs: JDK 17 or newer (JAVA_HOME), Android SDK with platform 36
# (ANDROID_HOME), network for Gradle's first run.
#
# After building, each APK's contents (everything except the signature
# files) are compared with the APK Fossify publishes for the same tag, when
# that file is present as <name>.upstream.apk next to the clone. A match
# means we built exactly the app Fossify released.
#

set -euo pipefail

SRC=${1:?usage: build-fossify.sh <dir-with-sources>}
HERE=$(cd "$(dirname "$0")" && pwd)

# name | clone dir | tag | commit (full or short prefix)
APPS=(
    "FossifyGallery|fossify-gallery|1.14.0|f5d52cd"
    "FossifyFileManager|fossify-file-manager|1.6.2|82b3c98"
)

: "${JAVA_HOME:?set JAVA_HOME to a JDK 17+}"
: "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"

compare_contents() {
    # Prints MATCH or the differing entries. Signature files are ignored.
    python3 -I - "$1" "$2" <<'PY'
import sys, zipfile
def entries(path):
    with zipfile.ZipFile(path) as z:
        return {i.filename: i.CRC for i in z.infolist()
                if not i.filename.startswith("META-INF/")}
a, b = entries(sys.argv[1]), entries(sys.argv[2])
diff = sorted(k for k in a.keys() | b.keys() if a.get(k) != b.get(k))
print("MATCH" if not diff else "DIFFER: " + ", ".join(diff[:20]))
PY
}

for entry in "${APPS[@]}"; do
    IFS='|' read -r name dir tag commit <<< "$entry"
    repo="$SRC/$dir"
    echo "==> $name ($dir @ $tag)"

    head=$(git -C "$repo" rev-parse HEAD)
    case "$head" in
        "$commit"*) ;;
        *) echo "error: $repo is at $head, expected tag $tag ($commit)" >&2; exit 1 ;;
    esac
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        echo "error: $repo has local changes" >&2; exit 1
    fi

    (cd "$repo" && ./gradlew --no-daemon --max-workers=4 -q assembleFossRelease)

    apk=$(ls "$repo"/app/build/outputs/apk/foss/release/*-unsigned.apk | head -n1)
    mkdir -p "$HERE/$name"
    cp "$apk" "$HERE/$name/$name.apk"
    sum=$(shasum -a 256 "$HERE/$name/$name.apk" | awk '{print $1}')

    upstream="$SRC/$name.upstream.apk"
    check="not checked (no $name.upstream.apk)"
    if [ -f "$upstream" ]; then
        check=$(compare_contents "$HERE/$name/$name.apk" "$upstream")
    fi

    cat > "$HERE/$name/SOURCE" <<EOF
app:     $name
source:  https://github.com/FossifyOrg/$( [ "$dir" = fossify-gallery ] && echo Gallery || echo File-Manager )
tag:     $tag
commit:  $head
flavour: foss, release, unsigned (re-signed by the ROM build)
sha256:  $sum
upstream contents check: $check
built:   $(date -u +%Y-%m-%dT%H:%MZ) with $("$JAVA_HOME/bin/java" -version 2>&1 | head -n1)
EOF
    echo "    $sum"
    echo "    upstream contents check: $check"
done
