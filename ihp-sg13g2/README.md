# Open-PDK LVS / DRC / PEX Regression Tests for the ihp-sg13g2 Open-PDK

> This Makefile-driven repository runs standalone LVS, DRC, and PEX regression tests on individual cells of the ihp-sg13g2 Open-PDK, using both KLayout and Magic+Netgen.

## Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

## Export Schematic Netlist for LVS

- `make klayout-lvs-netlist`
- `make klayout-lvs-netlist CELL=sg13_lv_nmos_tap`
- `make klayout-lvs-netlist EV_PRECISION=5`
- `make magic-lvs-netlist`
- `make magic-lvs-netlist CELL=sg13_lv_nmos_tap`
- `make magic-lvs-netlist EV_PRECISION=5`

## Layout Versus Schematic (LVS)

- `make klayout-lvs`
- `make klayout-lvs CELL=sg13_lv_nmos_tap`
- `make magic-lvs`
- `make magic-lvs CELL=sg13_lv_nmos_tap`

## Design Rule Check (DRC)

- `make klayout-drc`
- `make klayout-drc CELL=sg13_lv_nmos_tap`
- `make klayout-drc CELL=sg13_lv_nmos_tap DRC_LEVEL=regular`
- `make magic-drc`
- `make magic-drc CELL=sg13_lv_nmos_tap`

## Parasitic Extraction (PEX)

- `make klayout-pex`
- `make klayout-pex CELL=sg13_lv_nmos_tap`
- `make klayout-pex CELL=sg13_lv_nmos_tap EXT_MODE=3`
- `make magic-pex`
- `make magic-pex CELL=sg13_lv_nmos_tap`
- `make magic-pex CELL=sg13_lv_nmos_tap EXT_MODE=3`
- `make magic-pex CELL=sg13_lv_nmos_tap EXT_MODE=3 THRESHOLD=5000 MINRES=500 MINDELAY=2`

## Regression

Runs LVS, DRC, and PEX for every `.gds` in `layout/` and prints a pass/fail summary.

```sh
make regression
```

## Supported Cells / Files

The `regression` target auto-discovers every cell from the `.gds` files in `layout/`. Each cell has a matching layout (`layout/<cell>.gds`) and schematic (`schematic/xschem/<cell>.sch`). Pass any of these names via `CELL=<cellname>` to run a single target on one cell.

**Low-voltage MOS transistors**

- `sg13_lv_nmos_tap`
- `sg13_lv_pmos_tap`
- `sg13_lv_nmos_ring_dev`
- `sg13_lv_nmos_ring_pcell`
- `sg13_lv_pmos_ring_dev`
- `sg13_lv_pmos_ring_pcell`
- `sg13_lv_rf_nmos`
- `sg13_lv_rf_pmos`

**High-voltage MOS transistors**

- `sg13_hv_nmos_tap`
- `sg13_hv_pmos_tap`
- `sg13_hv_nmos_ring_dev`
- `sg13_hv_nmos_ring_pcell`
- `sg13_hv_pmos_ring_dev`
- `sg13_hv_pmos_ring_pcell`
- `sg13_hv_rf_nmos`
- `sg13_hv_rf_pmos`

**Capacitors**

- `sg13_cmim`
- `sg13_rf_cmim`

**Resistors**

- `sg13_rhigh`
- `sg13_rppd`
- `sg13_rsil`

**Diodes & antennas**

- `sg13_dantenna`
- `sg13_dpantenna`
- `sg13_schottky_nbl1`

**Combined test cells**

- `sg13_combined`
- `sg13_combined_wo_rfcmim`
- `sg13_combined_cmim_ontop`
- `sg13_combined_cmim_ontop_wo_rfcmim`
