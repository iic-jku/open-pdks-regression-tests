#!/bin/sh
# kpex drives Magic's full-RC extraction with a different recipe than sak-pex.sh:
#   sak-pex:  ext2spice lvs; extresist threshold/mindelay/minres; extract do resistance; extract all
#   kpex:     ext2sim; extresist tolerance 1; extresist all
# Run the kpex recipe on the bench cases that sak-pex gets wrong.
cd "$(dirname "$0")/.." || exit 1
mkdir -p runs/try12

run() {
	cell=$1
	d=runs/try12/$cell
	rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read layout/$cell.gds
load $cell
select top cell
flatten f
load f
cellname delete $cell -noprompt
cellname rename f $cell
select top cell
extract path $PWD/$d
extract all
ext2sim labels on
ext2sim -p $PWD/$d
extresist tolerance 1
extresist all
ext2spice short none
ext2spice merge none
ext2spice cthresh 0.01
ext2spice extresist on
ext2spice subcircuits top on
ext2spice format ngspice
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
	magic -dnull -noconsole -rcfile "$PDKPATH/libs.tech/magic/$PDK.magicrc" "$d/run.tcl" > "$d/log" 2>&1
	echo "### $cell (kpex recipe)"
	grep -E "^R|^C" "$d/out.spice" 2>/dev/null | sed 's/^/    /'
}

run tee_asym_m1
run res_m1
run res_long_m1
run rc_tee_pair_m1
