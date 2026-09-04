#!/bin/sh
# magic-pex and klayout-pex give identical coupling caps but differ by 40 fF in the
# substrate terms on the same layout. The only difference in how they drive Magic is
# that sak-pex.sh issues "ext2spice lvs" and kpex does not. Isolate which sub-option.
cd "$(dirname "$0")/.." || exit 1
G=/foss/designs/ihp-sg13g2-ams-chip-template/macros/inverter/layout/inverter_top.gds
mkdir -p runs/try9

run() {
	tag=$1; extra=$2
	d=runs/try9/$tag
	rm -rf "$d"; mkdir -p "$d"
	cat > "$d/run.tcl" <<EOF
crashbackups stop
drc off
gds read $G
load inverter_top
select top cell
flatten inverter_top_flat
load inverter_top_flat
cellname delete inverter_top -noprompt
cellname rename inverter_top_flat inverter_top
select top cell
extract path $PWD/$d
extract all
$extra
ext2spice cthresh 0.01
ext2spice -p $PWD/$d -o $PWD/$d/out.spice
quit -noprompt
EOF
	magic -dnull -noconsole -rcfile "$PDKPATH/libs.tech/magic/$PDK.magicrc" "$d/run.tcl" > "$d/log" 2>&1
	python3 - "$d/out.spice" "$tag" <<'PY'
import re, sys
mult = {"f": 1e-15, "p": 1e-12, "a": 1e-18, "n": 1e-9, "": 1.0}
tot = sub = 0.0
n = 0
per = {}
for line in open(sys.argv[1]):
    if not line.startswith("C"):
        continue
    p = line.split()
    m = re.match(r"([0-9.eE+-]+)([fpan]?)$", p[3])
    v = float(m.group(1)) * mult[m.group(2)]
    tot += v
    n += 1
    if "VSS" in (p[1], p[2]):
        sub += v
        other = p[1] if p[2] == "VSS" else p[2]
        per[other] = per.get(other, 0.0) + v
print("%-28s caps=%-3d total=%7.2f fF  to VSS=%6.2f fF  %s" % (
    sys.argv[2], n, tot * 1e15, sub * 1e15,
    " ".join("%s=%.2f" % (k, v * 1e15) for k, v in sorted(per.items()))))
PY
}

run kpex_style      "ext2spice short none
ext2spice merge none
ext2spice subcircuits top on
ext2spice format ngspice"
run sak_style       "ext2spice lvs"
run lvs_only        "ext2spice lvs"
run global_off      "ext2spice format ngspice
ext2spice global off"
run subckt_auto     "ext2spice format ngspice
ext2spice subcircuit top auto"
run blackbox_on     "ext2spice format ngspice
ext2spice blackbox on"
run magic_default   "ext2spice format ngspice"
run hier_on         "ext2spice format ngspice
ext2spice hierarchy on"
run hier_on_glob_off "ext2spice format ngspice
ext2spice hierarchy on
ext2spice global off"
run lvs_hier_off    "ext2spice lvs
ext2spice hierarchy off"
