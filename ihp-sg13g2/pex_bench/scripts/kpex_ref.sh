#!/bin/sh
# Convergence points for the structures whose amax=50 to amax=2 step was still large.
cd "$(dirname "$0")/.." || exit 1
for job in "capsub_m1 0.5" "capsub_m2 0.5" "overlap_m1_m2 0.5" "capsub_m1 0.2"; do
	set -- $job
	cell=$1; amax=$2
	d=kpex_conv/${cell}_a${amax}_b0.5_t0.01
	[ -f "$d/done" ] && continue
	mkdir -p "$d"
	/usr/bin/time -f "%e" -o "$d/secs" \
	kpex --pdk ihp-sg13g2 --cell "$cell" --gds "layout/$cell.gds" --fastercap \
		--delaunay_amax "$amax" --delaunay_b 0.5 --tolerance 0.01 \
		--out_dir "$d" --out_spice "$d/out.spice" > "$d/log" 2>&1
	echo $? > "$d/done"
	printf '%-22s amax=%-5s exit=%s\n' "$cell" "$amax" "$(cat "$d/done")"
done
echo "refinement done"
