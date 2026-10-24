#!/bin/bash
#
# Rebuild bootanimation.zip (ZeroS boot animation, design B1 "orbit") from
# make-frames.swift. Run on the Mac (needs Swift and macOS Core Text):
#
#   make-bootanimation.sh <Roboto variable TTF>
#
# Roboto is Android's system font (Apache 2.0); the copy used for the shipped
# zip came from ZeroS 0.4.0's /system/fonts/Roboto-Regular.ttf (sha256 in
# SOURCE). Android needs the zip stored without compression.
#
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail
FONT=${1:?usage: make-bootanimation.sh <Roboto variable TTF>}
HERE=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
swift "$HERE/make-frames.swift" "$FONT" "$tmp"
(cd "$tmp" && rm -f "$HERE/bootanimation.zip" && zip -0 -X -q -r "$HERE/bootanimation.zip" desc.txt part0 part1)
echo "bootanimation.zip: $(unzip -l "$HERE/bootanimation.zip" | tail -1 | awk '{print $2}') files, sha256 $(shasum -a 256 "$HERE/bootanimation.zip" | awk '{print $1}')"
