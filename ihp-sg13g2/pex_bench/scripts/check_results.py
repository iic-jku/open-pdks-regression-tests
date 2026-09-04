#!/usr/bin/env python3
"""Compare a fresh bench run against the expected values and fail on drift.

Usage:  check_results.py <fresh.json> <expected.json> [--write]

Each JSON is a list of {table, key, source, value} as written by analyse.py --json and
compare_engines.py --json. Tolerances per source:
  deck, magic, kpex25   0.05 %   these are deterministic model arithmetic
  fastercap             5 %      the triangulation is rebuilt every run, so points scatter
A value present in the expected file and missing from the fresh run is a failure, except for
fastercap, which is optional (make pex-bench FASTERCAP=1 produces it).
--write replaces the expected file with the fresh values instead of checking.

SPDX-FileCopyrightText: 2026 Simon Dorrer
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
"""
import json
import shutil
import sys

TOL = {"deck": 5e-4, "magic": 5e-4, "kpex25": 5e-4, "fastercap": 5e-2}
OPTIONAL = {"fastercap"}


def load(path):
    return {(r["table"], r["key"], r["source"]): r["value"] for r in json.load(open(path))}


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    fresh_path, exp_path = sys.argv[1], sys.argv[2]
    if "--write" in sys.argv:
        shutil.copyfile(fresh_path, exp_path)
        print("[CHECK] wrote %d expected values to %s" % (len(load(exp_path)), exp_path))
        return 0
    fresh, exp = load(fresh_path), load(exp_path)
    bad = missing = skipped = ok = 0
    for key, want in sorted(exp.items()):
        table, name, source = key
        got = fresh.get(key)
        if got is None:
            if source in OPTIONAL:
                skipped += 1
                continue
            print("[CHECK] MISSING  %s %-22s %-9s expected %.6g" % (table, name, source, want))
            missing += 1
            continue
        tol = TOL[source]
        err = abs(got - want) / abs(want) if want else abs(got - want)
        if err > tol:
            print("[CHECK] DRIFT    %s %-22s %-9s expected %.6g got %.6g (%+.2f %%, tol %.2f %%)" % (
                table, name, source, want, got, (got - want) / want * 100.0, tol * 100.0))
            bad += 1
        else:
            ok += 1
    new = sorted(set(fresh) - set(exp))
    for key in new:
        print("[CHECK] NEW      %s %-22s %-9s %.6g (not in expected file)" % (key[0], key[1], key[2], fresh[key]))
    print("[CHECK] %d ok, %d drifted, %d missing, %d optional skipped, %d new" % (ok, bad, missing, skipped, len(new)))
    return 1 if (bad or missing) else 0


if __name__ == "__main__":
    sys.exit(main())
