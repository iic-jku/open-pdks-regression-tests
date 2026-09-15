#!/usr/bin/env python3
"""Read kpex FasterCap capacitance matrices.

The Maxwell matrix is the honest source. For net i:
  coupling to net j = -M[i][j]
  residual to the far field = M[i][i] - sum_{j!=i} -M[i][j]
kpex attaches that residual to VSUBS in the netlist, so the effective
node-to-ground capacitance in the emitted netlist is coupling_to_VSUBS + residual.
"""
import csv
import os
import sys


def read_matrix(path):
    with open(path) as f:
        rows = list(csv.reader(f, delimiter=";"))
    names = [n.split("_", 1)[1] for n in rows[0]]
    m = [[float(x) for x in r] for r in rows[1:]]
    return names, m


def summary(run_dir):
    """Return (names, coupling dict, residual dict, asymmetry) for one kpex run dir."""
    avg = raw = None
    for root, _, files in os.walk(run_dir):
        for fn in files:
            if fn.endswith("_FasterCap_Result_Matrix_Avg.csv"):
                avg = os.path.join(root, fn)
            elif fn.endswith("_FasterCap_Result_Matrix_Raw.csv"):
                raw = os.path.join(root, fn)
    if not avg:
        return None
    names, m = read_matrix(avg)
    n = len(names)
    coup, resid = {}, {}
    for i in range(n):
        off = 0.0
        for j in range(n):
            if i == j:
                continue
            c = -m[i][j]
            off += c
            if i < j:
                coup[tuple(sorted((names[i], names[j])))] = c
        resid[names[i]] = m[i][i] - off

    # raw-matrix asymmetry, weighted by magnitude and thresholded at 0.1 fF,
    # is the convergence tell (a sign flip on a near-zero entry is not an error)
    asym = 0.0
    if raw:
        _, r = read_matrix(raw)
        num = den = 0.0
        for i in range(n):
            for j in range(i + 1, n):
                a, b = abs(r[i][j]), abs(r[j][i])
                if max(a, b) < 0.1e-15:
                    continue
                num += abs(a - b)
                den += max(a, b)
        asym = num / den * 100.0 if den else 0.0
    return names, coup, resid, asym


if __name__ == "__main__":
    for d in sys.argv[1:]:
        s = summary(d)
        if not s:
            print("%-44s no matrix" % os.path.basename(d))
            continue
        names, coup, resid, asym = s
        secs = ""
        p = os.path.join(d, "secs")
        if os.path.exists(p):
            secs = open(p).read().strip()
        parts = ["%s-%s %8.4f fF" % (a, b, v * 1e15) for (a, b), v in sorted(coup.items())]
        print("%-44s asym=%5.2f%% %6ss | %s" % (os.path.basename(d), asym, secs, "  ".join(parts)))
