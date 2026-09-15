#!/usr/bin/env python3
"""Tables F to I: three implementations of the gf180mcuD parasitic model against a field solve.

  deck        the arithmetic of gf180mcuD.tech, extract section, done by hand
  Magic       netlist/pex/<cell>_magic_pex_2.spice        (make pex-bench-magic)
  kpex 2.5D   netlist/pex/kpex/2.5D/<cell>/out.spice       (make pex-bench-2.5d)
  FasterCap   netlist/pex/kpex/fastercap/<cell>_a<amax>/   (make pex-bench-fastercap)
              falling back to expected/fastercap/<cell>_a<amax>*/, the converged study
              results shipped with the bench

kpex numbers the dummy nets ($1/$2 or $2/$3, it is not stable, there is no schematic to match
against), so nets are never looked up by name: the pair is whichever two nets are not VSUBS, and
on capsub the plate is the larger of the two substrate couplings, the wire the smaller.
With --json <file> every compared value is written for check_results.py.

SPDX-FileCopyrightText: 2026 Simon Dorrer
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
"""
import glob
import json
import os
import re
import sys

from read_kpex import summary

BENCH = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), ".."))
PEX = os.path.join(BENCH, "netlist", "pex")
MULT = {"f": 1e-15, "p": 1e-12, "a": 1e-18, "n": 1e-9, "": 1.0}

AREA = {"m1": 29.304, "m2": 15.016, "m3": 10.094, "m4": 7.602, "m5": 5.798}
PERI = {"m1": 39.431, "m2": 33.298, "m3": 30.021, "m4": 28.153, "m5": 30.386}
OVER = [(("m1", "m2"), 59.027, 47.566), (("m2", "m3"), 59.027, 49.011),
        (("m3", "m4"), 59.027, 47.871), (("m4", "m5"), 39.351, 52.692),
        (("m1", "m3"), 20.238, 36.609), (("m1", "m5"), 8.142, 33.316)]
SPACINGS = [(0.2, "0p2"), (0.4, "0p4"), (0.8, "0p8"), (1.6, "1p6"), (3.2, "3p2")]
SW_K, SW_OFF = 40.512, -0.053
# finest first: the reported FasterCap value is the finest triangulation that solved
FINE = ["0.1", "0.2", "0.5", "2", "10", "50"]

ROWS = []


def spice_caps(path):
    out = {}
    if not os.path.exists(path):
        return out
    for line in open(path):
        if line.startswith(("C", "Cext")):
            p = line.split()
            m = re.match(r"([0-9.eE+-]+)([fpan]?)$", p[3])
            if not m:
                continue
            a, b = p[1].replace("\\", ""), p[2].replace("\\", "")
            out[tuple(sorted((a, b)))] = float(m.group(1)) * MULT[m.group(2)]
    return out


def magic(cell):
    return spice_caps(os.path.join(PEX, "%s_magic_pex_2.spice" % cell))


def kpex25(cell):
    return spice_caps(os.path.join(PEX, "kpex", "2.5D", cell, "out.spice"))


def kpex25_pair(cell):
    """Coupling between the two signal nets, whatever kpex numbered them ($1/$2 or $2/$3)."""
    for k, v in kpex25(cell).items():
        if "VSUBS" not in k:
            return v
    return None


def kpex25_sub(cell, tag):
    """Coupling to VSUBS of the plate (largest) or the wire (smallest)."""
    vals = sorted(v for k, v in kpex25(cell).items() if "VSUBS" in k)
    if not vals:
        return None
    return vals[-1] if tag == "plate" else vals[0]


def fc(cell, amax):
    """One FasterCap run: (to_substrate by net, pair coupling, residuals, asymmetry, amax, origin)."""
    cands = [(os.path.join(PEX, "kpex", "fastercap", "%s_a%s" % (cell, amax)), "run")]
    cands += [(d, "expected") for d in sorted(glob.glob(
        os.path.join(BENCH, "expected", "fastercap", "%s_a%s_*" % (cell, amax))))]
    cands += [(d, "expected") for d in sorted(glob.glob(
        os.path.join(BENCH, "expected", "fastercap", "%s_a%s" % (cell, amax))))]
    for d, origin in cands:
        s = summary(d)
        if s:
            names, coup, resid, asym = s
            to_sub = {n: coup.get(tuple(sorted(("VSUBS", n))), 0.0) for n in names if n != "VSUBS"}
            sig = [n for n in names if n != "VSUBS"]
            pair = coup.get(tuple(sorted(sig)), 0.0) if len(sig) == 2 else 0.0
            return to_sub, pair, resid, asym, amax, origin
    return None


def fc_finest(cell):
    for a in FINE:
        r = fc(cell, a)
        if r:
            return r
    return None


def ff(x):
    return "%9.4f" % (x * 1e15) if x is not None else "        -"


def rel(got, ref):
    return "%+7.1f%%" % ((got - ref) / ref * 100.0) if (got is not None and ref) else "       -"


def pc(x):
    return "      -" if x != x else "%6.2f%%" % x


def keep(table, key, source, value):
    if value is not None:
        ROWS.append((table, key, source, value * 1e15))


sep = "=" * 108
print(sep)
print("F  Capacitance to substrate: three models against a field solve            [fF]")
print("%-14s %9s %9s %9s %9s %8s %6s %8s %7s %s" % (
    "structure", "deck", "Magic", "kpex 2.5D", "FasterCap", "FC/Magic", "amax", "FC resid", "asym", "from"))
print("-" * 108)
for m in AREA:
    cell = "capsub_" + m
    mg, r = magic(cell), fc_finest(cell)
    for tag, A, P in (("plate", 2500.0, 200.0), ("wire", 25.0, 101.0)):
        key = "%s_%s" % (m, tag)
        pred = (A * AREA[m] + P * PERI[m]) * 1e-18
        mv = next((v for k, v in mg.items() if tag in k), None)
        kv = kpex25_sub(cell, tag)
        fv = fres = None
        amax, asym, origin = "-", float("nan"), ""
        if r:
            to_sub, _, resid, asym, amax, origin = r
            order = sorted(to_sub.items(), key=lambda kv2: -kv2[1])
            n = order[0][0] if tag == "plate" else order[-1][0]
            fv, fres = to_sub[n], resid.get(n, 0.0)
        for src, val in (("deck", pred), ("magic", mv), ("kpex25", kv), ("fastercap", fv)):
            keep("F", key, src, val)
        print("%-14s %s %s %s %s %s %6s %s %7s %s" % (
            "%s %s" % (m, tag), ff(pred), ff(mv), ff(kv), ff(fv), rel(fv, mv), amax, ff(fres), pc(asym), origin))

print()
print(sep)
print("G  Interlayer overlap, plate-to-plate coupling                             [fF]")
print("%-16s %9s %9s %9s %9s %8s %8s %6s %7s %s" % (
    "pair", "deck", "Magic", "kpex 2.5D", "FasterCap", "FC/Magic", "FC/2.5D", "amax", "asym", "from"))
print("-" * 108)
for (lo, up), ov, sov in OVER:
    cell = "overlap_%s_%s" % (lo, up)
    key = "%s_over_%s" % (up, lo)
    pred = (100.0 * ov + 40.0 * sov) * 1e-18
    mg = magic(cell).get(("bot", "top"))
    kv = kpex25_pair(cell)
    r = fc_finest(cell)
    fv, amax, asym, origin = (r[1], r[4], r[3], r[5]) if r else (None, "-", float("nan"), "")
    for src, val in (("deck", pred), ("magic", mg), ("kpex25", kv), ("fastercap", fv)):
        keep("G", key, src, val)
    print("%-16s %s %s %s %s %s %s %6s %7s %s" % (
        "%s over %s" % (up, lo), ff(pred), ff(mg), ff(kv), ff(fv), rel(fv, mg), rel(fv, kv), amax, pc(asym), origin))

print()
print(sep)
print("H  Lateral sidewall coupling, Metal1, W = 0.5 um, L = 50 um                [fF]")
print("   deck formula: k*L/(s+off), k = %s aF, off = %s um. Magic emits half, offset quantised." % (SW_K, SW_OFF))
print("%-9s %9s %9s %9s %9s %8s %8s %6s %7s %s" % (
    "spacing", "deck", "Magic", "kpex 2.5D", "FasterCap", "Magic/FC", "2.5D/FC", "amax", "asym", "from"))
print("-" * 108)
for s, tag in SPACINGS:
    cell = "sidewall_m1_s" + tag
    pred = SW_K * 50.0 / (s + SW_OFF) * 1e-18
    mg = magic(cell).get(("a", "b"))
    kv = kpex25_pair(cell)
    r = fc_finest(cell)
    fv, amax, asym, origin = (r[1], r[4], r[3], r[5]) if r else (None, "-", float("nan"), "")
    for src, val in (("deck", pred), ("magic", mg), ("kpex25", kv), ("fastercap", fv)):
        keep("H", "s" + tag, src, val)
    print("%-9.2f %s %s %s %s %s %s %6s %7s %s" % (
        s, ff(pred), ff(mg), ff(kv), ff(fv), rel(mg, fv), rel(kv, fv), amax, pc(asym), origin))

print()
print(sep)
print("I  FasterCap mesh convergence (--delaunay_amax), sidewall coupling         [fF]")
print("   FasterCap runs in auto mode (-a), so kpex's --mesh is ignored. amax is the knob.")
print("%-9s %9s %9s %9s %9s %9s %9s" % ("spacing", "a=50", "a=10", "a=2", "a=0.5", "a=0.1", "asym@fine"))
print("-" * 108)
for s, tag in SPACINGS:
    cell = "sidewall_m1_s" + tag
    vals = []
    for a in ("50", "10", "2", "0.5", "0.1"):
        r = fc(cell, a)
        vals.append(ff(r[1]) if r else "        -")
    r = fc_finest(cell)
    print("%-9.2f %s %9s" % (s, " ".join(vals), "%.2f%%" % r[3] if r else "-"))

if "--json" in sys.argv:
    out = sys.argv[sys.argv.index("--json") + 1]
    with open(out, "w") as f:
        json.dump([{"table": t, "key": k, "source": s, "value": v} for t, k, s, v in ROWS], f, indent=1)
    print("\nwrote %d values to %s" % (len(ROWS), out))
