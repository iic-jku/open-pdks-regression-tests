#!/bin/sh
# Map the extresist threshold / mindelay gate on a 2-port wire and a 3-port tee.
cd "$(dirname "$0")/.." || exit 1
mkdir -p runs/try3
run() {
	cell=$1; thr=$2; mr=$3; md=$4
	d=runs/try3/${cell}_t${thr}_r${mr}_y${md}
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
	printf '%-14s t=%-7s r=%-5s y=%-4s nR=%-2s  %s\n' "$cell" "$thr" "$mr" "$md" \
		"$(grep -c '^R' "$d/out.spice" 2>/dev/null)" \
		"$(grep -h '^R' "$d/out.spice" 2>/dev/null | tr '\n' ' ')"
}

echo "=== 2-port wire res_m1 (11 Ohm, 11.5 fF): threshold sweep at mindelay=0 ==="
for t in 0 1 10 100 1000 10000 100000; do run res_m1 $t 1000 0; done
echo "=== 2-port wire res_m1: mindelay sweep at threshold=0 ==="
for y in 0 1 2 10; do run res_m1 0 1000 $y; done
echo "=== 2-port wire res_long_m1 (110 Ohm, 115 fF, delay 12.6 ps) ==="
for t in 0 10000; do for y in 0 1; do run res_long_m1 $t 1000 $y; done; done
echo "=== 3-port tee res_tee_m1: threshold sweep at mindelay=1 ==="
for t in 0 10000 100000 10000000; do run res_tee_m1 $t 1000 1; done
