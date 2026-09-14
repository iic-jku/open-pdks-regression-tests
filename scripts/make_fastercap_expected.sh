#!/bin/bash
# Produce the FasterCap reference matrices for one or more PEX benches and file them under
# <pdk>/pex_bench/expected/fastercap/, so the FasterCap column of tables F to I has a
# converged answer without a multi-hour run on every check.
#
# This is the expensive half of the bench. It belongs on a machine with cores and memory:
# on a 4-core laptop the 50 x 50 um plates did not converge at amax 0.5 within an hour of
# CPU and 6.6 GB, while amax 2 over 20 cells took about 230 s.
#
# Runs INSIDE the IIC-OSIC-TOOLS container and starts none. Open a container shell first.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

set -u

ALL_PDKS="ihp-sg13g2 ihp-sg13cmos5l gf180mcuD sky130A"
REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)
AMAX_LIST="2 50"
AMAX_GIVEN=0
TOL_GIVEN=0
# 0.01, not the bench's KPEX_TOL default of 0.05. The FasterCap auto tolerance moves the
# answer as much as the triangulation does: at amax 0.5 the sg13g2 sidewall coupling shifts
# 2 % across tol 0.05 / 0.01 / 0.005. The committed sg13g2 reference is a0.1_b0.5_t0.01, so
# a reference produced at 0.05 would not be comparable to it.
TOL=0.01
DELAUNAY_B=0.5
CELLS=""
CALIBRATE=""
CAL_AMAX="50 10 2 0.5 0.1"
CAL_TOL="0.05 0.01 0.005"
ASYM_WARN=0.2          # per cent; above this the raw matrix has not settled
DRY_RUN=0
REFRESH=0
KEEP_GOING=0
KEEP_RUNS=0
JOBS=1
THREADS=""
TIMEOUT=0

usage() {
	cat <<EOF
Usage: $(basename "$0") [options] [<pdk> ...]

  <pdk>            one or more of: $ALL_PDKS
                   default: all of them

  --amax "<list>"  KLayout-side triangulation values to run, coarsest last.
                   default: "$AMAX_LIST". The convergence study wants "0.1 0.5 2 10 50".
  --tol <frac>     FasterCap auto tolerance (-a). default: $TOL
  --delaunay-b <f> KLayout --delaunay_b. default: $DELAUNAY_B
  --cells "<list>" cells to solve. default: the bench's own KPEX_CELLS
  --asym-warn <%>  flag a run whose raw-matrix asymmetry exceeds this. default: $ASYM_WARN
                   Necessary, not sufficient: in the sg13g2 study amax 50 has the best
                   asymmetry of all the coarse runs (0.51 %) while sitting 9.6 % below the
                   converged value. Use --calibrate to find the settings, not this alone.
  --calibrate <c>  sweep one cell over the amax and tolerance ladder, print value, asymmetry
                   and wall time per point, file nothing. Run this once per PDK on the
                   tightest structure before producing a whole set, and once on a plate
                   cell, which fails differently. In this mode --amax and --tol name the
                   ladder; without them it is amax "$CAL_AMAX" x tol "$CAL_TOL".
  --refresh        after filing the matrices, run pex-bench-compare and pex-bench-expected,
                   which is what actually puts the FasterCap values into expected/results.json.
                   Only pass this after a full sweep: compare_engines.py prefers a run left in
                   netlist/pex/kpex/fastercap/ over the filed matrices, so a partial or coarse
                   run would be pinned as the reference. The script clears that directory
                   before it starts, unless --keep-runs is given.
  --keep-runs      do not clear netlist/pex/kpex/fastercap/ first. For adding to an existing
                   sweep; never combine with --refresh.
  --keep-going     do not stop at the first PDK that has failures
  -j, --jobs <n>   solve <n> cells at once. The cells are independent, and threading a
                   single cell scales poorly because the KLayout triangulation and the
                   LVS ahead of FasterCap are single-threaded, so on a many-core machine
                   this is where the speedup is. Keep jobs x threads at or below the core
                   count. default: $JOBS
  --timeout <s>    kill a solve that runs longer than <s> seconds and record it as a
                   failure, TIMEOUT in the calibrate table. 0, the default, means no
                   limit. Worth setting on the plate cells: a 50 x 50 um capsub at a fine
                   amax can run for hours and still not converge, and the sg13g2 study
                   has two such points that had to be killed by hand (see the head of
                   that bench's scripts/prune.sh).
  --threads <n>    passed to kpex as --threads, which becomes OMP_NUM_THREADS for
                   FasterCap. kpex's own default is os.cpu_count() * 4, so 128 threads on
                   a 32-core machine, four times oversubscribed - set it explicitly there.
                   Empty keeps kpex's default, which is what the committed sg13g2
                   matrices were solved with.
  --repo <path>    regression-test checkout. default: $REPO
  -n, --dry-run    print what would run, solve nothing
  -h, --help       this text

Every solve is written to expected/fastercap/<cell>_a<amax>_b<b>_t<tol>/ with the two result
matrices, out.spice and a "secs" file, which is the layout scripts/read_kpex.py and
scripts/compare_engines.py expect. A PROVENANCE.md next to them records the tool versions and
the date, so a stale column is visible rather than silent.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--amax)        AMAX_LIST=$2; AMAX_GIVEN=1; shift 2 ;;
		--tol)         TOL=$2; TOL_GIVEN=1; shift 2 ;;
		--delaunay-b)  DELAUNAY_B=$2; shift 2 ;;
		--cells)       CELLS=$2; shift 2 ;;
		--calibrate)   CALIBRATE=$2; shift 2 ;;
		--asym-warn)   ASYM_WARN=$2; shift 2 ;;
		--refresh)     REFRESH=1; shift ;;
		--keep-going)  KEEP_GOING=1; shift ;;
		--keep-runs)   KEEP_RUNS=1; shift ;;
		--jobs|-j)     JOBS=$2; shift 2 ;;
		--threads)     THREADS=$2; shift 2 ;;
		--timeout)     TIMEOUT=$2; shift 2 ;;
		--repo)        REPO=$2; shift 2 ;;
		-n|--dry-run)  DRY_RUN=1; shift ;;
		-h|--help)     usage; exit 0 ;;
		-*)            echo "[ERROR] unknown option $1" >&2; usage >&2; exit 1 ;;
		*)             break ;;
	esac
done

PDKS=${*:-$ALL_PDKS}

# ------------------------------------------------------------------ environment
if [ ! -d /foss/tools ]; then
	echo "[ERROR] not inside the IIC-OSIC-TOOLS container - magic, kpex and sak-pdk are missing." >&2
	echo "        Start a container shell first, then run this from there." >&2
	exit 1
fi
for t in kpex klayout make python3; do
	command -v "$t" > /dev/null || { echo "[ERROR] $t not on PATH" >&2; exit 1; }
done
if ! command -v FasterCap > /dev/null; then
	echo "[WARNING] FasterCap is not on PATH; kpex may still find it, but check the logs." >&2
fi
# REPO is derived from where this script sits, which assumes it sits inside the checkout.
# Copying the file somewhere on its own is the usual way to end up here; --repo fixes that.
if [ ! -f "$REPO/common.mk" ]; then
	{
		echo "[ERROR] $REPO has no common.mk, so it is not the regression-test checkout."
		echo "        This path came from the script's own location"
		echo "        ($(realpath "${BASH_SOURCE[0]}")); pass --repo <path> if the"
		echo "        checkout is elsewhere, for instance when only this file was copied over."
		echo "        What is actually there:"
		if [ -d "$REPO" ]; then
			ls -A "$REPO" 2>/dev/null | head -20 | sed "s/^/          /"
			[ -d "$REPO/.git" ] && echo "          (a git checkout of: $(git -C "$REPO" remote get-url origin 2>/dev/null || echo unknown), branch $(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown))"
		else
			echo "          the directory does not exist"
		fi
	} >&2
	exit 1
fi

KPEX_VERSION=$(kpex --version 2>&1 | head -1)
# Which kpex actually runs. A user install in ~/.local/bin shadows the system wheel, and the
# two can ship different PDK payloads: the wheel drops the 47 symlinked cmos5l LVS rule decks,
# so the same version string can mean "LVS works" on one machine and not on the next.
KPEX_PATH=$(command -v kpex 2>/dev/null || echo "not found")
MAGIC_VERSION=$(magic --version 2>/dev/null | head -1)
TOOLS_VERSION=${IIC_OSIC_TOOLS_VERSION:-unknown}
CORES=$(nproc)
STARTED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "================================================================================"
echo " FasterCap reference matrices"
echo "================================================================================"
echo " repo      : $REPO"
echo " pdks      : $PDKS"
[ -z "$CALIBRATE" ] && echo " amax      : $AMAX_LIST"
echo " tolerance : $TOL   delaunay_b: $DELAUNAY_B"
echo " cores     : $CORES"
echo " jobs      : $JOBS   threads per job: ${THREADS:-kpex default, cpu_count x 4}"
if [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then echo " timeout   : ${TIMEOUT}s per solve"; fi
echo " tools     : IIC_OSIC_TOOLS_VERSION=$TOOLS_VERSION"
echo " kpex      : $KPEX_VERSION"
echo " binary    : $KPEX_PATH"
echo " magic     : $MAGIC_VERSION"
[ "$DRY_RUN" -eq 1 ] && echo " MODE      : dry run, nothing is solved"
echo

# Command prefix for a solve, so a timeout can be asked for. This has to be a prefix and
# not a shell function: the produce path runs it behind /usr/bin/time, which execs its
# argument and cannot run a function ('/usr/bin/time: cannot run limit', exit 127).
# timeout returns 124 on expiry, which the produce path treats as a plain failure and the
# calibrate table shows as TIMEOUT.
if [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then
	LIMIT=(timeout "$TIMEOUT")
else
	LIMIT=()
fi

# make --eval lets us read a bench's own variables instead of duplicating them here
mkvar() {
	make -C "$1" --no-print-directory --eval="print-%: ; @echo \$(\$*)" "print-$2" 2>/dev/null \
		| grep -v '^\[' | tail -1
}

TOTAL_FAIL=0

# Ctrl+C or a kill has to take the solves with it. The jobs below are subshells started with
# "&", and a non-interactive shell puts them in its own process group rather than each in one
# of their own, so there is no group to signal per job: the make, kpex and FasterCap under a
# job are plain descendants and survive a kill of the job alone. Walk the tree instead.
kill_tree() {
	local p=$1 c
	for c in $(pgrep -P "$p" 2>/dev/null); do kill_tree "$c"; done
	kill -TERM "$p" 2>/dev/null
}

abort() {
	trap - INT TERM
	local p
	echo >&2
	echo "[ABORT] signal received, stopping the running solves" >&2
	for p in $(jobs -p); do kill_tree "$p"; done
	wait 2>/dev/null
	echo "[ABORT] stopped. Finished points keep their done marker, so a rerun resumes." >&2
	exit 130
}
trap abort INT TERM
TOTAL_WARN=0

# ------------------------------------------------------------------ calibrate
# One cell over the full ladder, so the settings for a whole set are chosen from measured
# convergence rather than assumed. Two rules that look reasonable and are not:
#   - "stop when two successive amax agree": the sequence is not monotone. In the sg13g2
#     study the s=0.2 coupling runs 5.6198 -> 5.9185 -> 5.7760 -> 6.0584 -> 6.2195 fF, so
#     two errors that happen to cancel look exactly like convergence.
#   - "stop when the asymmetry is small": amax 50 is the most self-consistent of the coarse
#     runs there and the furthest from the answer.
# Read the value column and take the setting past which it stops moving, then check that its
# asymmetry is also small.
#
# Calibrate on two cells, not one. They fail differently: the tightest sidewall gap sets the
# resolution the mesh has to reach, while a 50 x 50 um capsub plate sets the cost and may
# not converge at that resolution at all. That is why the committed sg13g2 set quotes the
# sidewall cells at amax 0.1 and the plates at amax 2. Use --timeout on the plates.
if [ -n "$CALIBRATE" ]; then
	# --amax and --tol name the ladder here, not a single production setting
	[ "$AMAX_GIVEN" -eq 1 ] && CAL_AMAX=$AMAX_LIST
	[ "$TOL_GIVEN" -eq 1 ] && CAL_TOL=$TOL
	echo " ladder    : amax $CAL_AMAX x tol $CAL_TOL"
	echo
	for PDK in $PDKS; do
		BENCH=$REPO/$PDK/pex_bench
		[ -f "$BENCH/Makefile" ] || { echo "[SKIP] no bench in $BENCH"; continue; }
		[ -f "$BENCH/layout/$CALIBRATE.gds" ] || {
			echo "[ERROR] $PDK has no layout/$CALIBRATE.gds" >&2; TOTAL_FAIL=1; continue; }
		echo "--------------------------------------------------------------------------------"
		echo " calibrate $PDK / $CALIBRATE"
		echo "--------------------------------------------------------------------------------"
		mkdir -p "$BENCH/netlist"		# same reason as in the produce path below
		CAL_OUT=$BENCH/netlist/calibrate_${CALIBRATE}.txt
		{
			echo "# $PDK / $CALIBRATE, $(date -u +%Y-%m-%dT%H:%M:%SZ)"
			echo "# $KPEX_VERSION, threads=${THREADS:-kpex default}, timeout=${TIMEOUT}s"
		} > "$CAL_OUT"
		row() { printf "$@" | tee -a "$CAL_OUT"; }
		row "%-6s %-7s %14s %8s %9s\n" "amax" "tol" "coupling [fF]" "asym" "secs"
		row "%s\n" "-------------------------------------------------------"
		for amax in $CAL_AMAX; do
			for tol in $CAL_TOL; do
				d=$BENCH/netlist/pex/kpex/fastercap/${CALIBRATE}_a${amax}
				rm -rf "$d"
				if [ "$DRY_RUN" -eq 1 ]; then
					row "%-6s %-7s %14s %8s %9s\n" "$amax" "$tol" "(dry)" "-" "-"
					continue
				fi
				t0=$(date +%s)
				if ${LIMIT[@]+"${LIMIT[@]}"} make -C "$BENCH" --no-print-directory pex-bench-fastercap \
						KPEX_CELLS="$CALIBRATE" KPEX_AMAX="$amax" KPEX_TOL="$tol" KPEX_THREADS="$THREADS" \
						> "$BENCH/netlist/calibrate_${CALIBRATE}_a${amax}_t${tol}.log" 2>&1; then
					secs=$(( $(date +%s) - t0 ))
					# read_kpex.summary() returns (names, coupling, residual, asymmetry); the signal is
					# the coupling that does not involve VSUBS.
					read=$(python3 -c "import sys;sys.path.insert(0,'$BENCH/scripts');from read_kpex import summary as S;r=S('$d');c=[v for k,v in r[1].items() if 'VSUBS' not in k] if r else [];print('%.4f %.2f'%((max(c)*1e15 if c else 0.0),(r[3] if r else 0.0)))" 2>/dev/null)
					val=${read%% *}
					asym=${read##* }
					[ -n "$read" ] || { val="?"; asym="?"; }
					row "%-6s %-7s %14s %7s%% %8ss\n" "$amax" "$tol" "$val" "$asym" "$secs"
				else
					rc=$?
					[ "$rc" -eq 124 ] && why="TIMEOUT" || why="FAILED"
					row "%-6s %-7s %14s %8s %9s\n" "$amax" "$tol" "$why" "-" "-"
				fi
			done
		done
		echo "[CALIBRATE] table also written to $PDK/pex_bench/netlist/calibrate_${CALIBRATE}.txt"
		echo
	done
	echo "================================================================================"
	echo " Calibration only, nothing filed. Pick --amax and --tol from the value column,"
	echo " then produce the set. Aim for a reference an order tighter than the 5 % that"
	echo " check_results.py allows the fastercap column to drift, so 0.5 % or better."
	echo "================================================================================"
	exit $((TOTAL_FAIL != 0))
fi

# One line saying why a solve failed, so a sweep that dies overnight is readable without
# opening 32 logs. The bench Makefile only prints a pointer: the traceback itself sits in
# kpex's own log one level down, and make's "*** [Makefile:NN: target] Error 1" is never
# the reason. Takes the logs to search, innermost first.
fail_reason() {
	local l
	for l in "$@"; do
		[ -f "$l" ] || continue
		grep -v "^make:" "$l" 2>/dev/null \
			| grep -m1 -E "Error|error:|ERROR|Traceback|Exception|No such file|not found|Aborted|Killed" \
			| cut -c1-150 | grep . && return 0
	done
	for l in "$@"; do
		[ -f "$l" ] || continue
		grep -v "^[[:space:]]*$" "$l" 2>/dev/null | tail -1 | cut -c1-150 | grep . && return 0
	done
	return 1
}

for PDK in $PDKS; do
	BENCH=$REPO/$PDK/pex_bench
	echo "--------------------------------------------------------------------------------"
	echo " $PDK"
	echo "--------------------------------------------------------------------------------"
	if [ ! -f "$BENCH/Makefile" ]; then
		echo "[SKIP] no bench in $BENCH"
		echo
		continue
	fi

	pdk_cells=${CELLS:-$(mkvar "$BENCH" KPEX_CELLS)}
	known=$(mkvar "$BENCH" KPEX_KNOWN_FAILS)
	if [ -z "$pdk_cells" ]; then
		echo "[ERROR] could not read KPEX_CELLS from $BENCH/Makefile" >&2
		TOTAL_FAIL=$((TOTAL_FAIL + 1))
		continue
	fi
	n_cells=$(echo "$pdk_cells" | wc -w)
	n_amax=$(echo "$AMAX_LIST" | wc -w)
	echo "[PLAN] $n_cells cells x $n_amax amax values = $((n_cells * n_amax)) solves"
	[ -n "$known" ] && echo "[PLAN] KPEX_KNOWN_FAILS, tolerated: $known"

	DEST=$BENCH/expected/fastercap
	if [ "$DRY_RUN" -eq 0 ]; then
		mkdir -p "$DEST"
		# make creates netlist/ itself, but the shell opens the log redirect of every solve
		# below before make ever starts, so on a checkout where this bench has never run
		# each one dies with "No such file or directory" in no time at all.
		mkdir -p "$BENCH/netlist"
		# fc() in compare_engines.py looks in netlist/pex/kpex/fastercap/ BEFORE the filed
		# matrices, so anything stale left there wins and would be pinned by --refresh.
		if [ "$KEEP_RUNS" -eq 0 ] && [ -d "$BENCH/netlist/pex/kpex/fastercap" ]; then
			echo "[PLAN] clearing netlist/pex/kpex/fastercap/ so no stale run is picked up"
			rm -rf "$BENCH/netlist/pex/kpex/fastercap"
		fi
	fi

	# A backgrounded job cannot report through a variable, so each appends its own line
	VERDICT_FAIL=$(mktemp)
	VERDICT_WARN=$(mktemp)
	pdk_start=$(date +%s)

	for amax in $AMAX_LIST; do
		for cell in $pdk_cells; do
			src=$BENCH/netlist/pex/kpex/fastercap/${cell}_a${amax}
			out=$DEST/${cell}_a${amax}_b${DELAUNAY_B}_t${TOL}

			if [ "$DRY_RUN" -eq 1 ]; then
				echo "[DRY] make -C $BENCH pex-bench-fastercap KPEX_CELLS=$cell KPEX_AMAX=$amax KPEX_TOL=$TOL -> $(basename "$out")"
				continue
			fi

			# One cell per job. The slot wait keeps at most $JOBS kpex processes alive; with
			# --jobs 1 the parent waits immediately, so the run is sequential as before.
			while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do wait -n 2>/dev/null || break; done
			(
			tag=$(printf "[SOLVE] %-34s amax=%-4s" "$cell" "$amax")
			# A finished point is skipped, so a sweep that dies after hours can be restarted.
			# The marker carries the kpex version it was solved with, so an upgraded kpex
			# resolves instead of silently keeping a stale matrix under a fresh PROVENANCE.
			# Delete the directory, or just its done marker, to force a resolve anyway.
			if [ "$(cat "$out/done" 2>/dev/null)" = "0 $KPEX_VERSION" ]; then
				printf "%s %8ss  (already done)\n" "$tag" "$(tail -1 "$out/secs" 2>/dev/null)"
				exit 0
			fi
			rm -rf "$out"
			mkdir -p "$out"
			# /usr/bin/time on the child, as scripts/kpex_run.sh in the sg13g2 bench does, so
			# the secs file means the same thing as in the committed sg13g2 matrices
			if /usr/bin/time -f "%e" -o "$out/secs" \
					${LIMIT[@]+"${LIMIT[@]}"} make -C "$BENCH" --no-print-directory pex-bench-fastercap \
					KPEX_CELLS="$cell" KPEX_AMAX="$amax" KPEX_TOL="$TOL" KPEX_THREADS="$THREADS" \
					> "$BENCH/netlist/fastercap_${cell}_a${amax}.log" 2>&1; then
				# /usr/bin/time -o prepends "Command exited with non-zero status N" when the
				# child fails, so the file can hold two lines. The time is always the last.
				secs=$(tail -1 "$out/secs" 2>/dev/null)
				echo "$secs" > "$out/secs"
				# Keep the matrices, the netlist and the wall time; the meshes, geometries and
				# LVS intermediates are inputs, are large, and any rerun regenerates them.
				# kpex writes the matrices into a <cell>__<cell>/ subdirectory; the committed
				# sg13g2 set has them flattened, and read_kpex.py expects them flat, so find
				# them wherever kpex put them rather than assuming a depth.
				find "$src" -name '*Result_Matrix_*.csv' -exec cp {} "$out"/ \; 2>/dev/null
				cp "$src"/out.spice "$out"/ 2>/dev/null
				if ! ls "$out"/*Result_Matrix_Raw.csv > /dev/null 2>&1; then
					echo "$tag  no matrix written, see netlist/fastercap_${cell}_a${amax}.log"
					reason=$(fail_reason "$src/log" "$BENCH/netlist/fastercap_${cell}_a${amax}.log")
					[ -n "$reason" ] && echo "$tag    -> $reason"
					echo "${cell}_a${amax}" >> "$VERDICT_FAIL"
					exit 0
				fi
				line=$(python3 "$BENCH/scripts/read_kpex.py" "$out" 2>/dev/null | tail -1)
				asym=$(echo "$line" | sed -n 's/.*asym= *\([0-9.]*\)%.*/\1/p')
				echo "0 $KPEX_VERSION" > "$out/done"
				printf "%s %8ss  asym=%s%%\n" "$tag" "$secs" "${asym:-?}"
				if [ -n "$asym" ] && awk "BEGIN{exit !($asym > $ASYM_WARN)}"; then
					echo "${cell}_a${amax}(${asym}%)" >> "$VERDICT_WARN"
				fi
			else
				rc=$?
				echo "$rc $KPEX_VERSION" > "$out/done"
				# 124 is timeout(1) expiry. Worth naming: after an overnight sweep it decides
				# whether to raise --timeout or to go read a traceback.
				[ "$rc" -eq 124 ] && why="TIMEOUT after ${TIMEOUT}s" || why="FAILED"
				echo "$tag  $why, see netlist/fastercap_${cell}_a${amax}.log"
				reason=$(fail_reason "$src/log" "$BENCH/netlist/fastercap_${cell}_a${amax}.log")
				[ -n "$reason" ] && echo "$tag    -> $reason"
				case " $known " in
					*" $cell "*) echo "$tag  known fail for this PDK, tolerated" ;;
					*)           echo "${cell}_a${amax}" >> "$VERDICT_FAIL" ;;
				esac
			fi
			) &
			[ "$JOBS" -le 1 ] && wait
		done
	done
	wait
	pdk_fail=$(sed "s/^/ /" "$VERDICT_FAIL" | tr -d "\n")
	pdk_warn=$(sed "s/^/ /" "$VERDICT_WARN" | tr -d "\n")
	rm -f "$VERDICT_FAIL" "$VERDICT_WARN"

	if [ "$DRY_RUN" -eq 0 ]; then
		pdk_secs=$(( $(date +%s) - pdk_start ))
		{
			echo "# FasterCap reference matrices for $PDK"
			echo
			echo "Produced by \`scripts/make_fastercap_expected.sh\`, not by a bench target, because"
			echo "the field solve is minutes to hours per cell. The bench reads these instead of"
			echo "solving, so the FasterCap column of tables F to I is only as current as this run."
			echo
			echo "| | |"
			echo "|---|---|"
			echo "| produced | $STARTED |"
			echo "| wall time | ${pdk_secs} s on $CORES cores |"
			echo "| amax | $AMAX_LIST |"
			echo "| tolerance | $TOL |"
			echo "| delaunay_b | $DELAUNAY_B |"
			echo "| cells | $n_cells |"
			echo "| IIC_OSIC_TOOLS_VERSION | $TOOLS_VERSION |"
			echo "| kpex | $KPEX_VERSION |"
			echo "| kpex binary | $KPEX_PATH |"
			echo "| magic | $MAGIC_VERSION |"
			echo
			echo "## When to redo this"
			echo
			echo "The other three columns are recomputed on every \`make pex-bench\`; this one is not."
			echo "Rerun this script when any of the following changes, and commit the result together"
			echo "with a fresh \`make pex-bench-expected\`:"
			echo
			echo "- the kpex version, or its process stack for this PDK"
			echo "- the PDK's extraction deck, if the change touches a layer the bench solves"
			echo "- the bench geometry, i.e. any \`scripts/gen_*.py\`"
			echo "- FasterCap itself"
			echo
			echo "If a \`make pex-bench\` reports drift in \`kpex25\` but not in \`deck\`, this file is the"
			echo "first thing to check: the 2.5D and the FasterCap column then disagree about which"
			echo "tool version they describe."
			[ -n "$pdk_warn" ] && { echo; echo "## Not converged at this setting"; echo;
				echo "Raw-matrix asymmetry above ${ASYM_WARN} %, do not quote these rows:"; echo;
				for w in $pdk_warn; do echo "- $w"; done; }
			[ -n "$pdk_fail" ] && { echo; echo "## Failed"; echo;
				for f in $pdk_fail; do echo "- $f"; done; }
		} > "$DEST/PROVENANCE.md"
		echo
		echo "[DONE] $PDK in ${pdk_secs} s, matrices under $PDK/pex_bench/expected/fastercap/"
		echo "[DONE] provenance written to $PDK/pex_bench/expected/fastercap/PROVENANCE.md"

		if [ -n "$pdk_warn" ]; then
			echo "[WARN] asymmetry above ${ASYM_WARN} %:$pdk_warn"
			TOTAL_WARN=$((TOTAL_WARN + $(echo "$pdk_warn" | wc -w)))
		fi
		if [ -n "$pdk_fail" ]; then
			echo "[FAIL] no matrix for:$pdk_fail"
			TOTAL_FAIL=$((TOTAL_FAIL + $(echo "$pdk_fail" | wc -w)))
			[ "$KEEP_GOING" -eq 0 ] && { echo; echo "[ERROR] stopping, pass --keep-going to continue"; exit 1; }
		fi

		if [ "$REFRESH" -eq 1 ] && [ -n "$pdk_warn" ]; then
			echo "[REFRESH] refusing for $PDK: $(echo "$pdk_warn" | wc -w) run(s) did not converge."
			echo "          Pinning an unconverged solve makes it the reference. Solve those"
			echo "          finer first, then rerun with --refresh."
		elif [ "$REFRESH" -eq 1 ]; then
			echo "[REFRESH] pex-bench-compare and pex-bench-expected for $PDK"
			make -C "$BENCH" --no-print-directory pex-bench-compare > /dev/null \
				&& make -C "$BENCH" --no-print-directory pex-bench-expected \
				|| { echo "[FAIL] refresh failed for $PDK"; TOTAL_FAIL=$((TOTAL_FAIL + 1)); }
		fi
	fi
	echo
done

echo "================================================================================"
if [ "$DRY_RUN" -eq 1 ]; then
	echo " dry run finished, nothing was solved"
	exit 0
fi
echo " $TOTAL_FAIL failed, $TOTAL_WARN not converged"
if [ "$REFRESH" -eq 0 ]; then
	echo
	echo " The matrices are filed but expected/results.json still has no FasterCap values."
	echo " Run this again with --refresh, or per PDK:"
	echo "   make -C <pdk>/pex_bench pex-bench-compare && make -C <pdk>/pex_bench pex-bench-expected"
fi
echo "================================================================================"
[ "$TOTAL_FAIL" -eq 0 ]
