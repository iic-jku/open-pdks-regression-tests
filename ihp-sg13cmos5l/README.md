# DRC / LVS / PEX Regression Tests for the ihp-sg13cmos5l Open-PDK

[![Regression ihp-sg13cmos5l](https://github.com/iic-jku/open-pdks-regression-tests/actions/workflows/regression-ihp-sg13cmos5l.yml/badge.svg?branch=main)](https://github.com/iic-jku/open-pdks-regression-tests/actions/workflows/regression-ihp-sg13cmos5l.yml)

This Makefile-driven directory runs standalone DRC, LVS, and PEX regression tests on individual cells of the `ihp-sg13cmos5l` Open-PDK, with KLayout, Magic + Netgen, gdscheck and kpex. The IIC-OSIC-TOOLS run it with every nightly build and before every release, as [test 31](https://github.com/iic-jku/IIC-OSIC-TOOLS/blob/next_release/_tests/31/test_drc_lvs_pex_sg13cmos5l.sh). The [regression-ihp-sg13cmos5l.yml](../.github/workflows/regression-ihp-sg13cmos5l.yml) workflow of this repository runs the regression and the PEX bench on every change of `main` on the IIC-OSIC-TOOLS nightly image.

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## PDK Selection

Every target except `help` needs the `ihp-sg13cmos5l` PDK. A wrong `$PDK` silently mixes technologies: DRC and LVS run against the wrong rule decks, Magic reads the wrong `magicrc`, and the results look valid. So [../common.mk](../common.mk) does not trust the PDK of the shell. When make parses the [Makefile](Makefile), it runs `sak-pdk-script.sh ihp-sg13cmos5l` itself, imports the variables that call prints (`PDK`, `PDKPATH`, `STD_CELL_LIBRARY`, `KLAYOUT_PATH`, ...) and exports them to every recipe, which the line `[PDK] switched to ihp-sg13cmos5l` reports once per run. `PDK_ROOT` has to be set, as it is in the IIC-OSIC-TOOLS container. A PDK that `sak-pdk` does not offer is a warning in `make help` and an error in every other target, which names the PDKs it found.

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

The `DRC_JOBS` parameter (`sak-drc.sh -j`) sets how many jobs one run uses at most. The default is 4, or the CPU count if lower, for KLayout and every CPU the container may use for gdscheck, which runs as one process with that many threads. Up to 4 jobs, `precheck` and `macro` run as one KLayout process with that many threads, and `regular` runs its four rule sets (main, extra rules, density and antenna) as parallel processes and writes the reports of the last three into the subfolders `maximal/`, `density/` and `antenna/` of the run folder. Above 4, `run_drc.py` splits the rule deck into its tables, one process each, and merges their reports into one. That only pays off for large layouts. On cells this small, more jobs change nothing.

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

**gdscheck DRC** runs the standalone [gdscheck](https://github.com/aesc-silicon/gdscheck) engine (`sak-drc.sh -g`) at the selected `DRC_LEVEL`, `GDSCHECK_SUITE` or `GDSCHECK_DECKS`. The levels map onto its built-in suites: `precheck` runs `precheck` (which includes the density rules, so a single cell fails it), `macro` runs `core` (all geometric rules without density and antenna) and `regular` runs `main` (all rules). The `GDSCHECK_SUITE` parameter (`sak-drc.sh -s`) replaces this mapping and also reaches `density`, `antenna` and `recommended`. The `GDSCHECK_DECKS` parameter (`sak-drc.sh -D`) runs single rule decks instead, comma-separated, and `gdscheck list-decks --process ihp-sg13cmos5l` lists them. The `core` suite includes the IHP extra rules of the `_maximal.drc` deck, which `klayout-drc` runs at `regular` only, so gdscheck can report a cell at `macro` that KLayout passes at that level (`Gat.c` in `sg13_lv_nmos_tap_gat_c`). The layer decks include their fill and density rules, so a deck run can fail on a rule that `macro` does not check:

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

**Magic + Netgen LVS** uses `sak-lvs.sh` (Magic + Netgen mode `-m`, the default), which extracts the layout netlist with Magic and compares it against the schematic netlist with Netgen, using the Netgen setup from the IHP Open-PDK:

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

**KLayout PEX** uses `sak-pex.sh -k`, which extracts with the 2.5D engine of `kpex`. It reads its coefficients from its own `ihp-sg13cmos5l_tech.pb.json`, which is meant to match the Magic deck, so where the two disagree, one of them has a bug or a different coefficient, which the [PEX bench](#pex-bench) is there to find:

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

In every `EXT_MODE`, `magic-pex` leaves each parasitic capacitor below `CTHRESH` (`sak-pex.sh -c`, in fF, default `0.01` = 10 aF) out of the netlist. `CTHRESH=0.001` keeps every capacitor Magic can resolve, since it writes smaller ones as `0`, and a larger value gives a smaller netlist, for example `make magic-pex CTHRESH=0.1`.

For full-RC extraction (`EXT_MODE=3`), `magic-pex` additionally exposes the three `extresist` tuning parameters of `sak-pex.sh`. They are ignored in `EXT_MODE=1`/`2`.

A full-RC extraction of a large layout would produce a resistor network far too large to simulate, and most of it would be wires so short that their resistance does not matter. The three parameters are the filters Magic applies to keep only the part of the network that is worth having. They run in this order:

1. **`THRESHOLD`** (`-t`, in mOhm, default `10000` = 10 Ohm) decides **which nets are extracted at all**. Before doing any real work, Magic makes a quick end-to-end resistance guess for every net. The guess is deliberately pessimistic: it is an absolute worst case. Nets that stay below `THRESHOLD` even in that worst case cannot matter, so they are treated as ideal wires and skipped. This is the cheap first pass that removes the many short, low-resistance nets.
2. **`MINDELAY`** (`-y`, in ps, default `1`) decides **which of the extracted nets are kept**. Because the guess above overestimates, Magic re-checks each net once it has been properly extracted and discards its resistor network again if the RC delay it adds stays below `MINDELAY`. Setting `MINDELAY=0` switches the delay criterion off and applies `THRESHOLD` a second time instead, now against the accurately extracted resistance rather than the initial guess.
3. **`MINRES`** (`-r`, in mOhm, default `1000` = 1 Ohm) decides **how detailed the kept networks are**. Inside a net, neighbouring resistors below `MINRES` are merged as far as possible, which shrinks the network without changing its overall resistance much.

In short: `THRESHOLD` and `MINDELAY` control *how many* nets carry parasitic resistance, while `MINRES` controls *how finely* each of them is modelled. Raising all three gives a smaller netlist that simulates faster with less detail. Lowering them gives a more accurate but considerably larger one.

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

[pex_bench/](pex_bench/) is a second, independent PEX test: 54 metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand (a 50 x 50 um plate, a 0.5 x 50 um wire, a plate over a plate, two wires at swept spacing, a wire with two ports, via chains, a tee and a cross). Each one is extracted with Magic in all three modes, the numbers are compared with the deck arithmetic, and the result is checked against `pex_bench/expected/results.json`. kpex 2.5D extracts the comparison cells as a second implementation.

```sh
make pex-bench                      # Magic modes 1/2/3, kpex 2.5D, compare, check against expected (a few minutes)
make -C pex_bench help              # the finer-grained targets
```

It is the [`ihp-sg13g2` bench](../ihp-sg13g2/pex_bench/) ported to this PDK: same geometry, every layer and every coefficient read from `ihp-sg13cmos5l-extract.tech`. The thick top metal is called `tm1` here as it is there, since it is the same physical layer (GDS 126) even though this deck calls it `metal5`. The thin `m5` of `ihp-sg13g2` does not exist in cmos5l. The defects the bench found in `ihp-sg13g2` are properties of Magic and kpex, not of the PDK. The write-up is in [../ihp-sg13g2/pex_bench/report/pex_bench_report.html](../ihp-sg13g2/pex_bench/report/pex_bench_report.html). On lateral coupling, Magic and kpex 2.5D both emit the deck value at all five spacings (tables C and H).

The port also turned up two defects that were specific to this PDK, both in kpex and both fixed since. Before kpex 0.9.0, `ihp-sg13cmos5l_tech.pb.json` carried **`ihp-sg13g2`'s** coefficients wherever a layer exists in both PDKs with a different value: the whole `sidewalls` block (Metal1 was 43.268 aF with offset +0.003 um in the deck of that time and 28.735 / -0.057 in kpex, so the error on lateral coupling grew with spacing from -5.7 % at 0.2 um to -32.3 % at 3.2 um), and in total 36 of the file's 107 coefficients: the 6 sidewall entries, 26 `sideoverlaps` and 4 substrate perimeters. kpex 0.9.0 took the refitted coefficients of [IHP-Open-PDK#1328](https://github.com/IHP-GmbH/IHP-Open-PDK/pull/1328) for both IHP PDKs ([klayout-pex#525](https://github.com/iic-jku/klayout-pex/pull/525)), the PDK of the IIC-OSIC-TOOLS nightly carries them since `1a12f6fe`, and kpex 2.5D now matches this PDK's deck in tables F, G and H of the bench. And up to kpex 0.4.4, kpex could not run for this PDK at all: its wheel shipped the `sg13cmos5l` LVS deck without the rule decks the deck includes, so `create_lvsdb` failed before any engine started. kpex 0.4.5 ships the complete deck, and the bench runs kpex 2.5D again. Details in [pex_bench/README.md](pex_bench/README.md).

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
make regression LAYOUT_CELLS="sg13_rhigh sg13_rppd" REGRESSION_STEPS="klayout-lvs magic-lvs"
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
- A listed step that fails with a finding is reported as `UNEXPECTED FAIL` and fails the regression: the tool catches the error now, move the entry to `EXPECTED_FAILS`. For a whole-cell entry this happens once every DRC and LVS step of the cell catches it. Until then, a step that catches it is reported as `EXPECTED FAIL`.
- A listed step that fails without a finding is reported as `BROKEN`, as above.

A step can be covered by one of the three lists only. The regression stops before running anything when a step is listed twice, or when a PEX step is listed under `EXPECTED_FAILS` or `KNOWN_FALSE_PASSES`.

## Clean

`make clean` deletes everything the targets generate: `netlist/` (schematic, layout and PEX netlists), `verification/drc/` and `verification/lvs/` (the DRC and LVS reports and the `.rc` exit code files of the regression) and `schematic/xschem/simulations/` (netlists written by the Xschem GUI). The cells in `layout/` and `schematic/xschem/` stay untouched, and so does `pex_bench/`, which has its own `make -C pex_bench pex-bench-clean`:

```sh
make clean
```

## Supported Cells / Files

Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`). Pass a name via `CELL=<cellname>` to run a single target on one cell, or a list via `LAYOUT_CELLS="<cell> <cell> ..."` to restrict `make regression` to those cells. The status is the one on the current IIC-OSIC-TOOLS image, and `KNOWN_FAILS` in the `Makefile` is the reference.

**Low-voltage MOS transistors**

- `sg13_lv_nmos_tap` (PASS)
- `sg13_lv_nmos_tap_m1_a` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): Metal1 0.10 um wide (M1.a)
- `sg13_lv_nmos_tap_m1_b` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): `sg13_lv_nmos_tap` with drain and source Metal1 0.12 um apart (M1.b)
- `sg13_lv_nmos_tap_cnt_c` (broken on purpose, EXPECTED FAIL: KLayout DRC, Magic DRC, gdscheck DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): drain contact 0.04 um inside Activ (Cnt.c)
- `sg13_lv_nmos_tap_cnt_c_ptap` (broken on purpose, EXPECTED FAIL: KLayout DRC, gdscheck DRC, KNOWN FALSE PASS: Magic DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): substrate tap contacts 0.04 um inside Activ (Cnt.c)
- `sg13_lv_nmos_tap_gat_c` (broken on purpose, EXPECTED FAIL: Magic DRC, gdscheck DRC, KLayout DRC passes at `DRC_LEVEL=macro`, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): gate end cap 0.10 um (Gat.c)
- `sg13_lv_nmos_tap_short_ds` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): drain and source shorted
- `sg13_lv_nmos_tap_open_g` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): gate not connected to its pin
- `sg13_lv_nmos_tap_w_mismatch` (broken on purpose, EXPECTED FAIL: KLayout LVS, Magic + Netgen LVS, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): schematic W 0.30 um, layout 0.15 um
- `sg13_lv_pmos_tap` (PASS)
- `sg13_lv_nmos_ring_dev` (PASS)
- `sg13_lv_nmos_ring_pcell` (PASS)
- `sg13_lv_pmos_ring_dev` (PASS)
- `sg13_lv_pmos_ring_pcell` (PASS)
- `sg13_lv_rf_nmos` (PASS)
- `sg13_lv_rf_pmos` (PASS)

**High-voltage MOS transistors**

- `sg13_hv_nmos_tap` (PASS)
- `sg13_hv_pmos_tap` (PASS)
- `sg13_hv_nmos_ring_dev` (PASS)
- `sg13_hv_nmos_ring_pcell` (PASS)
- `sg13_hv_pmos_ring_dev` (PASS)
- `sg13_hv_pmos_ring_pcell` (PASS)
- `sg13_hv_rf_nmos` (PASS)
- `sg13_hv_rf_pmos` (PASS)

**Capacitors**

- `sg13_cmomi` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sg13_cmomf` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))

**Resistors**

- `sg13_rhigh` (PASS)
- `sg13_rppd` (PASS)
- `sg13_rsil` (PASS)

**Diodes & antennas**

- `sg13_dantenna` (PASS)
- `sg13_dpantenna` (PASS)

**Combined test cells**

- `sg13_combined` (PASS)
