#!/bin/sh
# Drop the bulky FasterCap intermediates and keep what the numbers are read from:
# the result matrices, the emitted netlists and the run logs.
cd "$(dirname "$0")/.." || exit 1

# the killed capsub convergence points, which never produced a matrix
rm -rf kpex_conv/capsub_m1_a0.5_b0.5_t0.01 kpex_conv/capsub_m1_a0.2_b0.5_t0.01
rm -f ./*.sim ./*.nodes

for d in FasterCap_Input_Files Geometries .kpex_cache; do
	find kpex_bench kpex_conv kpex25 -type d -name "$d" -prune -exec rm -rf {} + 2>/dev/null
done
for f in '*.oas' '*.lvsdb.gz' '*.gds.gz' '*_FasterCap_Output.txt'; do
	find kpex_bench kpex_conv kpex25 -type f -name "$f" -delete 2>/dev/null
done
du -sh .
