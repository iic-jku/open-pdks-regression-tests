#!/bin/sh
# Refined FasterCap points for the spacings the convergence study did not cover,
# so the whole sidewall sweep can be quoted at a mesh where the answer has settled.
cd "$(dirname "$0")/.." || exit 1
mkdir -p kpex_conv
for tag in 0p4 1p6 3p2; do
	cell=sidewall_m1_s$tag
	for amax in 0.5 0.1; do
		d=kpex_conv/${cell}_a${amax}_b0.5_t0.01
		[ -f "$d/done" ] && continue
		mkdir -p "$d"
		/usr/bin/time -f "%e" -o "$d/secs" \
		kpex --pdk ihp-sg13g2 --cell "$cell" --gds "layout/$cell.gds" --fastercap \
			--delaunay_amax "$amax" --delaunay_b 0.5 --tolerance 0.01 \
			--out_dir "$d" --out_spice "$d/out.spice" > "$d/log" 2>&1
		echo $? > "$d/done"
		printf '%-24s amax=%-4s exit=%s\n' "$cell" "$amax" "$(cat "$d/done")"
	done
done
# and a matching tight point for the two already-swept spacings, for a uniform row
for tag in 0p2 0p8; do
	cell=sidewall_m1_s$tag
	d=kpex_conv/${cell}_a0.1_b0.5_t0.01
	[ -f "$d/done" ] && continue
	mkdir -p "$d"
	kpex --pdk ihp-sg13g2 --cell "$cell" --gds "layout/$cell.gds" --fastercap \
		--delaunay_amax 0.1 --delaunay_b 0.5 --tolerance 0.01 \
		--out_dir "$d" --out_spice "$d/out.spice" > "$d/log" 2>&1
	echo $? > "$d/done"
done
echo "sidewall refinement done"
