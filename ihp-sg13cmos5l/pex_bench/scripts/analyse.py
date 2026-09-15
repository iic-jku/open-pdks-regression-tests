#!/usr/bin/env python3
"""Tables A to E: the deck arithmetic against what Magic extracted.

Reads the netlists the bench Makefile writes into netlist/pex/ and prints the comparison.
With --json <file> it also writes every compared value for check_results.py.

SPDX-FileCopyrightText: 2026 Simon Dorrer
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
"""
import json
import os
import re
import sys

BENCH = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), ".."))
PEX = os.path.join(BENCH, "netlist", "pex")
MULT = {"f": 1e-15, "p": 1e-12, "a": 1e-18, "n": 1e-9, "": 1.0}

# aF/um^2 and aF/um, from ihp-sg13cmos5l-extract.tech, variants () - the block at line 170.
# The deck names the top layer allm5; it is stored here as tm1, the name the KLayout map and
# the sg13g2 bench both use for that same GDS 126 thick metal.
AREA = {"m1": 35.015, "m2": 18.180, "m3": 11.994, "m4": 8.948, "tm1": 6.727}
PERI = {"m1": 39.488, "m2": 35.540, "m3": 30.657, "m4": 29.210, "tm1": 34.527}
# defaultoverlap / defaultsideoverlap (upper edge down to the lower plate)
OVER = [(("m1", "m2"), 67.225, 49.422), (("m2", "m3"), 67.225, 49.293),
        (("m3", "m4"), 67.225, 48.867), (("m4", "tm1"), 42.708, 55.229),
        (("m1", "m3"), 23.122, 37.607), (("m1", "tm1"), 9.213, 37.397)]
# mOhm/square, from the variants (),(lvs) block at line 68
RSH = {"m1": 110, "m2": 88, "m3": 88, "m4": 88, "tm1": 18}
# mOhm/cut: via1 to via3 are all 9000, via4 is the one that differs
RVIA = {("m1", "m2"): 9000, ("m2", "m3"): 9000, ("m3", "m4"): 9000, ("m4", "tm1"): 2200}
# Which via-chain family table E reads per level. Two families exist: vc has 12 um wide landing
# metal on both sides, vp a 2 um arm plus a 16 um pad. Both are generated for the top level, as
# in the sg13g2 bench, and as there the pad variant is the one compared. Spelled out rather
# than derived from the layer name, which differs in every PDK.
VIA_CELL = {("m1", "m2"): "vc", ("m2", "m3"): "vc", ("m3", "m4"): "vc", ("m4", "tm1"): "vp"}
SIDEWALL_M1 = (43.268, 0.003)
LAMBDA = 0.05          # Magic grid; the sidewall offset is quantised to it
SPACINGS = ((0.2, "0p2"), (0.4, "0p4"), (0.8, "0p8"), (1.6, "1p6"), (3.2, "3p2"))

ROWS = []   # (table, key, source, value) for --json


def magic(cell, mode):
    return os.path.join(PEX, "%s_magic_pex_%d.spice" % (cell, mode))


def caps(path):
    out = {}
    if not os.path.exists(path):
        return out
    for line in open(path):
        if line.startswith("C"):
            p = line.split()
            m = re.match(r"([0-9.eE+-]+)([fpan]?)$", p[3])
            out[tuple(sorted((p[1], p[2])))] = float(m.group(1)) * MULT[m.group(2)]
    return out


def res(path):
    out = []
    if os.path.exists(path):
        for line in open(path):
            if line.startswith("R"):
                p = line.split()
                out.append((p[1], p[2], float(p[3])))
    return out


def row(table, key, name, pred, got):
    ROWS.append((table, key, "deck", pred))
    if got is None:
        print("%-22s %12.4f %12s %10s" % (name, pred, "-", "-"))
        return
    ROWS.append((table, key, "magic", got))
    print("%-22s %12.4f %12.4f %9.2f%%" % (name, pred, got, (got - pred) / pred * 100.0))


print("=" * 70)
print("A  Capacitance to substrate: C = A*areacap + P*perimc     [fF]")
print("%-22s %12s %12s %10s" % ("structure", "hand calc", "Magic", "delta"))
print("-" * 70)
for m in AREA:
    c = caps(magic("capsub_" + m, 2))
    for tag, A, P in (("plate", 2500.0, 200.0), ("wire", 25.0, 101.0)):
        got = next((v * 1e15 for k, v in c.items() if tag in k), None)
        row("A", "%s_%s" % (m, tag), "%s %s" % (m, tag), (A * AREA[m] + P * PERI[m]) * 1e-3, got)

print()
print("=" * 70)
print("B  Overlap between layers: C = A*overlap + P*sideoverlap  [fF]")
print("   (30x30 lower plate, 10x10 upper plate centred on it)")
print("%-22s %12s %12s %10s" % ("pair", "hand calc", "Magic", "delta"))
print("-" * 70)
for (lo, up), ov, sov in OVER:
    got = caps(magic("overlap_%s_%s" % (lo, up), 2)).get(("bot", "top"))
    row("B", "%s_over_%s" % (up, lo), "%s over %s" % (up, lo),
        (100.0 * ov + 40.0 * sov) * 1e-3, got * 1e15 if got else None)

print()
print("=" * 70)
print("C  Lateral sidewall coupling, M1, W=0.5 um, L=50 um       [fF]")
print("   tech line: defaultsidewall allm1 metal1 %s %s" % SIDEWALL_M1)
print("%-10s %12s %12s %12s %10s" % ("spacing", "k*L/(s+off)", "half of it", "Magic", "Magic/half"))
print("-" * 70)
k, off = SIDEWALL_M1
off_q = round(off / LAMBDA) * LAMBDA   # 0.003 rounds to 0 here, unlike sg13g2
for s, tag in SPACINGS:
    got = caps(magic("sidewall_m1_s" + tag, 2)).get(("a", "b"))
    full = k * 50.0 / (s + off) * 1e-3
    half = (k / 2.0) * 50.0 / (s + off_q) * 1e-3
    ROWS.append(("C", "s" + tag, "deck", full))
    if got is None:
        print("%-10.2f %12.4f %12.4f %12s %10s" % (s, full, half, "-", "-"))
        continue
    ROWS.append(("C", "s" + tag, "magic", got * 1e15))
    print("%-10.2f %12.4f %12.4f %12.4f %9.4f" % (s, full, half, got * 1e15, got * 1e15 / half))

print()
print("=" * 70)
print("D  Sheet resistance, 1 um wide wire, ports 99 um apart    [Ohm]")
print("   (full-RC with THRESHOLD=0 MINRES=0 MINDELAY=0, the only setting that emits it)")
print("%-22s %12s %12s %10s" % ("layer", "99*Rsheet", "Magic", "delta"))
print("-" * 70)
for m in RSH:
    r = res(magic("res_" + m, 3))
    row("D", m, m, 99.0 * RSH[m] * 1e-3, r[0][2] if r else None)

print()
print("=" * 70)
print("E  Contact resistance, n cuts in parallel                 [Ohm]")
print("%-22s %12s %12s %10s" % ("via / cuts", "Rvia/n", "Magic (diff)", "delta"))
print("-" * 70)
for (lo, up), rv in RVIA.items():
    pre = VIA_CELL[(lo, up)]
    vals = {}
    for n in (1, 2, 4, 8):
        r = res(magic("%s_%s_%s_n%d" % (pre, lo, up, n), 3))
        if r:
            vals[n] = r[0][2]
    if 1 not in vals:
        continue
    base_metal = vals[1] - rv * 1e-3
    for n in sorted(vals):
        row("E", "%s_%s_n%d" % (lo, up, n), "%s-%s  n=%d" % (lo, up, n), rv * 1e-3 / n, vals[n] - base_metal)

if "--json" in sys.argv:
    out = sys.argv[sys.argv.index("--json") + 1]
    with open(out, "w") as f:
        json.dump([{"table": t, "key": k, "source": s, "value": v} for t, k, s, v in ROWS], f, indent=1)
    print("\nwrote %d values to %s" % (len(ROWS), out))
