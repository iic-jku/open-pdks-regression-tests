#!/bin/sh
# Which extresist knob turns a correct 3-arm star into a 2-resistor chain?
cd "$(dirname "$0")/.." || exit 1
mkdir -p runs/try7
for cell in res_tee_m1 tee_asym_m1 cross_m1 res_long3_m1; do
	echo "===== $cell ====="
	for set in "0 0 0" "0 1000 0" "0 0 1" "10000 0 0" "10000 1000 0" "10000 1000 1" "10000 0 1" "1 0 0"; do
		set -- $set
		thr=$1; mr=$2; md=$3
		d=runs/try7/${cell}_${thr}_${mr}_${md}
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
		printf '  t=%-6s r=%-5s y=%-2s  nR=%s  %s\n' "$thr" "$mr" "$md" \
			"$(grep -c '^R' "$d/out.spice" 2>/dev/null)" \
			"$(grep -h '^R' "$d/out.spice" 2>/dev/null | tr '\n' '|')"
	done
done
