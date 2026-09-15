#!/bin/sh
# Does the explicit "sidewall" keyword give the same answer as "defaultsidewall"?
# Both are written with the same coefficient; Magic halves the parsed value on the
# assumption that each edge pair is visited twice.
cd "$(dirname "$0")/.." || exit 1
rm -rf techtest && mkdir -p techtest
cp -r "$PDKPATH/libs.tech/magic" techtest/magic
E=techtest/magic/ihp-sg13g2-extract.tech

variant() {
	tag=$1; line=$2
	cp "$E" "$E.bak"
	# replace only the metal1 sidewall entry in the nominal () variant
	python3 - "$E" "$line" <<'PY'
import sys
path, new = sys.argv[1], sys.argv[2]
src = open(path).read()
old = " defaultsidewall    allm1 metal1 28.735 -0.057"
assert src.count(old) == 1, src.count(old)
open(path, "w").write(src.replace(old, new))
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

echo "L = 50 um, W = 0.5 um, separation 0.8 um.  Coupling cap C0:"
variant default_28.735 " defaultsidewall    allm1 metal1 28.735 -0.057"
variant default_57.470 " defaultsidewall    allm1 metal1 57.470 -0.057"
variant explicit_28.735 " sidewall allm1 space allm1 space 28.735 -0.057"
variant explicit_swapped " sidewall allm1 space space allm1 28.735 -0.057"
echo
echo "tech-file formula, unhalved:  28.735 * 50 / (0.8 - 0.057) = $(python3 -c 'print(28.735*50/0.743)') aF"
echo "tech-file formula, halved  :  14.3675 * 50 / (0.8 - 0.05) = $(python3 -c 'print(14.3675*50/0.75)') aF"
