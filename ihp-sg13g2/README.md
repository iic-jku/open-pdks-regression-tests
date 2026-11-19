# DRC / LVS / PEX Regression Tests for the ihp-sg13g2 Open-PDK

[![Regression ihp-sg13g2](https://github.com/iic-jku/open-pdks-regression-tests/actions/workflows/regression-ihp-sg13g2.yml/badge.svg?branch=main)](https://github.com/iic-jku/open-pdks-regression-tests/actions/workflows/regression-ihp-sg13g2.yml)

This Makefile-driven directory runs standalone DRC, LVS, and PEX regression tests on individual cells of the ihp-sg13g2 Open-PDK, with KLayout, Magic + Netgen, gdscheck and kpex. The IIC-OSIC-TOOLS run it with every nightly build and before every release, as [test 26](https://github.com/iic-jku/IIC-OSIC-TOOLS/blob/next_release/_tests/26/test_drc_lvs_pex_sg13g2.sh). The [regression-ihp-sg13g2.yml](../.github/workflows/regression-ihp-sg13g2.yml) workflow of this repository runs the regression and the PEX bench on every change of `main` on the IIC-OSIC-TOOLS nightly image.

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## PDK Selection

Every target except `help` needs the ihp-sg13g2 PDK. A wrong `$PDK` silently mixes technologies: DRC and LVS run against the wrong rule decks, Magic reads the wrong `magicrc`, and the results look valid. So [../common.mk](../common.mk) does not trust the PDK of the shell. When make parses the [Makefile](Makefile), it runs `sak-pdk-script.sh ihp-sg13g2` itself, imports the variables that call prints (`PDK`, `PDKPATH`, `STD_CELL_LIBRARY`, `KLAYOUT_PATH`, ...) and exports them to every recipe, which the line `[PDK] switched to ihp-sg13g2` reports once per run. `PDK_ROOT` has to be set, as it is in the IIC-OSIC-TOOLS container. A PDK that `sak-pdk` does not offer is a warning in `make help` and an error in every other target, which names the PDKs it found.

## Open the Design Files

Opens a file browser for this folder with `sak-open.py` from the IIC-OSIC-TOOLS, one button per design file, grouped by directory. It needs the desktop of the container, and the tools it starts inherit the PDK selected above:

```sh
make open
make open OPEN_ARGS=--all     # also the generated netlists and reports
```

## Design Rule Check (DRC)

Runs DRC on the GDS layout in `layout/`. All three flows use `sak-drc.sh` and write their reports into per-cell run folders: `verification/drc/<CELL>.magic.drc/` (Magic), `verification/drc/<CELL>.klayout.drc/` (KLayout, `.lyrdb`) and `verification/drc/<CELL>.gdscheck.drc/` (gdscheck, `.lyrdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only.

The `DRC_LEVEL` parameter selects the KLayout DRC level and the gdscheck suite (`sak-drc.sh -l`). It is ignored by `magic-drc`, since Magic has no selectable rule decks and always runs the full rule set compiled into the PDK's Magic tech file:

- `precheck` = the foundry precheck rule set and the pin checks (fast iteration)
- `macro` = block-in-isolation sign-off: the full FEOL and BEOL rules with off-grid, angle, recommended and pin checks, without chip-level density, the extra rules and antenna (default)
- `regular` = full-chip sign-off: all checks, including density, the extra rules and antenna

For the IHP Open-PDK, `sak-drc.sh` passes `--precheck_drc --no_density --no_offgrid --no_angle --disable_extra_rules --no_recommended` for `precheck`, `--no_density --disable_extra_rules` for `macro` and `--antenna` for `regular` to the PDK's `run_drc.py`, which adds the pin checks at every level:

| Check | `precheck` | `macro` _(default)_ | `regular` |
| --- | :---: | :---: | :---: |
| Foundry precheck rule set | ✓ | ✓ | ✓ |
| Pin / label | ✓ | ✓ | ✓ |
| Full FEOL + BEOL rules | – | ✓ | ✓ |
| Off-grid / angle | – | ✓ | ✓ |
| Recommended rules | – | ✓ | ✓ |
| Extra rules | – | – | ✓ |
| Density (full-chip fill) | – | – | ✓ |
| Antenna | – | – | ✓ |

The `DRC_JOBS` parameter (`sak-drc.sh -j`) sets how many jobs one run uses at most, by default 4 (or the CPU count if lower) for KLayout and every CPU the container may use for gdscheck. At `regular`, KLayout runs the four rule sets as parallel processes and writes the reports of the extra rules, the density and the antenna checks into the subfolders `maximal/`, `density/` and `antenna/` of the run folder. On cells this small, more jobs change nothing.

**KLayout DRC** runs a KLayout DRC at the selected `DRC_LEVEL`:

```sh
make klayout-drc
make klayout-drc CELL=sg13_lv_nmos_tap
make klayout-drc CELL=sg13_lv_nmos_tap DRC_LEVEL=regular
```

**Magic DRC** runs Magic's full DRC on the layout (`sak-drc.sh -m`), hierarchically and without flattening any cell. On these cells it finds the same errors as on a copy flattened with Magic's `flatten` command, and a `-f` pattern that matches the top cell would make Magic check an empty cell:

```sh
make magic-drc
make magic-drc CELL=sg13_lv_nmos_tap
```

**gdscheck DRC** runs the standalone [gdscheck](https://github.com/aesc-silicon/gdscheck) engine (`sak-drc.sh -g`) at the selected `DRC_LEVEL`, `GDSCHECK_SUITE` or `GDSCHECK_DECKS`. The levels map onto its built-in suites: `precheck` runs `precheck` (which includes the density rules, so a single cell fails it), `macro` runs `core` (all geometric rules without density and antenna) and `regular` runs `main` (all rules). The `GDSCHECK_SUITE` parameter (`sak-drc.sh -s`) replaces this mapping and also reaches `density`, `antenna` and `recommended`. The `GDSCHECK_DECKS` parameter (`sak-drc.sh -D`) runs single rule decks instead, comma-separated, and `gdscheck list-decks --process ihp-sg13g2` lists them. The `core` suite includes the IHP extra rules of the `_maximal.drc` deck, which `klayout-drc` runs at `regular` only, so gdscheck can report a cell at `macro` that KLayout passes at that level (`Gat.c` in `sg13_lv_nmos_tap_gat_c`). The layer decks include their fill and density rules, so a deck run can fail on a rule that `macro` does not check:

```sh
make gdscheck-drc
make gdscheck-drc CELL=sg13_lv_nmos_tap
make gdscheck-drc CELL=sg13_lv_nmos_tap GDSCHECK_SUITE=recommended
make gdscheck-drc CELL=sg13_lv_nmos_tap GDSCHECK_DECKS=cont,via1
```

KLayout is the sign-off DRC, Magic and gdscheck give a second and a third opinion. Where one of them disagrees with the KLayout deck on a cell, the step is listed in the [Makefile](Makefile) and the cause is written up in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Export Schematic Netlist for LVS

Exports the schematic netlist for LVS from Xschem and places it in `netlist/schematic/`.

The `EV_PRECISION` parameter sets the number of significant digits used by Xschem's `ev` function when calculating device properties (default: 5). Increase this to avoid LVS mismatches caused by floating-point rounding differences between Xschem and KLayout (see [xschem#465](https://github.com/StefanSchippers/xschem/issues/465)).

The `ntap` and `ptap` substrate contacts are ignored during LVS in both flows. `sak-lvs.sh` runs KLayout LVS with the `--disable_tap_extraction` option so it does not extract `ntap` and `ptap` devices from the layout (matching Magic + Netgen LVS).

KLayout uses CDL netlists, while Magic uses SPICE netlists. Accordingly, `klayout-lvs-netlist` uses the Xschem commands `set spiceprefix 1`, `set lvs_netlist 1`, `set top_is_subckt 1`, and `set lvs_ignore 1`, while `magic-lvs-netlist` uses `set spiceprefix 1`, `set lvs_netlist 0`, `set top_is_subckt 1`, and `set lvs_ignore 1`. Hence, switching between CDL and SPICE netlists can be done with `lvs_netlist`.

To extract a CDL schematic netlist for KLayout LVS, use:
```sh
make klayout-lvs-netlist
make klayout-lvs-netlist CELL=sg13_lv_nmos_tap
make klayout-lvs-netlist EV_PRECISION=5
```

To extract a SPICE schematic netlist for Magic + Netgen LVS, use:
```sh
make magic-lvs-netlist
make magic-lvs-netlist CELL=sg13_lv_nmos_tap
make magic-lvs-netlist EV_PRECISION=5
```

## Layout Versus Schematic (LVS)

Exports the schematic netlist from Xschem, then runs LVS. Compares the GDS layout in `layout/` against the schematic netlist in `netlist/schematic/`. Both flows use `sak-lvs.sh` and write their reports into per-cell run folders: `verification/lvs/<CELL>.magic.lvs/` (Magic + Netgen) and `verification/lvs/<CELL>.klayout.lvs/` (KLayout, `.lvsdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only. The extracted layout netlist is moved to `netlist/layout/`.

**KLayout LVS** uses `sak-lvs.sh` (KLayout mode `-k`), which wraps `run_lvs.py` from the IHP Open-PDK:

```sh
make klayout-lvs
make klayout-lvs CELL=sg13_lv_nmos_tap
```

**Magic + Netgen LVS** uses `sak-lvs.sh` (Magic + Netgen mode, the default), which extracts the layout netlist with Magic and compares it against the schematic netlist with Netgen, using the Netgen setup from the IHP Open-PDK:

```sh
make magic-lvs
make magic-lvs CELL=sg13_lv_nmos_tap
```

## Parasitic Extraction (PEX)

Runs parasitic extraction on the GDS layout in `layout/`. The extracted SPICE netlist is written to `netlist/pex/`.

The extracted SPICE filenames include the selected extraction mode:
- `klayout-pex` writes `netlist/pex/<CELL>_klayout_pex_<EXT_MODE>.spice`
- `magic-pex` writes `netlist/pex/<CELL>_magic_pex_<EXT_MODE>.spice`

The `EXT_MODE` parameter selects the extraction mode:
- `1` = C-decoupled (default)
- `2` = C-coupled
- `3` = full-RC

> [!NOTE]
> For `klayout-pex`, `EXT_MODE=1` (C-decoupled) runs kpex in its mode `C`, which replaces each coupling capacitance by its full value from both nets to the substrate.

The `.subckt` name in the extracted SPICE file is `<CELL>_pex`: both targets set it via the `sak-pex.sh` option `-n <CELL>_pex`.

After every extraction, `scripts/check_pex_ports.py` checks that each port of the netlist is connected to at least one element, and that a port which full-RC extraction splits into resistance fragments reaches one of them. A netlist with a dangling port fails the target, since anything wired to that pin in a simulation would float. After a full-RC extraction (`EXT_MODE=3`), `scripts/check_pex_modes.py` compares the netlist with the C-coupled netlist of the same cell (`EXT_MODE=2`, which `make regression` extracts first): every device terminal has to reach the same ports, and no two ports that are separate nets in the C-coupled netlist may be joined through resistors. A port of several shorted pins, which kpex names `D|S` in its C-decoupled and C-coupled netlists and keeps as the pins D and S in the full-RC one, counts as both pins. It catches a short between pins, or a device terminal cut off from its pin, that the port check passes because other elements keep the pin connected. Without a C-coupled netlist, or with one older than the layout, it says so and does not compare. The extracted values themselves are checked by the PEX bench.

**KLayout PEX** uses `sak-pex.sh -k`, which extracts with the 2.5D engine of `kpex`. It reads the same coefficients as the Magic deck (`ihp-sg13g2_tech.pb.json`), so where it disagrees with Magic exactly one of the two has a bug, which the [PEX bench](#pex-bench) is there to find:

```sh
make klayout-pex
make klayout-pex CELL=sg13_lv_nmos_tap
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=3
```

On top of the extraction the target does three things:

- It keeps MIM and MOM capacitors as devices with their models (`--blackbox y`), which kpex would otherwise replace by the extracted capacitance of their plates.
- It reduces the full-RC netlist with TICER (`KPEX_REDUCE`, default `ticer`), which leaves far fewer elements and a faster simulation. `floating` only merges the floating islands and removes the capacitor-only nodes, `none` keeps every node.
- It keeps the substrate port `sub!` of the 2.5D netlist (`PEX_SUB_NET`, empty by default): the cells here name their bulk pin `B`, not `VSS`, so there is no net to tie it to. `PEX_SUB_NET=<net>` ties it to that port of the cell, as the chip templates tie it to `VSS`.

Unlike the chip templates, the target passes no schematic to kpex (`sak-pex.sh -S`): its device check would fail the full-RC extraction of every cell whose layout and schematic differ, which is what the LVS steps report. A PEX step checks the extraction, not the cell.

**Magic PEX** uses `sak-pex.sh`, which extracts the parasitics with Magic (C-decoupled, C-coupled, or full-RC):

```sh
make magic-pex
make magic-pex CELL=sg13_lv_nmos_tap
make magic-pex CELL=sg13_lv_nmos_tap EXT_MODE=3
```

For full-RC extraction (`EXT_MODE=3`), `magic-pex` additionally exposes the `sak-pex.sh` `extresist` tuning parameters. They are ignored in `EXT_MODE=1`/`2`:

- `THRESHOLD` - extresist threshold in mOhm (`-t`, default `10000` = 10 Ohm)
- `MINRES` - extresist minimum resistance in mOhm (`-r`, default `1000` = 1 Ohm)
- `MINDELAY` - extresist minimum delay in ps (`-y`, default `1`; `0` = gate by resistance)

```sh
make magic-pex CELL=sg13_lv_nmos_tap EXT_MODE=3 THRESHOLD=5000 MINRES=500 MINDELAY=2
```

## Verify a Cell

Runs DRC, LVS and PEX of one cell in sequence with KLayout (`klayout-drc`, `klayout-lvs`, `klayout-pex`) or with Magic (`magic-drc`, `magic-lvs`, `magic-pex`), each step only if the one before it passed. `make regression` runs every step instead and judges the outcome against the lists, and `gdscheck-drc` runs on its own:

```sh
make klayout-verify CELL=sg13_lv_nmos_tap
make magic-verify CELL=sg13_lv_nmos_tap
```

## PEX Bench

[pex_bench/](pex_bench/) is a second, independent PEX test: 63 metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand (a 50 x 50 um plate, a 0.5 x 50 um wire, a plate over a plate, two wires at swept spacing, a wire with two ports, via chains, a tee and a cross). Each one is extracted with Magic in all three modes and with the kpex 2.5D engine, the numbers are compared with the deck arithmetic and, optionally, with a FasterCap field solve, and the result is checked against `pex_bench/expected/results.json`.

```sh
make pex-bench                      # Magic + kpex 2.5D, compare, check against expected (a few minutes)
make pex-bench FASTERCAP=1          # additionally field-solve the 20 comparison cells (minutes)
make pex-bench-defects              # reproduce the six defects below on their smallest cases
make -C pex_bench help              # the finer-grained targets
```

What it established on Magic 8.3 r681, kpex 0.3.15 and PDK deck 1.0.1 is written up in [pex_bench/report/pex_bench_report.html](pex_bench/report/pex_bench_report.html). In short: the area, perimeter, sheet and contact terms are exact in every implementation, and six things around them are not. Full-RC (`EXT_MODE=3`) either doubles every coupling capacitance (`MINDELAY=0`) or collapses the resistor network and leaves ports floating (the shipped `MINDELAY=1`), see [magic#550](https://github.com/RTimothyEdwards/magic/issues/550). `EXT_MODE=1` drops interconnect coupling instead of grounding it. `sak-pex.sh` issues `ext2spice lvs`, whose `hierarchy on` loses 16 % of the substrate capacitance on a layout with devices, which is why `magic-pex` and `klayout-pex` disagree. Magic's lateral (sidewall) coupling was exactly half the deck coefficient from 8.3.679 to 8.3.692, below a converged field solve at every spacing, and kpex 2.5D halved the coefficient as well from 0.4.3 to 0.8.1. Magic 8.3.693 emits the full value again ([magic#557](https://github.com/RTimothyEdwards/magic/issues/557)). Against the field solve Magic is 61.5 % above at 0.2 um and within 15 % from 0.4 um up, on deck coefficients that [IHP-Open-PDK#1328](https://github.com/IHP-GmbH/IHP-Open-PDK/pull/1328) recomputes. kpex 0.9.0 counts the coefficient once and already uses the #1328 values, which puts kpex 2.5D 4 to 21 % below the field solve. And Magic's halo model sends part of a shielded plate's coupling to the substrate. The bench is what tells you when any of that changes.

## Regression

The `regression` target is this repository's end-to-end smoke test for the [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS) environment. It runs the full DRC / LVS / PEX toolchain over **every** cell in `layout/`, so a single command exercises the KLayout, Magic + Netgen, gdscheck and kpex flows across all supported devices.

```sh
make regression
```

The target auto-discovers every cell from the `.gds` files in `layout/`, then runs the steps listed in `REGRESSION_STEPS` on each cell and records which ones fail. The default steps are:

- `klayout-drc`
- `klayout-lvs`
- `magic-drc`
- `magic-lvs`
- `gdscheck-drc`
- `magic-pex1` (C-decoupled)
- `magic-pex2` (C-coupled)
- `magic-pex3` (full-RC)
- `klayout-pex1` (C-decoupled)
- `klayout-pex2` (C-coupled)
- `klayout-pex3` (full-RC)

`REGRESSION_STEPS` picks the steps, and `LAYOUT_CELLS` restricts the run to some cells:

```sh
make regression LAYOUT_CELLS="sg13_rhigh sg13_rppd" REGRESSION_STEPS="klayout-lvs magic-lvs klayout-pex2"
```

`STEPS` runs only the default steps that match, `%` matches any text. Both LVS steps:

```sh
make regression STEPS=%-lvs
```

A run restricted by `LAYOUT_CELLS`, `STEPS` or `REGRESSION_STEPS` prints a `Partial run:` line with the cells and steps it covers, at the start and again in the summary. `SAK_DRC=<path>`, `SAK_LVS=<path>` and `SAK_PEX=<path>` run another copy of `sak-drc.sh`, `sak-lvs.sh` or `sak-pex.sh` in every step, for example the one of an open IIC-OSIC-TOOLS pull request.

Each cell prints a `PASSED` or `FAILED` line, or one line per listed outcome (see below), and the run ends with a summary. The last summary line lists every cell with the steps that failed it, for example:

```
[REGRESSION] PASSED: sg13_lv_nmos_tap
...
[REGRESSION] KNOWN FAIL (tool bug, ignored): sg13_cmomi (magic-lvs)
...
========================================
[REGRESSION] SUMMARY: KNOWN FAIL cells (tool bug, ignored): sg13_cmomi(magic-lvs)
[REGRESSION] SUMMARY: No unexpected failures
========================================
```

`make regression` exits with a non-zero status when a step fails that is not listed, or a listed step does not end the way its list says, so it can be used directly as a CI gate.

The following tools and flows are checked:

| Tool / flow | Where it is exercised |
| --- | --- |
| KLayout DRC (`sak-drc.sh -k`) | `klayout-drc` |
| KLayout LVS (`sak-lvs.sh -k` → `run_lvs.py`) | `klayout-lvs` |
| Magic DRC (`sak-drc.sh -m`) | `magic-drc` |
| Magic extract + Netgen LVS (`sak-lvs.sh`) | `magic-lvs` |
| gdscheck DRC (`sak-drc.sh -g`) | `gdscheck-drc` |
| Magic PEX (`sak-pex.sh`, C-decoupled / C-coupled / full-RC), then the port check (`scripts/check_pex_ports.py`, for full-RC also `scripts/check_pex_modes.py`) | `magic-pex1` / `magic-pex2` / `magic-pex3` |
| KLayout PEX (`sak-pex.sh -k`, the kpex 2.5D engine, C-decoupled / C-coupled / full-RC), then the same checks | `klayout-pex1` / `klayout-pex2` / `klayout-pex3` |

### Known failures

`KNOWN_FAILS` in this directory's `Makefile` lists the steps that should pass but fail because of a tool or PDK bug, one entry per `<cell>:<step>`, or `<cell>` for every step of that cell. Why each entry is there is written up in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that fails is reported as `KNOWN FAIL (tool bug, ignored)` and does not fail the regression.
- A listed step that passes is reported as `UNEXPECTED PASS` and **does** fail the regression, so an entry cannot outlive the bug it stands for. Remove the entry, and its section in `KNOWN_ISSUES.md`, once that happens.
- Any other failing step fails the regression.

### Expected failures

A cell can be broken on purpose, to check that a tool still catches the mistake: a metal line that is too narrow for DRC, or swapped wiring for LVS. `EXPECTED_FAILS` lists the DRC and LVS steps that have to catch such a cell, one entry per `<cell>:<step>`, or `<cell>` for every DRC and LVS step of that cell. PEX steps cannot be listed, they check that the extraction gives a usable netlist, not the cell. What is broken in each cell is written up in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

- A listed step that fails with a finding (DRC violations, layout and schematic do not match) is reported as `EXPECTED FAIL (broken on purpose, caught)` and does not fail the regression.
- A listed step that passes is reported as `FALSE PASS` and fails the regression: the tool missed the deliberate error.
- A listed step that fails without a finding is reported as `BROKEN` and fails the regression. The check did not run to the end, for example because the schematic could not be netlisted, so it says nothing about the cell. The regression tells the two apart by the exit code of `sak-drc.sh` or `sak-lvs.sh`, which every DRC and LVS target writes to `verification/drc/<cell>.<step>.rc` or `verification/lvs/<cell>.<step>.rc`.

### Known false passes

When a tool misses the error in a cell that is broken on purpose because of a bug, that step goes into `KNOWN_FALSE_PASSES` instead, and the bug gets a section in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that passes is reported as `KNOWN FALSE PASS (tool bug, ignored)` and does not fail the regression.
- A listed step that fails with a finding is reported as `UNEXPECTED FAIL` and fails the regression: the tool catches the error now, move the entry to `EXPECTED_FAILS`. For a whole-cell entry this happens once every DRC and LVS step of the cell catches it; until then, a step that catches it is reported as `EXPECTED FAIL`.
- A listed step that fails without a finding is reported as `BROKEN`, as above.

A step can be covered by one of the three lists only. The regression stops before running anything when a step is listed twice, or when a PEX step is listed under `EXPECTED_FAILS` or `KNOWN_FALSE_PASSES`.

## Clean

`make clean` deletes everything the targets generate: `netlist/` (schematic, layout and PEX netlists), `verification/drc/` and `verification/lvs/` (the DRC and LVS reports and the `.rc` exit code files of the regression) and `schematic/xschem/simulations/` (netlists written by the Xschem GUI). The cells in `layout/` and `schematic/xschem/` stay untouched, and so does `pex_bench/`, which has its own `make -C pex_bench pex-bench-clean`:

```sh
make clean
```

## Supported Cells / Files

Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`). Pass a name via `CELL=<cellname>` to run a single target on one cell, or a list via `LAYOUT_CELLS="<cell> <cell> ..."` to restrict `make regression` to those cells. The status is the one on the current IIC-OSIC-TOOLS image; `KNOWN_FAILS` in the `Makefile` is the reference.

**Low-voltage MOS transistors**

- `sg13_lv_nmos_tap` (PASS)
- `sg13_lv_nmos_tap_m1_a` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - Metal1 0.10 um wide (M1.a)
- `sg13_lv_nmos_tap_m1_b` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - `sg13_lv_nmos_tap` with drain and source Metal1 0.12 um apart (M1.b)
- `sg13_lv_nmos_tap_cnt_c` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - drain contact 0.04 um inside Activ (Cnt.c)
- `sg13_lv_nmos_tap_cnt_c_ptap` (broken on purpose, EXPECTED FAIL: KLayout DRC, gdscheck DRC, KNOWN FALSE PASS: Magic DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - substrate tap contacts 0.04 um inside Activ (Cnt.c)
- `sg13_lv_nmos_tap_gat_c` (broken on purpose, EXPECTED FAIL: Magic DRC, gdscheck DRC, KLayout DRC passes at `DRC_LEVEL=macro`, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - gate end cap 0.10 um (Gat.c)
- `sg13_lv_nmos_tap_short_ds` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - drain and source shorted
- `sg13_lv_nmos_tap_open_g` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - gate not connected to its pin
- `sg13_lv_nmos_tap_w_mismatch` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - schematic W 0.30 um, layout 0.15 um
- `sg13_lv_pmos_tap` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_lv_nmos_ring_dev` (PASS)
- `sg13_lv_nmos_ring_pcell` (PASS)
- `sg13_lv_pmos_ring_dev` (PASS)
- `sg13_lv_pmos_ring_pcell` (PASS)
- `sg13_lv_rf_nmos` (PASS)
- `sg13_lv_rf_pmos` (PASS)

**High-voltage MOS transistors**

- `sg13_hv_nmos_tap` (PASS)
- `sg13_hv_pmos_tap` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_hv_nmos_ring_dev` (PASS)
- `sg13_hv_nmos_ring_pcell` (PASS)
- `sg13_hv_pmos_ring_dev` (PASS)
- `sg13_hv_pmos_ring_pcell` (PASS)
- `sg13_hv_rf_nmos` (PASS)
- `sg13_hv_rf_pmos` (PASS)

**Capacitors**

- `sg13_cmim` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_rf_cmim` (KNOWN FAIL: Magic DRC, Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_cmomi` (KNOWN FAIL: Magic + Netgen LVS, gdscheck DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_cmomf` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))

**Resistors**

- `sg13_rhigh` (PASS)
- `sg13_rppd` (PASS)
- `sg13_rsil` (PASS)

**Diodes & antennas**

- `sg13_dantenna` (PASS)
- `sg13_dpantenna` (PASS)
- `sg13_schottky_nbl1` (PASS)

**Isolated devices (`isolbox`)**

- `sg13_dnwell_nmos` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_dnwell_inv` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_dnwell_inv_nmosi_c` (broken on purpose, EXPECTED FAIL: Magic DRC, gdscheck DRC, KLayout DRC passes at `DRC_LEVEL=macro`, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - `sg13_dnwell_inv` before its nmosi.c fix

**Combined test cells**

- `sg13_combined` (KNOWN FAIL: Magic DRC, Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_combined_wo_rfcmim` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_combined_cmim_ontop` (KNOWN FAIL: Magic DRC, Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_combined_cmim_ontop_wo_rfcmim` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_short1` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - LV and HV NMOS and PMOS with shorted terminals
