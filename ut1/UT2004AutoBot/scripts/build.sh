#!/usr/bin/env bash
# Copies the AutoBot package into a UT2004 install, compiles it with ucc,
# and exports the .ucl cache so all mutators appear in Instant Action -> Mutators.
# Usage: scripts/build.sh <UT2004 dir>     (or set UT2004_DIR)
# Works from WSL (Windows UCC.exe), Linux with Wine, or a native Linux install (ucc-bin).
set -euo pipefail

UT="${1:-${UT2004_DIR:-}}"
if [[ -z "$UT" ]]; then
    echo "usage: $0 <UT2004 dir>   e.g. $0 /mnt/c/UnrealTournament2004" >&2
    exit 1
fi

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SYS="$UT/System"
INI="$SYS/UT2004.ini"
[[ -f "$INI" ]] || { echo "error: $INI not found - is '$UT' a UT2004 install?" >&2; exit 1; }

echo ">> copying package to $UT/AutoBot"
rm -rf "$UT/AutoBot"
cp -r "$REPO/AutoBot" "$UT/AutoBot"

if [[ ! -f "$SYS/AutoBot.ini" ]]; then
    echo ">> installing default System/AutoBot.ini"
    cp "$REPO/System/AutoBot.ini" "$SYS/AutoBot.ini"
else
    echo ">> keeping existing $SYS/AutoBot.ini"
fi

# Register the package: EditPackages=AutoBot must come after stock packages
# in [Editor.EditorEngine], so append it after the last existing EditPackages line.
if ! awk '{ sub(/\r$/, ""); if ($0 == "EditPackages=AutoBot") found=1 } END { exit !found }' "$INI"; then
    echo ">> adding EditPackages=AutoBot to UT2004.ini (backup: UT2004.ini.bak)"
    cp "$INI" "$INI.bak"
    cr=""; grep -q $'\r' "$INI" && cr=$'\r'
    awk -v add="EditPackages=AutoBot$cr" '
        NR == FNR { if (/^\[/) sec = /^\[Editor\.EditorEngine\]/; if (sec && /^EditPackages=/) last = FNR; next }
        { print } FNR == last { print add }
        END { if (!last) exit 1 }
    ' "$INI" "$INI" > "$INI.tmp" || { rm -f "$INI.tmp"; echo "error: no EditPackages in [Editor.EditorEngine]" >&2; exit 1; }
    mv "$INI.tmp" "$INI"
fi

# ucc only rebuilds packages whose .u is missing
rm -f "$SYS/AutoBot.u" "$SYS/AutoBot.ucl"

cd "$SYS"
UCC_WIN=""
if [[ -f UCC.exe ]]; then
    UCC_WIN=./UCC.exe
elif [[ -f ucc.exe ]]; then
    UCC_WIN=./ucc.exe
fi

if [[ -n "$UCC_WIN" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    ucc=("$UCC_WIN")
elif [[ -x ucc-bin ]]; then
    ucc=(./ucc-bin)
elif [[ -n "$UCC_WIN" ]] && command -v wine >/dev/null; then
    ucc=(wine "$UCC_WIN")
else
    echo "error: no usable ucc (need UCC.exe under WSL, ucc-bin, or wine + UCC.exe)" >&2
    exit 1
fi

echo ">> ${ucc[*]} make"
"${ucc[@]}" make </dev/null
[[ -f AutoBot.u ]] || { echo "error: AutoBot.u was not produced - check the ucc output above" >&2; exit 1; }

echo ">> ${ucc[*]} exportcache -v AutoBot.u"
"${ucc[@]}" exportcache -v AutoBot.u </dev/null

echo ">> done: $SYS/AutoBot.u"
[[ -f AutoBot.ucl ]] && echo ">> cache: $SYS/AutoBot.ucl"
