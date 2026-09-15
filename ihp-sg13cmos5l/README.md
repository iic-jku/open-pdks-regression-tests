# DRC / LVS / PEX Regression Tests for the ihp-sg13cmos5l Open-PDK

This Makefile-driven directory runs standalone DRC, LVS, and PEX regression tests on individual cells of the ihp-sg13cmos5l Open-PDK, using both KLayout and Magic + Netgen. The IIC-OSIC-TOOLS run it before every release, as [test 31](https://github.com/iic-jku/IIC-OSIC-TOOLS/blob/next_release/_tests/31/test_drc_lvs_pex_sg13cmos5l.sh).

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
- `2.5D` = kpex's own analytical engine, reading its coefficients from `ihp-sg13cmos5l_tech.pb.json`.
- `fastercap` = a FasterCap field solve on the kpex process stack, capacitance only. `KPEX_AMAX` sets the KLayout-side triangulation (`--delaunay_amax`) and `KPEX_TOL` the FasterCap auto tolerance.

The output is `<CELL>_klayout_pex_<EXT_MODE>.spice` for the Magic engine and `<CELL>_klayout_<engine>_pex_<EXT_MODE>.spice` for the other two.

> [!WARNING]
> `klayout-pex` does not run for this PDK on an unmodified IIC-OSIC-TOOLS image, with any engine. The kpex wheel ships the `sg13cmos5l` LVS deck without the rule decks it includes, so kpex fails while building the LVS database, before an engine is chosen. See [PEX Bench](#pex-bench) below.

```sh
make klayout-pex
make klayout-pex CELL=sg13_lv_nmos_tap
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=3
make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=2 KPEX_ENGINE=2.5D
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

[pex_bench/](pex_bench/) is a second, independent PEX test: 54 metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand (a 50 x 50 um plate, a 0.5 x 50 um wire, a plate over a plate, two wires at swept spacing, a wire with two ports, via chains, a tee and a cross). Each one is extracted with Magic in all three modes, the numbers are compared with the deck arithmetic, and the result is checked against `pex_bench/expected/results.json`. The kpex engines are not run for this PDK today, see below.

```sh
make pex-bench                      # Magic modes 1/2/3, compare, check against expected (a few minutes)
make -C pex_bench help              # the finer-grained targets
```

It is the [ihp-sg13g2 bench](../ihp-sg13g2/pex_bench/) ported to this PDK: same geometry, every layer and every coefficient read from `ihp-sg13cmos5l-extract.tech`. The thick top metal is called `tm1` here as it is there, since it is the same physical layer (GDS 126) even though this deck calls it `metal5`; the thin `m5` of ihp-sg13g2 does not exist in cmos5l. The defects the bench found in ihp-sg13g2 are properties of Magic and kpex, not of the PDK - the write-up is in [../ihp-sg13g2/pex_bench/report/pex_bench_report.html](../ihp-sg13g2/pex_bench/report/pex_bench_report.html). The lateral coupling case is even cleaner in this PDK: the deck offset of 0.003 um quantises to zero, so Magic emits exactly half the deck coefficient at all five spacings.

The port also turned up two defects that are specific to this PDK, both in kpex. kpex's `ihp-sg13cmos5l_tech.pb.json` carries **ihp-sg13g2's** coefficients wherever a layer exists in both PDKs with a different value: the whole `sidewalls` block (Metal1 should be 43.268 aF with offset +0.003 um and kpex uses 28.735 / -0.057, so the error on lateral coupling grows with spacing from -5.7 % at 0.2 um to -32.3 % at 3.2 um), and in total 36 of the file's 107 coefficients - the 6 sidewall entries, 26 `sideoverlaps` and 4 substrate perimeters. The area quantities are correct. And kpex cannot run for this PDK at all on an unmodified container: its wheel ships the `sg13cmos5l` LVS deck without the 47 rule decks the deck includes, so `create_lvsdb` fails before any engine starts. The bench therefore declares `PEX_ENGINES := magic`, `make pex-bench` calls no kpex engine here, and `pex_bench/expected/results.json` holds only the deck and Magic columns. Details in [pex_bench/README.md](pex_bench/README.md).

## Regression

The `regression` target is this repository's end-to-end smoke test for the [IIC-OSIC-TOOLS](https://github.com/iic-jku/iic-osic-tools) environment. It runs the full DRC / LVS / PEX toolchain over **every** cell in `layout/`, so a single command exercises both the KLayout and the Magic + Netgen flows across all supported devices.

```sh
make regression
```

The target auto-discovers every cell from the `.gds` files in `layout/`, then runs the steps listed in `REGRESSION_STEPS` on each cell and records which ones fail. The default steps are:

- `klayout-drc`
- `klayout-lvs`
- `magic-drc`
- `magic-lvs`
- `magic-pex1` (C-decoupled)
- `magic-pex2` (C-coupled)
- `magic-pex3` (full-RC)

`klayout-pex1`, `klayout-pex2` and `klayout-pex3` exist as steps but are not in the default list. For this PDK they would fail on every cell, see the warning under [Parasitic Extraction (PEX)](#parasitic-extraction-pex).

```sh
make regression LAYOUT_CELLS="sg13_rhigh sg13_rppd" REGRESSION_STEPS="klayout-lvs magic-lvs"
```

Each cell prints a `PASSED`, `FAILED`, `KNOWN FAIL (ignored)` or `UNEXPECTED PASS` line, and the run ends with a summary, for example:

```
[REGRESSION] PASSED: sg13_lv_nmos_tap
...
[REGRESSION] KNOWN FAIL (ignored): sg13_cmomi (magic-lvs)
...
========================================
[REGRESSION] SUMMARY: KNOWN FAIL cells (ignored): sg13_cmomi(magic-lvs)
[REGRESSION] SUMMARY: No unexpected failures
========================================
```

`make regression` exits with a non-zero status when a step fails that is not listed or a listed step passes, so it can be used directly as a CI gate.

The following tools and flows are checked:

| Tool / flow | Where it is exercised |
| --- | --- |
| KLayout DRC (`sak-drc.sh -k`) | `klayout-drc` |
| KLayout LVS (`sak-lvs.sh -k` → `run_lvs.py`) | `klayout-lvs` |
| Magic DRC (`sak-drc.sh -m`) | `magic-drc` |
| Magic extract + Netgen LVS (`sak-lvs.sh`) | `magic-lvs` |
| Magic PEX (`sak-pex.sh`, C-decoupled / C-coupled / full-RC) | `magic-pex1` / `magic-pex2` / `magic-pex3` |

### Known failures

`KNOWN_FAILS` in this directory's `Makefile` lists the failures that are currently expected, one entry per `<cell>:<step>`, or `<cell>` for every step of that cell. Why each entry is there is written up in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that fails is reported as `KNOWN FAIL (ignored)` and does not fail the regression.
- A listed step that passes is reported as `UNEXPECTED PASS` and **does** fail the regression, so an entry cannot outlive the bug it stands for. Remove the entry, and its section in `KNOWN_ISSUES.md`, once that happens.
- Any other failing step fails the regression.

## Supported Cells / Files

Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`). Pass a name via `CELL=<cellname>` to run a single target on one cell, or a list via `LAYOUT_CELLS="<cell> <cell> ..."` to restrict `make regression` to those cells. The status is the one on the current IIC-OSIC-TOOLS image; `KNOWN_FAILS` in the `Makefile` is the reference.

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

- `sg13_cmomi` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))

**Resistors**

- `sg13_rhigh` (PASS)
- `sg13_rppd` (PASS)
- `sg13_rsil` (PASS)

**Diodes & antennas**

- `sg13_dantenna` (PASS)
- `sg13_dpantenna` (PASS)

**Combined test cells**

- `sg13_combined` (PASS)
