#!/bin/sh
# Extract hier_test with ext2spice hierarchy on and off. The Metal2 wire on net A is
# 0.5 x 200 um, roughly 100*18.18 + 401*34.798 aF = 15.8 fF of substrate capacitance
# that has to show up on A somewhere.
cd "$(dirname "$0")/.." || exit 1
klayout -b -r gen_hier.py 2>&1 | grep -v "^\[" | tail -2
for mode in off on; do
	d=runs/try13/h$mode; rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read layout/hier_test.gds
load hier_test
select top cell
flatten f
load f
cellname delete hier_test -noprompt
cellname rename f hier_test
select top cell
extract path $PWD/$d
extract all
ext2spice format ngspice
ext2spice hierarchy $mode
ext2spice cthresh 0.01
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
	magic -dnull -noconsole -rcfile "$PDKPATH/libs.tech/magic/$PDK.magicrc" "$d/run.tcl" > "$d/log" 2>&1
	echo "--- hierarchy=$mode ---"
	grep -E "^C|^X|^\.subckt" "$d/out.spice"
done
