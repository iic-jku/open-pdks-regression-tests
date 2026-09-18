#!/bin/sh
# Fresh-directory reproduction of every Magic number the report leans on.
cd "$(dirname "$0")/.." || exit 1
rm -rf runs/rv && mkdir -p runs/rv
show() { printf '%-42s %s\n' "$1" "$(grep -hE '^[RC]' "$2" | tr '\n' ' ')"; }

sak-pex.sh -m 2 -w runs/rv/a layout/capsub_m1.gds >/dev/null 2>&1;       show "A capsub_m1 mode2 (expect 95.4545 / 4.87346)" runs/rv/a/capsub_m1.pex.spice
sak-pex.sh -m 2 -w runs/rv/b layout/sidewall_m1_s0p2.gds >/dev/null 2>&1; show "F sidewall s0p2 mode2 (expect a-b 4.78917)" runs/rv/b/sidewall_m1_s0p2.pex.spice
sak-pex.sh -m 2 -w runs/rv/c layout/sidewall_m1_s0p8.gds >/dev/null 2>&1; show "F sidewall s0p8 mode2 (expect a-b 0.95783)" runs/rv/c/sidewall_m1_s0p8.pex.spice
sak-pex.sh -m 2 -w runs/rv/d layout/overlap_m1_tm1.gds >/dev/null 2>&1;   show "G overlap_m1_tm1 mode2 (expect 1.60235/0.79572)" runs/rv/d/overlap_m1_tm1.pex.spice
sak-pex.sh -m 3 -t 0 -r 0 -y 0 -w runs/rv/e layout/cross_m1.gds >/dev/null 2>&1;        show "D2 cross open gates (expect 4 R, star)" runs/rv/e/cross_m1.pex.spice
sak-pex.sh -m 3 -w runs/rv/f layout/cross_m1.gds >/dev/null 2>&1;                       show "D2 cross shipped defaults (expect 2 R, e absent)" runs/rv/f/cross_m1.pex.spice
sak-pex.sh -m 3 -w runs/rv/g layout/res_long_m1.gds >/dev/null 2>&1;                    show "D2 res_long defaults (expect no R)" runs/rv/g/res_long_m1.pex.spice
sak-pex.sh -m 3 -t 0 -r 0 -y 0 -w runs/rv/h layout/res_long_m1.gds >/dev/null 2>&1;     show "D2 res_long open gates (expect R 109.891)" runs/rv/h/res_long_m1.pex.spice
sak-pex.sh -m 2 -w runs/rv/i layout/rc_tee_pair_m1.gds >/dev/null 2>&1;                 show "D1 rc_tee_pair mode2 (expect 19.1567/14.093)" runs/rv/i/rc_tee_pair_m1.pex.spice
sak-pex.sh -m 3 -t 10000 -r 1000 -y 0 -w runs/rv/j layout/rc_tee_pair_m1.gds >/dev/null 2>&1
printf '%-42s ' "D1 rc_tee_pair mode3 y=0 net s1 sum to sub"; python3 - runs/rv/j/rc_tee_pair_m1.pex.spice <<'PY'
import re,sys
t=0
for l in open(sys.argv[1]):
    p=l.split()
    if l.startswith("C") and "w_" in p[2] and p[1].split(".")[0] in ("s1","a1","b1"):
        t+=float(re.match(r"([0-9.]+)",p[3]).group(1))
print("%.4f fF (expect 33.2497 = 14.093 + 19.1567)"%t)
PY
sak-pex.sh -m 1 -w runs/rv/k layout/sidewall_m1_s0p2.gds >/dev/null 2>&1;  show "D3 sidewall s0p2 mode1 (expect 4.87346 each)" runs/rv/k/sidewall_m1_s0p2.pex.spice
echo "--- kpex 2.5D sidewall s0p8 (expect 0.966857, kpex >= 0.4.3) ---"
kpex --pdk ihp-sg13g2 --cell sidewall_m1_s0p8 --gds layout/sidewall_m1_s0p8.gds --2.5D --out_dir runs/rv/l --out_spice runs/rv/l/out.spice >/dev/null 2>&1; grep -h "^C" runs/rv/l/out.spice | head -1
