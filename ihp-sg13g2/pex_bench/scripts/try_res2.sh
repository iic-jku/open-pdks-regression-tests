#!/bin/sh
# Isolate which extresist knob suppresses the resistor, and on which topologies.
cd "$(dirname "$0")/.." || exit 1
mkdir -p runs/try2
run() {
	tag=$1; cell=$2; thr=$3; mr=$4; md=$5
	d=runs/try2/$tag
	rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read layout/$cell.gds
load $cell
select top cell
flatten ${cell}_flat
load ${cell}_flat
cellname delete $cell
cellname rename ${cell}_flat $cell
select top cell
extract path $PWD/$d
ext2spice lvs
extresist threshold $thr
extresist mindelay $md
extresist minres $mr
extract do resistance
extract do unique
extract all
ext2spice extresist on
ext2spice cthresh 0.01
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
	magic -dnull -noconsole -rcfile "$PDKPATH/libs.tech/magic/$PDK.magicrc" "$d/run.tcl" > "$d/log" 2>&1
	printf '%-26s %-14s t=%-6s r=%-5s y=%-2s  R=%-2s  %s\n' "$tag" "$cell" "$thr" "$mr" "$md" \
		"$(grep -c '^R' "$d/out.spice" 2>/dev/null)" \
		"$(grep -h '^R' "$d/out.spice" 2>/dev/null | tr '\n' ' ')"
}

echo "--- knob isolation on res_m1 (11 Ohm, 2 ports) ---"
run iso_t0r0y0   res_m1     0    0 0
run iso_t0r1y0   res_m1     0    1 0
run iso_t1r0y0   res_m1     1    0 0
run iso_t0r0y1   res_m1     0    0 1
run iso_tDr0yD   res_m1 10000    0 1
run iso_tDr1yD   res_m1 10000    1 1

echo "--- higher resistance (res_long_m1, 1000 squares = 110 Ohm) ---"
run long_r0      res_long_m1 10000    0 1
run long_r1000   res_long_m1 10000 1000 1
run long_r1      res_long_m1 10000    1 1

echo "--- three-terminal net (res_tee_m1) ---"
run tee_r0       res_tee_m1  10000    0 1
run tee_r1000    res_tee_m1  10000 1000 1
