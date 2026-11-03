# DRC / LVS / PEX Regression Tests for the gf180mcuD Open-PDK

This Makefile-driven directory runs standalone DRC, LVS, and PEX regression tests on individual cells of the gf180mcuD Open-PDK, using both KLayout and Magic + Netgen. Every target lives in [../common.mk](../common.mk), shared with the other PDK directories; the [Makefile](Makefile) only selects the PDK and lists the known failures.

Things in this PDK that are easy to get wrong when drawing these devices are collected in [FINDINGS.md](FINDINGS.md), the causes of the known failures in [KNOWN_ISSUES.md](KNOWN_ISSUES.md), and the cells broken on purpose in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## Design Rule Check (DRC)

Runs DRC on the GDS layout in `layout/`. Both flows use `sak-drc.sh` and write their reports into per-cell run folders: `verification/drc/<CELL>.magic.drc/` (Magic) and `verification/drc/<CELL>.klayout.drc/` (KLayout, `.lyrdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only.

KLayout DRC runs the PDK's `gf180mcu.drc` deck directly, with the metal stack preset of variant D. The `DRC_LEVEL` parameter selects which rule groups it runs (`sak-drc.sh -l`). It is ignored by `magic-drc`, since Magic has no selectable rule decks and always runs the full rule set compiled into the PDK's Magic tech file:

| Rule groups | `precheck` | `macro` _(default)_ | `regular` |
| --- | :---: | :---: | :---: |
| All device and layer rules | ✓ | ✓ | ✓ |
| Off-grid | – | ✓ | ✓ |
| Density | – | – | ✓ |
| Antenna | – | – | ✓ |

**KLayout DRC** runs a KLayout DRC at the selected `DRC_LEVEL`:

```sh
make klayout-drc
make klayout-drc CELL=gf180_nfet_03v3_tap
make klayout-drc CELL=gf180_nfet_03v3_tap DRC_LEVEL=regular
```

**Magic DRC** runs a hierarchical Magic DRC (`sak-drc.sh -m`):

```sh
make magic-drc
make magic-drc CELL=gf180_nfet_03v3_tap
```

Magic DRC and the KLayout deck disagree in both directions. Magic reports errors on cells the KLayout deck passes, and misses errors the deck catches, such as `NAT.6` and `MIMTM.10` away from the top plate of a MIM capacitor. Both are listed in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Export Schematic Netlist for LVS

Exports the schematic netlist for LVS from Xschem and places it in `netlist/schematic/`.

The `EV_PRECISION` parameter sets the number of significant digits used by Xschem's `ev` function when calculating device properties (default: 5). Increase this to avoid LVS mismatches caused by floating-point rounding differences between Xschem and KLayout (see [xschem#465](https://github.com/StefanSchippers/xschem/issues/465)).

KLayout uses CDL netlists, while Magic uses SPICE netlists. Accordingly, `klayout-lvs-netlist` uses the Xschem commands `set spiceprefix 1`, `set lvs_netlist 1`, `set top_is_subckt 1`, and `set lvs_ignore 1`, while `magic-lvs-netlist` uses `set spiceprefix 1`, `set lvs_netlist 0`, `set top_is_subckt 1`, and `set lvs_ignore 1`.

The `gf180mcu_fd_pr` symbols of capacitors, resistors and bipolar transistors have no `lvs_format`, so their CDL lines are subcircuit calls the KLayout deck cannot read. Every such instance here sets `lvs_format` itself, see [FINDINGS.md](FINDINGS.md) ("Passive symbols and the KLayout deck"). `gf180_cap_nmos_03v3_nofmt` is the one cell without it.

```sh
make klayout-lvs-netlist
make klayout-lvs-netlist CELL=gf180_nfet_03v3_tap
make magic-lvs-netlist
make magic-lvs-netlist CELL=gf180_nfet_03v3_tap
```

## Layout Versus Schematic (LVS)

Exports the schematic netlist from Xschem, then runs LVS. Compares the GDS layout in `layout/` against the schematic netlist in `netlist/schematic/`. Both flows use `sak-lvs.sh` and write their reports into per-cell run folders: `verification/lvs/<CELL>.magic.lvs/` (Magic + Netgen) and `verification/lvs/<CELL>.klayout.lvs/` (KLayout, `.lvsdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only. The extracted layout netlist is moved to `netlist/layout/`.

**KLayout LVS** uses `sak-lvs.sh` (KLayout mode `-k`), which runs the PDK's `gf180mcu.lvs` deck directly rather than its `run_lvs.py` wrapper, with the variant D stack, `check_ports=false` and the deck's other defaults. `combine` is one of them and is off, so a multi-finger layout only matches a schematic with one instance per finger. It writes the extracted netlist as `<CELL>.cir`, not `<CELL>_extracted.cir` as for the IHP PDKs, which is what `KLAYOUT_EXT_CIR` in the [Makefile](Makefile) is for.

```sh
make klayout-lvs
make klayout-lvs CELL=gf180_nfet_03v3_tap
```

**Magic + Netgen LVS** uses `sak-lvs.sh` (Magic + Netgen mode, the default), which extracts the layout netlist with Magic and compares it against the schematic netlist with Netgen, using the Netgen setup from the gf180mcu Open-PDK:

```sh
make magic-lvs
make magic-lvs CELL=gf180_nfet_03v3_tap
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

If a matching Xschem symbol (`schematic/xschem/<CELL>_pex.sym`) exists, the `.subckt` pin order in the extracted SPICE file is automatically reordered to match the symbol's pin positions.

After every extraction, `scripts/check_pex_ports.py` checks that each port of the netlist is connected to at least one element, and that a port which full-RC extraction splits into resistance fragments reaches one of them. A netlist with a dangling port fails the target, since anything wired to that pin in a simulation would float. It does not check what the port is connected to: [FINDINGS.md](FINDINGS.md) ("Full-RC PEX of devices in a deep Nwell") has two cells whose full-RC netlist shorts two pins and passes.

**KLayout PEX** uses `kpex`. The `KPEX_ENGINE` parameter selects its engine: `magic` (default, kpex drives Magic), `2.5D` (kpex's own analytical engine) or `fastercap` (a FasterCap field solve, capacitance only). See [../ihp-sg13g2/README.md](../ihp-sg13g2/README.md) for what each engine is and for `KPEX_AMAX` / `KPEX_TOL`. For this PDK the 2.5D engine cannot extract the top metal, see [pex_bench/README.md](pex_bench/README.md).

```sh
make klayout-pex
make klayout-pex CELL=gf180_nfet_03v3_tap
make klayout-pex CELL=gf180_nfet_03v3_tap EXT_MODE=2 KPEX_ENGINE=2.5D
```

**Magic PEX** uses `sak-pex.sh`, which extracts the parasitics with Magic (C-decoupled, C-coupled, or full-RC). For full-RC extraction (`EXT_MODE=3`) the `extresist` parameters `THRESHOLD`, `MINRES` and `MINDELAY` apply as described in [../ihp-sg13g2/README.md](../ihp-sg13g2/README.md):

```sh
make magic-pex
make magic-pex CELL=gf180_nfet_03v3_tap
make magic-pex CELL=gf180_nfet_03v3_tap EXT_MODE=3
```

## PEX Bench

[pex_bench/](pex_bench/) is a second, independent PEX test: metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand, extracted with Magic and the kpex engines and checked against `pex_bench/expected/results.json`. It is the ihp-sg13g2 bench ported to this PDK, see [pex_bench/README.md](pex_bench/README.md).

```sh
make pex-bench                      # Magic modes 1/2/3 and kpex 2.5D, compare, check against expected
make pex-bench FASTERCAP=1          # additionally field-solve the comparison cells (minutes)
make -C pex_bench help              # the finer-grained targets
```

## Regression

The `regression` target runs the full DRC / LVS / PEX toolchain over **every** cell in `layout/`, so a single command exercises both the KLayout and the Magic + Netgen flows across all supported devices.

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
- `klayout-pex2` (C-coupled)
- `klayout-pex3` (full-RC)

`klayout-pex1` exists as a step but is not in the default list: kpex has no C-decoupled mode and falls back to C-coupled, so it would repeat `klayout-pex2`. `REGRESSION_STEPS` picks the steps, and `LAYOUT_CELLS` restricts the run to some cells:

```sh
make regression LAYOUT_CELLS="gf180_rm1 gf180_rm2" REGRESSION_STEPS="klayout-lvs magic-lvs klayout-pex2"
```

Each cell prints a `PASSED` or `FAILED` line, or one line per listed outcome (see below), and the run ends with a summary. `make regression` exits with a non-zero status when a step fails that is not listed, or a listed step does not end the way its list says, so it can be used directly as a CI gate.

### Known failures

`KNOWN_FAILS` in this directory's `Makefile` lists the steps that should pass but fail because of a tool or PDK bug, one entry per `<cell>:<step>`, or `<cell>` for every step of that cell. Why each entry is there is written up in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that fails is reported as `KNOWN FAIL (tool bug, ignored)` and does not fail the regression.
- A listed step that passes is reported as `UNEXPECTED PASS` and **does** fail the regression, so an entry cannot outlive the bug it stands for. Remove the entry, and its section in `KNOWN_ISSUES.md`, once that happens.
- Any other failing step fails the regression.

Some cells exist to show a tool defect and would be wrong the other way round: `gf180_nfet_03v3_tap_nostrap`, `gf180_cap_nmos_03v3_nofmt`, `gf180_nfet_03v3_mintap` and `gf180_nfet_03v3_ring_cogap` are drawn so that one flow must fail until it is fixed.

### Expected failures

A cell can be broken on purpose, to check that a tool still catches the mistake. `EXPECTED_FAILS` lists the DRC and LVS steps that have to catch such a cell, one entry per `<cell>:<step>`, or `<cell>` for every DRC and LVS step of that cell. PEX steps cannot be listed, they check that the extraction gives a usable netlist, not the cell. What is broken in each cell is written up in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

- A listed step that fails with a finding (DRC violations, layout and schematic do not match) is reported as `EXPECTED FAIL (broken on purpose, caught)` and does not fail the regression.
- A listed step that passes is reported as `FALSE PASS` and fails the regression: the tool missed the deliberate error.
- A listed step that fails without a finding is reported as `BROKEN` and fails the regression. The check did not run to the end, for example because the schematic could not be netlisted, so it says nothing about the cell. The regression tells the two apart by the exit code of `sak-drc.sh` or `sak-lvs.sh`, which every DRC and LVS target writes to `verification/drc/<cell>.<step>.rc` or `verification/lvs/<cell>.<step>.rc`.

### Known false passes

When a tool misses the error in a cell that is broken on purpose because of a bug, that step goes into `KNOWN_FALSE_PASSES` instead, and the bug gets a section in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that passes is reported as `KNOWN FALSE PASS (tool bug, ignored)` and does not fail the regression.
- A listed step that fails with a finding is reported as `UNEXPECTED FAIL` and fails the regression: the tool catches the error now, move the entry to `EXPECTED_FAILS`. For a whole-cell entry this happens once every DRC and LVS step of the cell catches it; until then, a step that catches it is reported as `EXPECTED FAIL`.
- A listed step that fails without a finding is reported as `BROKEN`, as above.

A step can be covered by one of the three lists only. The regression stops before running anything when a step is listed twice, or when a PEX step is listed under `EXPECTED_FAILS` or `KNOWN_FALSE_PASSES`.

## Supported Cells / Files

Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`), both with the same name as the layout top cell. Pass a name via `CELL=<cellname>` to run a single target on one cell, or a list via `LAYOUT_CELLS="<cell> <cell> ..."` to restrict `make regression` to those cells. The status is the one on the current IIC-OSIC-TOOLS image; `KNOWN_FAILS` in the `Makefile` is the reference.

The layouts are built from the `gf180mcu` KLayout PCells of the PDK, the BJTs from its fixed layouts. Where a PCell draws something that fails DRC or LVS, the cell repairs it and [FINDINGS.md](FINDINGS.md) says what and why. MOS cells come as `_tap` (the PCell's butted bulk tie plus a Metal1 strap, bulk on the source, pins D/S/G) and `_ring` (the device without bulk option inside a drawn guard ring, pins D/S/G/B).

**MOS transistors**

- `gf180_nfet_03v3_tap`, `gf180_nfet_03v3_ring` (PASS)
- `gf180_nfet_05v0_tap`, `gf180_nfet_05v0_ring` (PASS)
- `gf180_nfet_06v0_tap`, `gf180_nfet_06v0_ring` (PASS)
- `gf180_nfet_06v0_nvt_tap`, `gf180_nfet_06v0_nvt_ring` (PASS) - native 6 V NMOS
- `gf180_pfet_03v3_tap`, `gf180_pfet_03v3_ring` (PASS)
- `gf180_pfet_05v0_tap`, `gf180_pfet_05v0_ring` (PASS)
- `gf180_pfet_06v0_tap`, `gf180_pfet_06v0_ring` (PASS)
- `gf180_nfet_03v3_tap_nostrap` (KNOWN FAIL: KLayout LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - butted bulk tie without the Metal1 strap
- `gf180_nfet_03v3_mintap` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - one tap as small as the rules allow instead of the guard ring
- `gf180_nfet_03v3_ring_cogap` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - guard ring contacts 0.29 um apart at the corners
- `gf180_nfet_06v0_nvt_ring_nat` (broken on purpose, EXPECTED FAIL: KLayout DRC, KNOWN FALSE PASS: Magic DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - NAT over the guard ring (NAT.6)

**Deep Nwell**

- `gf180_dnwell_nmos` (KNOWN FAIL: Magic DRC, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - NMOS in LVPWELL inside DNWELL, pins D/S/G/VDD/VSS
- `gf180_dnwell_inv` (KNOWN FAIL: Magic DRC, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - PMOS and NMOS in one DNWELL

**Capacitors**

- `gf180_cap_mim_2f0fF` (PASS)
- `gf180_cap_mim_2f0fF_via3` (broken on purpose, KNOWN FALSE PASS: KLayout DRC, Magic DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - bottom plate connected through Via3 (MIMTM.10)
- `gf180_cap_nmos_03v3`, `gf180_cap_nmos_06v0` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_cap_pmos_03v3`, `gf180_cap_pmos_06v0` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_cap_nmos_03v3_b`, `gf180_cap_nmos_06v0_b` (PASS)
- `gf180_cap_pmos_03v3_b`, `gf180_cap_pmos_06v0_b` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_cap_nmos_03v3_nofmt` (KNOWN FAIL: KLayout LVS, Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - without the `lvs_format` work-around

**Resistors**

- `gf180_nplus_u`, `gf180_pplus_u` (PASS)
- `gf180_nplus_s`, `gf180_pplus_s` (KNOWN FAIL: Magic + Netgen LVS, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_nwell` (KNOWN FAIL: Magic + Netgen LVS, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_npolyf_u`, `gf180_npolyf_s`, `gf180_ppolyf_u`, `gf180_ppolyf_s` (PASS)
- `gf180_ppolyf_u_1k`, `gf180_ppolyf_u_1k_6p0` (PASS)
- `gf180_rm1` (KNOWN FAIL: Magic + Netgen LVS, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_rm2`, `gf180_rm3` (PASS)

**Diodes**

- `gf180_diode_nd2ps_03v3`, `gf180_diode_nd2ps_06v0` (PASS, with a Netgen property error on the area that `sak-lvs.sh` does not count, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_diode_pd2nw_03v3`, `gf180_diode_pd2nw_06v0` (PASS, with the same property error)
- `gf180_diode_nw2ps_03v3`, `gf180_diode_nw2ps_06v0` (KNOWN FAIL: Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_diode_pw2dw`, `gf180_diode_dw2ps` (KNOWN FAIL: KLayout LVS, Magic + Netgen LVS, Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_sc_diode` (KNOWN FAIL: KLayout LVS, Magic + Netgen LVS, Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - kept as a finding, the PCell and both decks disagree on the device

**Bipolar transistors**

- `gf180_npn_00p54x02p00`, `gf180_npn_00p54x08p00`, `gf180_npn_00p54x16p00`, `gf180_npn_05p00x05p00` (KNOWN FAIL: Magic DRC, full-RC PEX, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_npn_00p54x04p00`, `gf180_npn_10p00x10p00` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_pnp_10p00x00p42` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `gf180_pnp_05p00x00p42`, `gf180_pnp_05p00x05p00`, `gf180_pnp_10p00x10p00` (KNOWN FAIL: Magic DRC, Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))

"Full-RC PEX" stands for `magic-pex3` and `klayout-pex3`.

**Combined test cells**

- `gf180_combined` (KNOWN FAIL: Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - 15 of the cells above as instances and a 46 x 46 um MIM capacitor beside them, 16 devices on VDD, VSS and G, after `sg13_combined`
- `gf180_combined_cmim_ontop` (KNOWN FAIL: KLayout LVS, Magic DRC, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - the same with the MIM capacitor over all devices, after `sg13_combined_cmim_ontop`
- `gf180_short1` (PASS) - 3.3 V and 6 V NMOS and PMOS with every terminal on VDD

### Devices without a cell

- `cap_mim_1f0fF`, `cap_mim_1f5fF`, `ppolyf_u_2k`, `ppolyf_u_3k`: other variants of the PDK than D.
- `efuse`, the `pwell` resistor: no Xschem symbol.
- `nfet_10v0_asym`, `pfet_10v0_asym` (LDMOS), left out: neither generator of the PDK draws a usable layout. The `gf180mcu_klayoutapi` PCell fails KLayout DRC already at its default size (`CO.4`, `DF.6_MV`, `PL.4_MV`), the Magic generator writes the drain without contacts, and Magic's GDS import has no rule for the LDMOS drain types, so Magic + Netgen LVS could not pass on any layout. `schematic/xschem/gf180_nfet_10v0_asym.sch` is kept without a layout.
- `nfet_03v3_dss`, `pfet_03v3_dss`, `nfet_06v0_dss`, `pfet_06v0_dss`: only the Magic generator draws them, and its GDS has no source and drain contacts and salicide block over the whole device.
