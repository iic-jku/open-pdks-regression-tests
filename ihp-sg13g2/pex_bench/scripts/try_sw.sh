#!/bin/sh
# SPDX-FileCopyrightText: 2026 Julian Schwarz, Simon Dorrer, and Harald Pretl
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0
#
# Does the explicit "sidewall" keyword give the same answer as "defaultsidewall"?
# Magic 8.3.679 to 8.3.692 halved the parsed value on the assumption that each edge pair is visited twice.
cd "$(dirname "$0")/.." || exit 1
rm -rf techtest && mkdir -p techtest
cp -r "$PDKPATH/libs.tech/magic" techtest/magic
E=techtest/magic/ihp-sg13g2-extract.tech

# line index, coefficient and offset of the metal1 sidewall in the nominal () variant, read from the deck so that a refit does not break the script
set -- $(python3 - "$E" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(lines) if re.fullmatch(r"variants \(\)\s*", l))
for i in range(start, len(lines)):
    m = re.fullmatch(r"\s*defaultsidewall\s+allm1\s+metal1\s+(\S+)\s+(\S+)\s*", lines[i])
    if m:
        print(i, m.group(1), m.group(2))
        break
PY
)
N=$1; K=$2; OFF=$3
if [ -z "$OFF" ]; then echo "no metal1 sidewall line in the () variant of $E"; exit 1; fi
K2=$(python3 -c "print(round(2 * $K, 6))")

variant() {
	tag=$1; line=$2
	cp "$E" "$E.bak"
	python3 - "$E" "$N" "$line" <<'PY'
import sys
path, n, new = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lines = open(path, encoding="utf-8").read().split("\n")
lines[n] = new
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
	d=techtest/$tag
	rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read layout/sidewall_m1_s0p8.gds
load sidewall_m1_s0p8
select top cell
flatten f
load f
cellname delete sidewall_m1_s0p8
cellname rename f sw
select top cell
extract path $PWD/$d
ext2spice lvs
extract all
ext2spice cthresh 0.01
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
	magic -dnull -noconsole -rcfile "$PWD/techtest/magic/ihp-sg13g2.magicrc" "$d/run.tcl" > "$d/log" 2>&1
	printf '%-24s %s\n' "$tag" "$(grep -h '^C0' "$d/out.spice" 2>/dev/null)"
	mv "$E.bak" "$E"
}

echo "L = 50 um, W = 0.5 um, separation 0.8 um, deck: defaultsidewall allm1 metal1 $K $OFF.  Coupling cap C0:"
variant default_x1 " defaultsidewall    allm1 metal1 $K $OFF"
variant default_x2 " defaultsidewall    allm1 metal1 $K2 $OFF"
variant explicit_x1 " sidewall allm1 space allm1 space $K $OFF"
variant explicit_swapped " sidewall allm1 space space allm1 $K $OFF"
echo
echo "tech-file formula, full (Magic 8.3.693 on):        $K * 50 / (0.8 + $OFF) = $(python3 -c "print($K * 50 / (0.8 + $OFF))") aF"
echo "tech-file formula, halved (Magic 8.3.679 to 8.3.692, which also rounded the offset): $(python3 -c "print($K * 25 / (0.8 + $OFF))") aF"
