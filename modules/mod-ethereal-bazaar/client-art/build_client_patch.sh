#!/usr/bin/env bash
# Builds patch-ZG.MPQ: the Groot Coin icon plus the client's own ItemDisplayInfo.dbc with display 990001 appended.
# These two files must reach players before or with the world migration that uses 990001; see README.md.
# Usage: build_client_patch.sh <client Data dir> <mpqcli> <output dir>
set -euo pipefail
data=$1 mpqcli=$2 out=$3
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/x" "$work/build/DBFilesClient" "$work/build/Interface/Icons" "$out"
# patch-M.MPQ held the effective ItemDisplayInfo.dbc on 13 Oct 2026; recheck with apps/coa-dbc/client_dbc.py.
"$mpqcli" extract -f 'DBFilesClient\ItemDisplayInfo.dbc' -o "$work/x" "$data/patch-M.MPQ" >/dev/null
python3 "$here/add_display_990001.py" "$(find "$work/x" -iname ItemDisplayInfo.dbc)" \
    "$work/build/DBFilesClient/ItemDisplayInfo.dbc"
cp "$here/INV_GrootCoin.blp" "$work/build/Interface/Icons/INV_GrootCoin.blp"
rm -f "$out/patch-ZG.MPQ"
"$mpqcli" create -g wow-wotlk -o "$out/patch-ZG.MPQ" "$work/build" >/dev/null
"$mpqcli" list "$out/patch-ZG.MPQ"
