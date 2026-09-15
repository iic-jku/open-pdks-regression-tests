#!/bin/sh
# Find which extresist setting makes the coupling cap also appear lumped to substrate.
cd "$(dirname "$0")/.." || exit 1
mkdir -p runs/try8
cell=sidewall_m1_s0p2
for set in "0 0 0" "0 0 1" "0 1000 0" "1 0 0" "10000 0 0" "10000 1000 0" "10000 1000 1" "10000 1000 2"; do
	set -- $set
	thr=$1; mr=$2; md=$3
	d=runs/try8/${thr}_${mr}_${md}
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
	printf 't=%-6s r=%-5s y=%-2s | %s\n' "$thr" "$mr" "$md" \
		"$(grep -h '^C' "$d/out.spice" 2>/dev/null | tr '\n' ' ')"
done
echo "--- reference: no resistance extraction at all (mode 2) ---"
d=runs/try8/mode2; rm -rf "$d"; mkdir -p "$d"
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
extract all
ext2spice cthresh 0.01
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
magic -dnull -noconsole -rcfile "$PDKPATH/libs.tech/magic/$PDK.magicrc" "$d/run.tcl" > "$d/log" 2>&1
grep -h '^C' "$d/out.spice"
