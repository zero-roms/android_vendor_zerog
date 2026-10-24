#!/bin/bash
#
# Build NotallyX, the notes app ZeroS ships, from source and place the APK
# where prebuilt/apps/NotallyX/Android.bp expects it. The ROM build re-signs
# it with its default app key.
#
# SPDX-License-Identifier: Apache-2.0
#
# Usage: build-notallyx.sh <dir-with-sources>
#   <dir-with-sources> holds the clone NotallyX/, checked out at the tag
#   pinned below.
#
# Needs: JDK 17 or newer (JAVA_HOME), Android SDK (ANDROID_HOME), network for
# Gradle's first run.
#
# NotallyX's release build requires a signing key, so a throwaway key is
# generated for the Gradle run; the ROM build replaces that signature. After
# building, the APK's contents (everything except the signature files) are
# compared with the APK NotallyX publishes for the same tag, when that file is
# present as NotallyX.upstream.apk next to the clone.
#

set -euo pipefail

SRC=${1:?usage: build-notallyx.sh <dir-with-sources>}
HERE=$(cd "$(dirname "$0")" && pwd)

NAME=NotallyX
DIR=NotallyX
TAG=v7.11.3
COMMIT=f8c9cea0fdc35be7f495bb323ddab50632bdc373

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

repo="$SRC/$DIR"
echo "==> $NAME ($DIR @ $TAG)"

head=$(git -C "$repo" rev-parse HEAD)
if [ "$head" != "$COMMIT" ]; then
    echo "error: $repo is at $head, expected tag $TAG ($COMMIT)" >&2; exit 1
fi
if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "error: $repo has local changes" >&2; exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
"$JAVA_HOME/bin/keytool" -genkeypair -keystore "$tmp/throwaway.jks" \
    -storepass throwaway -keypass throwaway -alias throwaway \
    -keyalg RSA -keysize 2048 -validity 1 -dname "CN=throwaway" >/dev/null 2>&1

(cd "$repo" && ./gradlew --no-daemon --max-workers=4 -q assembleRelease \
    -PRELEASE_STORE_FILE="$tmp/throwaway.jks" -PRELEASE_STORE_PASSWORD=throwaway \
    -PRELEASE_KEY_ALIAS=throwaway -PRELEASE_KEY_PASSWORD=throwaway)

apk=$(ls "$repo"/app/build/outputs/apk/release/*.apk | head -n1)
# The release build rewrites two tracked files (app.lastVersionName in
# gradle.properties, and the R8 mapping); restore them so the clean-tree check
# passes next time.
git -C "$repo" checkout -- gradle.properties app/obfuscation
mkdir -p "$HERE/$NAME"
cp "$apk" "$HERE/$NAME/$NAME.apk"
sum=$(shasum -a 256 "$HERE/$NAME/$NAME.apk" | awk '{print $1}')

upstream="$SRC/$NAME.upstream.apk"
check="not checked (no $NAME.upstream.apk)"
if [ -f "$upstream" ]; then
    check=$(compare_contents "$HERE/$NAME/$NAME.apk" "$upstream")
fi

cat > "$HERE/$NAME/SOURCE" <<EOF
app:     $NAME
source:  https://github.com/Crustack/NotallyX
tag:     $TAG
commit:  $head
build:   release, signed with a throwaway key (re-signed by the ROM build)
sha256:  $sum
upstream contents check: $check
built:   $(date -u +%Y-%m-%dT%H:%MZ) with $("$JAVA_HOME/bin/java" -version 2>&1 | head -n1)
EOF
echo "    $sum"
echo "    upstream contents check: $check"
