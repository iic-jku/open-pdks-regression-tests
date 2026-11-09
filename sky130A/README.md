# DRC / LVS / PEX Regression Tests for the sky130A Open-PDK

This Makefile-driven directory runs standalone DRC, LVS, and PEX regression tests on individual cells of the sky130A Open-PDK, using both KLayout and Magic + Netgen. Every target lives in [../common.mk](../common.mk), shared with the other PDK directories; the [Makefile](Makefile) only selects the PDK and lists the known failures.

Things in this PDK that are easy to get wrong when drawing these devices are collected in [FINDINGS.md](FINDINGS.md), the causes of the known failures in [KNOWN_ISSUES.md](KNOWN_ISSUES.md), and the cells broken on purpose in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

> [!NOTE]
> The `sky130.lvs` deck needs `-rd convert_subckts=true -rd scale=true` to read the CDL that the `sky130_fd_pr` Xschem symbols write (see [FINDINGS.md](FINDINGS.md)). The lists in the [Makefile](Makefile) are for a `sak-lvs.sh` that passes both switches and fails Magic + Netgen LVS on property errors. With an older `sak-lvs.sh`, KLayout LVS fails on every cell; `make regression SAK_LVS=<path>` runs another `sak-lvs.sh`.

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## Design Rule Check (DRC)

Runs DRC on the GDS layout in `layout/`. Both flows use `sak-drc.sh`. KLayout writes its reports into `verification/drc/` (`<CELL>.klayout.drc.<deck>.xml`), Magic into the run folder `verification/drc/<CELL>.magic.drc/`.

KLayout DRC runs the PDK's `sky130A_mr.drc` deck in a FEOL and a BEOL pass, plus separate pin/label, zero-area and density checks depending on `DRC_LEVEL` (`sak-drc.sh -l`). It is ignored by `magic-drc`, which always runs the full rule set of the PDK's Magic tech file:

| Check | `precheck` | `macro` _(default)_ | `regular` |
| --- | :---: | :---: | :---: |
| FEOL + BEOL rules (`sky130A_mr.drc`) | ✓ | ✓ | ✓ |
| Off-grid | – | ✓ | ✓ |
| Pin / label | – | ✓ | ✓ |
| Zero-area | – | ✓ | ✓ |
| Density (`met_min_ca_density.lydrc`) | – | – | ✓ |

**KLayout DRC** runs a KLayout DRC at the selected `DRC_LEVEL`:

```sh
make klayout-drc
make klayout-drc CELL=sky130_nfet_01v8_tap
make klayout-drc CELL=sky130_nfet_01v8_tap DRC_LEVEL=regular
```

**Magic DRC** runs a hierarchical Magic DRC (`sak-drc.sh -m`):

```sh
make magic-drc
make magic-drc CELL=sky130_nfet_01v8_tap
```

Magic DRC and the KLayout deck disagree in both directions. `sky130A_mr.drc` has no check for several periphery rules that Magic does check, such as `hvdifftap.16` and `varac.5`; Magic does not check NPC and HVI as drawn, and reports errors on some layouts the deck passes. See [FINDINGS.md](FINDINGS.md) ("The KLayout DRC deck misses rules") and [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Export Schematic Netlist for LVS

Exports the schematic netlist for LVS from Xschem and places it in `netlist/schematic/`.

The `EV_PRECISION` parameter sets the number of significant digits used by Xschem's `ev` function when calculating device properties (default: 5). Increase this to avoid LVS mismatches caused by floating-point rounding differences between Xschem and KLayout (see [xschem#465](https://github.com/StefanSchippers/xschem/issues/465)).

KLayout uses CDL netlists, while Magic uses SPICE netlists. Accordingly, `klayout-lvs-netlist` uses the Xschem commands `set spiceprefix 1`, `set lvs_netlist 1`, `set top_is_subckt 1`, and `set lvs_ignore 1`, while `magic-lvs-netlist` uses `set spiceprefix 1`, `set lvs_netlist 0`, `set top_is_subckt 1`, and `set lvs_ignore 1`.

```sh
make klayout-lvs-netlist CELL=sky130_nfet_01v8_tap
make magic-lvs-netlist CELL=sky130_nfet_01v8_tap
```

## Layout Versus Schematic (LVS)

Exports the schematic netlist from Xschem, then runs LVS. Compares the GDS layout in `layout/` against the schematic netlist in `netlist/schematic/`. Both flows use `sak-lvs.sh` and write their reports into per-cell run folders: `verification/lvs/<CELL>.magic.lvs/` (Magic + Netgen) and `verification/lvs/<CELL>.klayout.lvs/` (KLayout, `.lvsdb`). The extracted layout netlist is moved to `netlist/layout/`.

**KLayout LVS** uses `sak-lvs.sh` (KLayout mode `-k`), which runs the PDK's `sky130.lvs` deck directly rather than its `run_lvs.py` wrapper, with `run_mode=deep`, `convert_subckts=true`, `scale=true` and the deck's defaults otherwise. See the note at the top.

```sh
make klayout-lvs CELL=sky130_nfet_01v8_tap
```

**Magic + Netgen LVS** uses `sak-lvs.sh` (Magic + Netgen mode, the default), which extracts the flattened layout with Magic and compares it against the schematic netlist with Netgen, using the Netgen setup from the sky130A Open-PDK:

```sh
make magic-lvs
make magic-lvs CELL=sky130_nfet_01v8_tap
```

## Parasitic Extraction (PEX)

Runs parasitic extraction on the GDS layout in `layout/`. The extracted SPICE netlist is written to `netlist/pex/`, as `<CELL>_klayout_pex_<EXT_MODE>.spice` (`klayout-pex`) or `<CELL>_magic_pex_<EXT_MODE>.spice` (`magic-pex`).

The `EXT_MODE` parameter selects the extraction mode: `1` = C-decoupled (default), `2` = C-coupled, `3` = full-RC. For `klayout-pex`, `EXT_MODE=1` is not yet supported by kpex and falls back to `EXT_MODE=2` with a warning.

After every extraction, `scripts/check_pex_ports.py` checks that each port of the netlist is connected to at least one element, and that a port which full-RC extraction splits into resistance fragments reaches one of them. After a full-RC extraction (`EXT_MODE=3`), `scripts/check_pex_modes.py` compares the netlist with the C-coupled netlist of the same cell (`EXT_MODE=2`, which `make regression` extracts first): every device terminal has to reach the same ports, and no two ports that are separate nets in the C-coupled netlist may be joined through resistors. It catches a short between pins, or a device terminal cut off from its pin, that the port check passes because other elements keep the pin connected. Without a C-coupled netlist, or with one older than the layout, it says so and does not compare.

**KLayout PEX** uses `kpex`, **Magic PEX** uses `sak-pex.sh`. `KPEX_ENGINE`, `KPEX_AMAX`, `KPEX_TOL` and the `extresist` parameters `THRESHOLD`, `MINRES` and `MINDELAY` work as described in [../ihp-sg13g2/README.md](../ihp-sg13g2/README.md).

```sh
make magic-pex CELL=sky130_nfet_01v8_tap EXT_MODE=3
make klayout-pex CELL=sky130_nfet_01v8_tap EXT_MODE=2 KPEX_ENGINE=2.5D
```

## PEX Bench

[pex_bench/](pex_bench/) is a second, independent PEX test: metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand, extracted with Magic and the kpex engines and checked against `pex_bench/expected/results.json`. It is the ihp-sg13g2 bench ported to this PDK, see [pex_bench/README.md](pex_bench/README.md).

```sh
make pex-bench                      # Magic modes 1/2/3 and kpex 2.5D, compare, check against expected
make pex-bench FASTERCAP=1          # additionally field-solve the comparison cells (minutes)
```

## Regression

The `regression` target runs the DRC / LVS / PEX toolchain over **every** cell in `layout/`:

```sh
make regression
```

It runs the steps listed in `REGRESSION_STEPS` on each cell. Here they are `klayout-drc`, `magic-drc`, `magic-lvs`, `magic-pex1` (C-decoupled), `magic-pex2` (C-coupled), `magic-pex3` (full-RC), `klayout-pex2` (C-coupled) and `klayout-pex3` (full-RC), and `klayout-lvs`: the default of `../common.mk`. `REGRESSION_STEPS` picks other steps, and `LAYOUT_CELLS` restricts the run to some cells:

```sh
make regression LAYOUT_CELLS="sky130_nfet_01v8_tap sky130_res_generic_po" REGRESSION_STEPS="klayout-drc magic-drc magic-lvs"
```

Each cell prints a `PASSED` or `FAILED` line, or one line per listed outcome (see below), and the run ends with a summary. `make regression` exits with a non-zero status when a step fails that is not listed, or a listed step does not end the way its list says, so it can be used directly as a CI gate.

### Known failures

`KNOWN_FAILS` in this directory's `Makefile` lists the steps that should pass but fail because of a tool or PDK bug, one entry per `<cell>:<step>`. Why each entry is there is written up in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that fails is reported as `KNOWN FAIL (tool bug, ignored)` and does not fail the regression.
- A listed step that passes is reported as `UNEXPECTED PASS` and **does** fail the regression, so an entry cannot outlive the bug it stands for. Remove the entry, and its section in `KNOWN_ISSUES.md`, once that happens.
- Any other failing step fails the regression.

### Expected failures

A cell can be broken on purpose, to check that a tool still catches the mistake. `EXPECTED_FAILS` lists the DRC and LVS steps that have to catch such a cell. What is broken in each cell is written up in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

- A listed step that fails with a finding is reported as `EXPECTED FAIL (broken on purpose, caught)` and does not fail the regression.
- A listed step that passes is reported as `FALSE PASS` and fails the regression: the tool missed the deliberate error.
- A listed step that fails without a finding is reported as `BROKEN` and fails the regression: the check did not run to the end.

### Known false passes

When a tool misses the error in a cell that is broken on purpose because of a bug, that step goes into `KNOWN_FALSE_PASSES` instead, and the bug gets a section in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

- A listed step that passes is reported as `KNOWN FALSE PASS (tool bug, ignored)` and does not fail the regression.
- A listed step that fails with a finding is reported as `UNEXPECTED FAIL` and fails the regression: the tool catches the error now, move the entry to `EXPECTED_FAILS`.
- A listed step that fails without a finding is reported as `BROKEN`, as above.

A step can be covered by one of the three lists only. [../common.mk](../common.mk) has the entry syntax and every outcome.

## Supported Cells / Files

Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`), both with the same name as the layout top cell. The status is the one on the current IIC-OSIC-TOOLS image; the lists in the `Makefile` are the reference.

The layouts are built from the `skywater130` KLayout PCells of the PDK, the 16 V MOS from its Magic generator, the BJTs, the photodiode and the VPP capacitors from its fixed layouts. Where a PCell draws something that breaks a design rule, the cell repairs it and [FINDINGS.md](FINDINGS.md) says what and why.

MOS cells come as `_tap` (the PCell's butted bulk tie strapped to the source, pins D/S/G), `_ring` (the PCell's own guard ring, pins D/S/G/B) and `_ring_pcell` (the device inside a `guard_ring_gen` ring, pins D/S/G/B).

**MOS transistors**

- `sky130_nfet_01v8_*`, `sky130_nfet_01v8_lvt_*`, `sky130_nfet_03v3_nvt_*`, `sky130_nfet_05v0_nvt_*`, `sky130_nfet_g5v0d10v5_*` (PASS, each as `_tap`, `_ring` and `_ring_pcell`)
- `sky130_pfet_01v8_*`, `sky130_pfet_01v8_lvt_*`, `sky130_pfet_01v8_hvt_*`, `sky130_pfet_g5v0d10v5_*` as `_tap` and `_ring` (PASS)
- `sky130_pfet_01v8_ring_pcell`, `sky130_pfet_01v8_lvt_ring_pcell`, `sky130_pfet_01v8_hvt_ring_pcell`, `sky130_pfet_g5v0d10v5_ring_pcell` (KNOWN FAIL: Magic DRC, Magic + Netgen LVS, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))
- `sky130_nfet_g5v0d16v0` (KNOWN FAIL: KLayout LVS), `sky130_pfet_g5v0d16v0` (KNOWN FAIL: Magic DRC, KLayout LVS) - drawn with the Magic generator; the KLayout deck has no extraction for them
- `sky130_nfet_01v8_tap_licon15` (broken on purpose, KNOWN FALSE PASS: KLayout DRC, Magic DRC, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)) - NPC of the PCell (`licon.15`)
- `sky130_nfet_05v0_nvt_tap_hvdifftap16` (broken on purpose, EXPECTED FAIL: Magic DRC, KNOWN FALSE PASS: KLayout DRC) - bulk tie of the PCell, 0.45 um deep (`hvdifftap.16`)

**Deep Nwell**

- `sky130_dnwell_nmos`, `sky130_dnwell_inv` (PASS; the KLayout deck shorts the isolated P-well to the substrate and still reports a match, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md))

**Capacitors**

- `sky130_cap_mim_m3_1`, `sky130_cap_mim_m3_2` (KNOWN FAIL: KLayout LVS)
- `sky130_cap_var_lvt`, `sky130_cap_var_hvt` (KNOWN FAIL: KLayout LVS, Magic + Netgen LVS)
- `sky130_cap_var_hvt_varac5` (broken on purpose, KNOWN FALSE PASS: KLayout DRC, Magic DRC; KNOWN FAIL: KLayout LVS, Magic + Netgen LVS) - Nwell of the PCell (`varac.5`)
- `sky130_cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5`, `sky130_cap_vpp_11p5x11p7_m1m2_noshield`, `sky130_cap_vpp_08p6x07p8_m1m2_shieldl1`, `sky130_cap_vpp_04p4x04p6_m1m2_shieldl1` (KNOWN FAIL: KLayout LVS, Magic + Netgen LVS)

**Resistors**

- `sky130_res_generic_po`, `sky130_res_generic_nd`, `sky130_res_generic_pd` (PASS)
- `sky130_res_high_po_{1p41,2p85,5p73}`, `sky130_res_xhigh_po_{1p41,2p85,5p73}` (PASS)
- `sky130_res_high_po_{0p35,0p69}`, `sky130_res_xhigh_po_{0p35,0p69}` (KNOWN FAIL: Magic DRC)
- `sky130_res_generic_l1`, `sky130_res_generic_m1` ... `sky130_res_generic_m5` (PASS)
- `sky130_res_iso_pw` (KNOWN FAIL: KLayout LVS)

**Diodes**

- `sky130_diode_pw2nd_05v5`, `_05v5_lvt`, `_05v5_nvt`, `_11v0` (KNOWN FAIL: KLayout LVS)
- `sky130_diode_pd2nw_05v5`, `_11v0` (KNOWN FAIL: KLayout LVS)
- `sky130_diode_pd2nw_05v5_lvt`, `sky130_diode_pd2nw_05v5_hvt` (KNOWN FAIL: Magic DRC, KLayout LVS, Magic + Netgen LVS)
- `sky130_diode_pd2nw_05v5_psd8` (broken on purpose, EXPECTED FAIL: Magic DRC, KNOWN FALSE PASS: KLayout DRC, KNOWN FAIL: KLayout LVS) - PSDM of the PCell over the cathode ring (`n/psd.8`)
- `sky130_photodiode` (KNOWN FAIL: KLayout DRC, Magic DRC, Magic + Netgen LVS, full-RC PEX)

**Bipolar transistors**

- `sky130_npn_05v5_W1p00L1p00`, `sky130_npn_05v5_W1p00L2p00` (PASS)
- `sky130_npn_11v0_W1p00L1p00` (KNOWN FAIL: Magic DRC, KLayout LVS, Magic + Netgen LVS)
- `sky130_pnp_05v5_W0p68L0p68` (PASS)
- `sky130_pnp_05v5_W3p40L3p40` (KNOWN FAIL: full-RC PEX, `magic-pex3` and `klayout-pex3`)

**Combined test cells**

- `sky130_combined` (KNOWN FAIL: Magic DRC, KLayout LVS, Magic + Netgen LVS) - 16 of the cells above side by side, flattened, on VDD, VSS and G, after `sg13_combined`
- `sky130_short1` (KNOWN FAIL: full-RC PEX, which leaves the NMOS sources unconnected, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)) - 1.8 V and 5 V NMOS and PMOS with every terminal on VDD

### Devices without a cell

- `nfet_20v0`, `nfet_20v0_nvt`, `nfet_20v0_zvt`, `nfet_20v0_iso`, `pfet_20v0`: the PDK has no PCell and no Magic generator for them, and its fixed 20 V layouts are the `rf_nfet_20v0_*` and `esd_rf_nfet_20v0_*` devices, which have no Xschem symbol.
- `nfet_01v8_esd`, `nfet_g5v0d10v5_esd`, `nfet_g5v0d10v5_nvt_esd`: no PCell, no Magic generator, no fixed layout.
- The RF MOS devices (`rf_mosfet` PCell): no Xschem symbol.
