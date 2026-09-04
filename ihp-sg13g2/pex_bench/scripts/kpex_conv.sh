#!/bin/sh
# Mesh convergence for the kpex FasterCap engine.
# FasterCap runs in auto mode (-a), which overrides -m and -d, so --mesh does nothing.
# The knobs that bite are the KLayout-side triangulation (--delaunay_amax, --delaunay_b)
# and the FasterCap auto tolerance (--tolerance).
cd "$(dirname "$0")/.." || exit 1
OUT=kpex_conv
mkdir -p $OUT

run() {
	cell=$1; amax=$2; b=$3; tol=$4
	tag="${cell}_a${amax}_b${b}_t${tol}"
	d=$OUT/$tag
	[ -f "$d/done" ] && return 0
	mkdir -p "$d"
	/usr/bin/time -f "%e" -o "$d/secs" \
	kpex --pdk ihp-sg13g2 --cell "$cell" --gds "layout/$cell.gds" --fastercap \
		--delaunay_amax "$amax" --delaunay_b "$b" --tolerance "$tol" \
		--out_dir "$d" --out_spice "$d/out.spice" > "$d/log" 2>&1
	echo $? > "$d/done"
}

for cell in sidewall_m1_s0p2 sidewall_m1_s0p8; do
	for amax in 50 10 2 0.5 0.1; do
		run "$cell" "$amax" 0.5 0.05
	done
	run "$cell" 0.5 0.5 0.01
	run "$cell" 0.5 0.5 0.005
	run "$cell" 0.1 0.5 0.01
done
echo "convergence sweep done"
