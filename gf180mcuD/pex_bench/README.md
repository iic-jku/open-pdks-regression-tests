# PEX bench for the gf180mcuD Open-PDK

Metal-only dummy layouts whose parasitics can be computed by hand from the PDK extraction deck, extracted with Magic and with the kpex engines, compared term by term, and checked against expected values.
It is the test that says whether the parasitic extractors in IIC-OSIC-TOOLS implement the deck.

This is the [ihp-sg13g2 bench](../../ihp-sg13g2/pex_bench/) ported to gf180mcuD. The geometry is unchanged, the layers and every coefficient are read from this PDK. See that directory's README for the investigation that built the bench, the report on the six defects it found, and the upstream issue drafts. Those defects are properties of the tools, not of the PDK.

**kpex 2.5D cannot extract this PDK's top metal.** `klayout_pex_protobuf/gf180mcuD_tech.pb.json` declares the computed layer `metal5_con` with `"original_layer_name": "MetalTop"`, while every parasitics table in the same file names that layer `Metal5`. One wrong string, two consequences:

- Any cell whose fringe extraction touches the top metal crashes: `RuntimeError: KeyError: 'MetalTop' in EdgeNeighborhoodVisitor.on_edge`. That is `overlap_m4_m5` and `overlap_m1_m5`, listed in `KPEX_KNOWN_FAILS` so the target reports them and carries on. Remove them from that list when kpex is fixed - a listed cell that passes fails the target on purpose.
- `capsub_m5` does not crash but is silently wrong. The `substrates` table happens to carry a stray `MetalTop` row whose coefficients are **sky130A's** met5 values (6.32 aF/um^2 and 38.85 aF/um), so kpex returns 23.5703 fF where the deck gives 20.5722 fF - 14.6 % high. `expected/results.json` pins the value kpex actually produces, as the bench does for Magic's known defects, so the check notices the day it changes.

Magic covers the top metal correctly, so the deck column and the Magic column are complete.

Everything runs inside the IIC-OSIC-TOOLS container from this directory. `make help` lists the targets.

```sh
make pex-bench                  # Magic modes 1/2/3 on every layout, kpex 2.5D on the comparison cells, tables, check
make pex-bench FASTERCAP=1      # also field-solve the comparison cells (KPEX_AMAX=2 by default, minutes)
make magic-pex CELL=cross_m1 EXT_MODE=3 MINDELAY=1      # any single cell, any setting
make klayout-pex CELL=sidewall_m1_s0p8 KPEX_ENGINE=2.5D
make layouts                    # regenerate layout/ from scripts/gen_*.py
make layouts-check              # assert the generators still reproduce layout/ byte for byte
```

The layouts are committed as well as generated. `make layouts-check` guards that pair: the generators write GDS with timestamps disabled, so a regeneration that changes nothing produces byte-identical files, and any real change to a generator shows up as a layout diff that has to be committed deliberately.

## The metal stack

Five conductors, `m5` being the thick top metal. It is called `m5` and not `tm1` as in the two IHP benches because that is what this PDK calls it everywhere - `Metal5` in `libs.tech/klayout/tech/gf180mcu.map`, `allm5`/`metal5` in the Magic deck. There is no separate TopMetal layer and no skipped count, so the name is unambiguous. The pin purpose lives on datatype 10 here, not 2 as in the IHP PDKs.

| Bench name | Magic deck | drawn | pin | Rsheet [mOhm/sq] |
|---|---|---|---|---|
| `m1` | `allm1` / `metal1` | 34/0 | 34/10 | 90 |
| `m2` | `allm2` / `metal2` | 36/0 | 36/10 | 90 |
| `m3` | `allm3` / `metal3` | 42/0 | 42/10 | 90 |
| `m4` | `allm4` / `metal4` | 46/0 | 46/10 | 90 |
| `m5` | `allm5` / `metal5` | 81/0 | 81/10 | 40 |

Vias: `Via1` 35/0 m1-m2, `Via2` 38/0 m2-m3, `Via3` 40/0 m3-m4, `Via4` 41/0 m4-m5. All four are a fixed 0.26 x 0.26 um cut on 0.26 um minimum spacing (rules `V<n>.1` and `V<n>.2a` in `libs.tech/klayout/tech/drc/rule_decks/via.rb`) and all four carry 4500 mOhm per cut. There is one via family, so unlike the IHP benches there is no `vp_*` chain and no `gen_via3.py`. `Via5` appears in the shared gf180mcu layer map but has no metal above it in this metal option.

## What is compared

| Column | How it is produced | What it is |
|---|---|---|
| deck | by hand from `$PDKPATH/libs.tech/magic/gf180mcuD.tech`, extract section, variant `()` | the arithmetic the PDK specifies |
| Magic | `sak-pex.sh`, i.e. `make magic-pex` | Magic's implementation |
| kpex 2.5D | `kpex --2.5D` | a second implementation, reading its coefficients from the kpex tech protobuf |
| FasterCap | `kpex --fastercap` | a boundary-element field solve on the kpex process stack |

`make klayout-pex` with the default `KPEX_ENGINE=magic` is not a further opinion: kpex then drives Magic, and the coupling capacitors are bit-identical to `magic-pex`.

Where Magic and kpex 2.5D disagree, exactly one of them has a bug, and FasterCap arbitrates.

This PDK keeps its extraction rules in the main tech file rather than a separate `<pdk>-extract.tech`. The extract section opens at line 3252 with `style ngspice variants (),(hrhc),(lrhc),(hrlc),(lrlc)`; the nominal resistances are the `variants ()` block at 3311 and the nominal capacitances the one at 3490. Every coefficient is repeated per corner, so a value taken from the wrong block is a plausible-looking wrong number. The hand-maintained tables in `scripts/analyse.py` and `scripts/compare_engines.py` are transcribed from those two blocks only.

## Structures

All in `layout/`, 50 cells, regenerated by `make layouts` from `scripts/gen_*.py`. Each isolates one term.

| Cells | Term | Geometry |
|---|---|---|
| `capsub_<layer>` | area and perimeter to substrate | a 50 x 50 um plate (A/P = 12.5) and a 0.5 x 50 um wire (A/P = 0.25), 60 um apart, so the two coefficients separate |
| `overlap_<lower>_<upper>` | plate-to-plate and edge fringe | a 10 x 10 um upper plate centred in a 30 x 30 um lower one; the four adjacent pairs plus `m1_m3` and `m1_m5` |
| `sidewall_m1_s<spacing>` | lateral coupling | two 0.5 x 50 um Metal1 wires at 0.2, 0.4, 0.8, 1.6, 3.2 um |
| `res_<layer>` | sheet resistance | 1 um wide wire, ports 99 um apart (99 squares, Magic measures between labels) |
| `vc_*` | contact resistance | via chains with 1, 2, 3, 4, 8 cuts, legal spacing, wide landing metal |
| `res_long_m1`, `res_long3_m1`, `res_tee_m1`, `tee_asym_m1`, `cross_m1` | extresist gating and topology | a 1000 um wire, with and without a middle port, and branched nets with distinct arm lengths |
| `rc_pair_m1`, `rc_tee_pair_m1` | coupling on a resistive net | two wires that also branch |
| `gf180mcu_fd_sc_mcu7t5v0__inv_1`, `hier_test` | the `ext2spice hierarchy` defect | one standard cell, and the same cell with a 200 um Metal2 wire on its input |

The standard cell's input pin is called `I` here, not `A` as in the IHP libraries, and this library ships one GDS per library rather than one per cell. It draws no pin boxes on the Metal1 pin datatype, only labels, so `gen_hier.py` takes the landing metal from the drawn Metal1 shape the label falls inside.

The geometry was carried over from ihp-sg13g2 unchanged and is not DRC clean for this PDK. That was a deliberate call: the bench measures extractor arithmetic on known shapes, and identical shapes across PDKs are what make the columns comparable. Fitting the shapes to this PDK's rules would move every hand-computed number.

## Outputs and the check

- `netlist/pex/<cell>_magic_pex_<mode>.spice`, `netlist/pex/kpex/2.5D/<cell>/`, `netlist/pex/kpex/fastercap/<cell>_a<amax>/` are the run outputs (ignored by git).
- `scripts/analyse.py` prints tables A to E (deck against Magic), `scripts/compare_engines.py` tables F to I (all engines against the field solve). Both write their values to JSON.
- `scripts/check_results.py` compares that JSON with `expected/results.json`: deck, Magic and kpex 2.5D values to 0.05 %, FasterCap to 5 % (the triangulation is rebuilt every run, so points scatter). FasterCap values are optional in the check, so the bench passes without a field solve.
- Its exit code says what drifted, so a CI test can triage without reading the log: `0` clean, `1` a deck value moved (the hand-maintained tables were edited), `2` only tool values moved, `3` the run is incomplete or the fresh file is missing or broken, `4` usage error or the expected file is missing.

`make pex-bench-expected` overwrites `expected/results.json` with a fresh run. Do that after a deliberate change (a new tool version that fixes a defect), never to make a failing check pass.

This directory ships no `expected/fastercap/` matrices, so the FasterCap column stays empty until a field solve is run locally with `FASTERCAP=1`.

To produce a set, use `scripts/make_fastercap_expected.sh` in the repository root, which takes
the PDK as an argument and writes a `PROVENANCE.md` beside the matrices. What those matrices
contain, why there are a Raw and an Avg one, and how to choose `--delaunay_amax` and
`--tolerance` is written up once, in
[../../ihp-sg13g2/pex_bench/README.md](../../ihp-sg13g2/pex_bench/README.md#where-the-fastercap-numbers-come-from).

## Notes for anyone extending this

- Magic measures resistance between the label positions, not the wire ends. A 100 um wire with ports 0.5 um in from each end is 99 squares.
- Read every coefficient from this PDK's own deck. Reusing another PDK's table minus a row is the one mistake that fails silently: the layer names line up, the numbers do not. The `MetalTop` row above is exactly that mistake, made in kpex's tech file.
- Keep via cuts inside the landing metal and on legal spacing. Cuts that fall off the metal make it look as though Magic is miscounting parallel vias when it is counting exactly what is there.
- Structures meant not to couple must be more than `sidehalo` (8 um here) apart. The bench uses 60 um.
- Text on the pin datatype (`34/10` for Metal1) becomes a port. The pin box is OR'ed into the metal, so keep it inside the drawn shape.
