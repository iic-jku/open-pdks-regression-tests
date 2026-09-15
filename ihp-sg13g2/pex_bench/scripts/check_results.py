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

Exit codes, so a CI test can triage a failure without reading the log:

  0  everything within tolerance
  1  a deck value drifted. The deck column is not read from $PDKPATH, it is the coefficient
     tables transcribed by hand into analyse.py and compare_engines.py, so this means those
     tables were edited - normally to track a new PDK release. A PDK update on its own does
     not move this column; it shows up as tool drift against an unchanged deck instead.
  2  only tool values drifted (magic, kpex25, fastercap) while the deck held. A new Magic or
     kpex version behaves differently. Six of the expected magic values encode known defects
     (report/pex_bench_report.html), so check whether upstream fixed one before re-blessing.
  3  the run did not complete: the fresh results are missing entirely, or values are
     missing from them, so the comparison is on partial data. Fix the run before reading
     any drift verdict.
  4  usage error, or the expected file is not there to compare against.

Precedence is 3, then 1, then 2: the most basic problem is the one reported.

SPDX-FileCopyrightText: 2026 Simon Dorrer
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
"""
import json
import shutil
import sys

TOL = {"deck": 5e-4, "magic": 5e-4, "kpex25": 5e-4, "fastercap": 5e-2}
OPTIONAL = {"fastercap"}

# The deck column is arithmetic from constants in this repository, every other column is
# output of a tool. The two drift for unrelated reasons and need different responses, which
# is what the exit code carries.
DECK = "deck"

EXIT_OK, EXIT_DECK, EXIT_TOOL, EXIT_INCOMPLETE, EXIT_USAGE = 0, 1, 2, 3, 4


def load(path):
    return {(r["table"], r["key"], r["source"]): r["value"] for r in json.load(open(path))}


def load_or(path, code, what):
    """Load a result file, or report why it cannot be read and exit with that meaning.

    A missing fresh file is the normal shape of "the bench did not get that far": the
    extraction or the table step failed, so pex-bench-compare never wrote it. That has to
    read as an incomplete run, not as drift, which is what an uncaught traceback would
    look like to a caller that only sees the exit code.
    """
    try:
        return load(path)
    except FileNotFoundError:
        print("[CHECK] %s is not there: %s" % (what, path))
    except (ValueError, KeyError, TypeError) as e:
        print("[CHECK] %s is unreadable: %s (%s)" % (what, path, e))
    sys.exit(code)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return EXIT_USAGE
    fresh_path, exp_path = sys.argv[1], sys.argv[2]
    if "--write" in sys.argv:
        shutil.copyfile(fresh_path, exp_path)
        print("[CHECK] wrote %d expected values to %s" % (len(load(exp_path)), exp_path))
        return EXIT_OK
    fresh = load_or(fresh_path, EXIT_INCOMPLETE, "the fresh results file")
    exp = load_or(exp_path, EXIT_USAGE, "the expected results file")
    deck_drift = tool_drift = missing = skipped = ok = 0
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
            # An expected value of 0 would make the relative change meaningless, and there is
            # no such value in the bench, but printing must not be what discovers that.
            pct = (got - want) / want * 100.0 if want else float("nan")
            print("[CHECK] DRIFT    %s %-22s %-9s expected %.6g got %.6g (%+.2f %%, tol %.2f %%)" % (
                table, name, source, want, got, pct, tol * 100.0))
            if source == DECK:
                deck_drift += 1
            else:
                tool_drift += 1
        else:
            ok += 1
    new = sorted(set(fresh) - set(exp))
    for key in new:
        print("[CHECK] NEW      %s %-22s %-9s %.6g (not in expected file)" % (key[0], key[1], key[2], fresh[key]))
    print("[CHECK] %d ok, %d deck drifted, %d tool drifted, %d missing, %d optional skipped, %d new" % (
        ok, deck_drift, tool_drift, missing, skipped, len(new)))

    # Reported in order of how basic the problem is: an incomplete run makes every other
    # verdict provisional, and a moved deck makes the tool columns unreadable.
    if missing:
        print("[CHECK] INCOMPLETE: %d expected values were not produced. Fix the run first, "
              "the drift verdict above is on partial data." % missing)
        return EXIT_INCOMPLETE
    if deck_drift:
        print("[CHECK] DECK: %d hand-maintained deck constants moved. analyse.py and "
              "compare_engines.py were edited - was that deliberate, for a new PDK release?" % deck_drift)
        return EXIT_DECK
    if tool_drift:
        print("[CHECK] TOOL: %d values moved while the deck held. Magic or kpex behaves "
              "differently than when the expected values were written. Check the versions "
              "and report/pex_bench_report.html before re-blessing." % tool_drift)
        return EXIT_TOOL
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
