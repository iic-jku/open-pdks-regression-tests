# DRC / LVS / PEX Regression Tests for the ihp-sg13g2 Open-PDK

This Makefile-driven repository runs standalone DRC, LVS, and PEX regression tests on individual cells of the ihp-sg13g2 Open-PDK, using both KLayout and Magic+Netgen. This regression test is always executed before a new release for the IIC-OSIC-TOOLS is released. The test script can be found [here](https://github.com/iic-jku/IIC-OSIC-TOOLS/blob/next_release/_tests/26/test_lvs_drc_pex_sg13g2.sh).

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## Design Rule Check (DRC)

Runs DRC on the GDS layout in `layout/`. Both flows use `sak-drc.sh` and write their reports into per-cell run folders: `verification/drc/<CELL>.magic.drc/` (Magic) and `verification/drc/<CELL>.klayout.drc/` (KLayout, `.lyrdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only.

The `DRC_LEVEL` parameter selects the KLayout DRC level (`sak-drc.sh -l`). It is ignored by `magic-drc`, since Magic has no selectable rule decks and always runs the full rule set compiled into the PDK's Magic tech file:

- `precheck` = core FEOL + BEOL manufacturing rules only (fast iteration)
- `macro` = block-in-isolation sign-off: `precheck` plus off-grid, zero-area, and pin/label checks (default)
- `regular` = full-chip sign-off: all checks, including density and antenna

| Check | `precheck` | `macro` _(default)_ | `regular` |
| --- | :---: | :---: | :---: |
| FEOL + BEOL core rules | ✓ | ✓ | ✓ |
| Off-grid / angle | – | ✓ | ✓ |
| Zero-area / geometry | – | ✓ | ✓ |
| Pin / label | – | ✓ | ✓ |
| Recommended / extra rules | – | – | ✓ |
| Density (chip-level fill) | – | – | ✓ |
| Antenna | – | – | ✓ |

**KLayout DRC** runs a KLayout DRC at the selected `DRC_LEVEL`:

```sh
make klayout-drc
make klayout-drc CELL=sg13_lv_nmos_tap
make klayout-drc CELL=sg13_lv_nmos_tap DRC_LEVEL=regular
```

**Magic DRC** runs a Magic DRC with all subcells flattened (`sak-drc.sh -f "*"`):

```sh
make magic-drc
make magic-drc CELL=sg13_lv_nmos_tap
```

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
> For `klayout-pex`, `EXT_MODE=1` (C-decoupled) is not yet supported by kpex and automatically falls back to `EXT_MODE=2` (CC) with a warning.

The `.subckt` name in the extracted SPICE file is `<CELL>_pex`: `magic-pex` sets it directly via the `sak-pex.sh` option `-n <CELL>_pex`, while `klayout-pex` renames the kpex output to `<CELL>_pex`.

If a matching Xschem symbol (`schematic/xschem/<CELL>_pex.sym`) exists, the `.subckt` pin order in the extracted SPICE file is automatically reordered to match the symbol's pin positions. This ensures the PEX netlist can be used directly with the corresponding Xschem symbol for simulation regardless of the selected `EXT_MODE`.

**KLayout PEX** uses `kpex`. The `KPEX_ENGINE` parameter selects its engine:

- `magic` = kpex drives Magic (default). The coupling capacitors are then identical to `magic-pex`, so this is the same engine behind a KLayout front end, not a second opinion.
- `2.5D` = kpex's own analytical engine. It reads the same coefficients as the Magic deck (`ihp-sg13g2_tech.pb.json`), so where it disagrees with Magic exactly one of the two has a bug.
- `fastercap` = a FasterCap field solve on the kpex process stack, capacitance only. `KPEX_AMAX` sets the KLayout-side triangulation (`--delaunay_amax`, kpex default 50 um^2, far too coarse for sub-micron gaps) and `KPEX_TOL` the FasterCap auto tolerance. kpex's `--mesh` has no effect, since FasterCap's auto mode overrides it.

The output is `<CELL>_klayout_pex_<EXT_MODE>.spice` for the Magic engine and `<CELL>_klayout_<engine>_pex_<EXT_MODE>.spice` for the other two.

```sh
make klayout-pex
make klayout-pex CELL=sg13_lv_nmos_tap
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=3
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=2 KPEX_ENGINE=2.5D
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=2 KPEX_ENGINE=fastercap KPEX_AMAX=2
```

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

## PEX Bench

[pex_bench/](pex_bench/) is a second, independent PEX test: 63 metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand (a 50 x 50 um plate, a 0.5 x 50 um wire, a plate over a plate, two wires at swept spacing, a wire with two ports, via chains, a tee and a cross). Each one is extracted with Magic in all three modes and with the kpex 2.5D engine, the numbers are compared with the deck arithmetic and, optionally, with a FasterCap field solve, and the result is checked against `pex_bench/expected/results.json`.

```sh
make pex-bench                      # Magic + kpex 2.5D, compare, check against expected (about a minute)
make pex-bench FASTERCAP=1          # additionally field-solve the 20 comparison cells (minutes)
make pex-bench-defects              # reproduce the six defects below on their smallest cases
make -C pex_bench help              # the finer-grained targets
```

What it established on Magic 8.3 r681, kpex 0.3.15 and PDK deck 1.0.1 is written up in [pex_bench/report/pex_bench_report.html](pex_bench/report/pex_bench_report.html). In short: the area, perimeter, sheet and contact terms are exact in every implementation, and six things around them are not. Full-RC (`EXT_MODE=3`) either doubles every coupling capacitance (`MINDELAY=0`) or collapses the resistor network and leaves ports floating (the shipped `MINDELAY=1`), see [magic#550](https://github.com/RTimothyEdwards/magic/issues/550). `EXT_MODE=1` drops interconnect coupling instead of grounding it. `sak-pex.sh` issues `ext2spice lvs`, whose `hierarchy on` loses 16 % of the substrate capacitance on a layout with devices, which is why `magic-pex` and `klayout-pex` disagree. Magic's lateral (sidewall) coupling is exactly half the deck coefficient, while kpex 2.5D emits the full value and a converged field solve sits above Magic at every spacing. And Magic's halo model sends part of a shielded plate's coupling to the substrate. The bench is what tells you when any of that changes.

## Regression

The `regression` target is this repository's end-to-end smoke test for the [IIC-OSIC-TOOLS](https://github.com/iic-jku/iic-osic-tools) environment. It runs the full DRC / LVS / PEX toolchain over **every** cell in `layout/`, so a single command exercises both the KLayout and the Magic + Netgen flows across all supported devices.

```sh
make regression
```

The target auto-discovers every cell from the `.gds` files in `layout/`, then, for each cell, runs the individual verification targets and records which ones fail:

- `klayout-drc`
- `klayout-lvs`
- `magic-drc`
- `magic-lvs`
- `magic-pex EXT_MODE=1` (C-decoupled)
- `magic-pex EXT_MODE=2` (C-coupled)
- `magic-pex EXT_MODE=3` (full-RC)

> [!NOTE]
> `klayout-pex` is currently commented out in the regression loop. Re-enable the three `klayout-pex` lines in the `regression` target to include it.

Each cell prints a `PASSED`/`FAILED` line, and the run ends with a summary listing every cell that failed together with the tools that failed for it, for example:

```
[REGRESSION] PASSED: sg13_lv_nmos_tap
...
[REGRESSION] SUMMARY: FAILED cells: sg13_rf_cmim(MAGIC-LVS) sg13_combined(MAGIC-LVS)
```

If any cell fails, `make regression` exits with a non-zero status (`exit 1`), so it can be used directly as a CI gate. Known, expected failures are documented in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

The following tools and flows are checked:

| Tool / flow | Where it is exercised |
| --- | --- |
| KLayout DRC (`sak-drc.sh -k`) | `klayout-drc` |
| KLayout LVS (`sak-lvs.sh -k` → `run_lvs.py`) | `klayout-lvs` |
| Magic DRC (`sak-drc.sh -m`) | `magic-drc` |
| Magic extract + Netgen LVS (`sak-lvs.sh`) | `magic-lvs` |
| Magic PEX (`sak-pex.sh`, C-decoupled / C-coupled / full-RC) | `magic-pex EXT_MODE=1/2/3` |

## Supported Cells / Files

The `regression` target auto-discovers every cell from the `.gds` files in `layout/`. Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`). Pass any of these names via `CELL=<cellname>` to run a single target on one cell.
A regression over a selected list of cells is also possible with `LAYOUT_CELLS="Cell1 Cell2 ... CellN"`, eg. by calling `make regression LAYOUT_CELLS="Cell1 Cell2 ... CellN"`

**Low-voltage MOS transistors**

- `sg13_lv_nmos_tap` (PASS)
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

- `sg13_cmim` (PASS)
- `sg13_rf_cmim` (FAILED: Magic+Netgen LVS)
- `sg13_cmomi` (FAILED: Magic+Netgen LVS)

**Resistors**

- `sg13_rhigh` (PASS)
- `sg13_rppd` (PASS)
- `sg13_rsil` (PASS)

**Diodes & antennas**

- `sg13_dantenna` (PASS)
- `sg13_dpantenna` (PASS)
- `sg13_schottky_nbl1` (PASS)

**Combined test cells**

- `sg13_combined` (FAILED: Magic+Netgen LVS)
- `sg13_combined_wo_rfcmim` (PASS)
- `sg13_combined_cmim_ontop` (FAILED: Magic+Netgen LVS)
- `sg13_combined_cmim_ontop_wo_rfcmim` (PASS)
