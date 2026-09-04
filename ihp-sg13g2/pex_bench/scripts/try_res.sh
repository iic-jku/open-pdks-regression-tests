#!/bin/sh
# Sweep extresist settings on res_m1 to find what makes Magic emit resistors.
cd "$(dirname "$0")/.." || exit 1
mkdir -p try
run() {
	tag=$1; thr=$2; mr=$3; md=$4; extra=$5
	d=try/$tag
	rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read layout/res_m1.gds
load res_m1
select top cell
flatten res_m1_flat
load res_m1_flat
cellname delete res_m1
cellname rename res_m1_flat res_m1
select top cell
extract path $PWD/$d
$extra
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
	printf '%-28s R=%-3s C=%-3s | %s\n' "$tag" \
		"$(grep -c '^R' "$d/out.spice" 2>/dev/null)" \
		"$(grep -c '^C' "$d/out.spice" 2>/dev/null)" \
		"$(grep -E 'Nets extracted|Nets output' "$d/log" | tr '\n' ' ')"
}

run lvs_t1_r1_y0      1     1     0  "ext2spice lvs"
run lvs_default   10000  1000     1  "ext2spice lvs"
run lvs_t1_r1_y1      1     1     1  "ext2spice lvs"
run lvs_t0_r0_y0      0     0     0  "ext2spice lvs"
run nolvs_t1_r1_y0    1     1     0  ""
run nolvs_default 10000  1000     1  ""
run nolvs_t0_r0_y0    0     0     0  ""
