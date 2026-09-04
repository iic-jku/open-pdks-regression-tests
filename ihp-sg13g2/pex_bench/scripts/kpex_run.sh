#!/bin/sh
# Run the kpex FasterCap engine over the bench, at the coarse default triangulation
# and at a refined one, so the mesh sensitivity of every number is visible.
# Note: FasterCap runs in auto mode (-a<tolerance>), which overrides -m and -d, so
# kpex's --mesh has no effect. --delaunay_amax is the knob that discretises the geometry.
cd "$(dirname "$0")/.." || exit 1
OUT=${OUT:-kpex_bench}
AMAX_LIST=${AMAX_LIST:-"50 2"}
mkdir -p $OUT

CELLS="capsub_m1 capsub_m2 capsub_m3 capsub_m4 capsub_m5 capsub_tm1 capsub_tm2
       overlap_m1_m2 overlap_m2_m3 overlap_m3_m4 overlap_m4_m5 overlap_m5_tm1
       overlap_tm1_tm2 overlap_m1_m3 overlap_m1_tm1
       sidewall_m1_s0p2 sidewall_m1_s0p4 sidewall_m1_s0p8 sidewall_m1_s1p6 sidewall_m1_s3p2"

for cell in $CELLS; do
	for amax in $AMAX_LIST; do
		d=$OUT/${cell}_a${amax}
		[ -f "$d/done" ] && continue
		mkdir -p "$d"
		/usr/bin/time -f "%e" -o "$d/secs" \
		kpex --pdk ihp-sg13g2 --cell "$cell" --gds "layout/$cell.gds" --fastercap \
			--delaunay_amax "$amax" --delaunay_b 0.5 --tolerance 0.05 \
			--out_dir "$d" --out_spice "$d/out.spice" > "$d/log" 2>&1
		echo $? > "$d/done"
		printf '%-30s amax=%-4s exit=%s\n' "$cell" "$amax" "$(cat "$d/done")"
	done
done
echo "kpex bench done"
