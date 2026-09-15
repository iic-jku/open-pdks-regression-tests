# PEX bench for the sky130A Open-PDK

Metal-only dummy layouts whose parasitics can be computed by hand from the PDK extraction deck, extracted with Magic and with the kpex engines, compared term by term, and checked against expected values.
It is the test that says whether the parasitic extractors in IIC-OSIC-TOOLS implement the deck.

This is the [ihp-sg13g2 bench](../../ihp-sg13g2/pex_bench/) ported to sky130A. The geometry is unchanged, the layers and every coefficient are read from this PDK. See that directory's README for the investigation that built the bench, the report on the six defects it found, and the upstream issue drafts. Those defects are properties of the tools, not of the PDK.

Unlike the other three directories in this repository, `sky130A/` has no DRC/LVS regression yet (`coming soon.txt`) and therefore no PDK-level Makefile. This bench is self-contained: it includes `../../common.mk` itself, so run it from here.

## The metal stack

Six conductors. This is the only one of the four PDKs whose stack starts below Metal1: `li1`, the local interconnect, is a conductor in its own right, with a sheet resistance two orders of magnitude above the metals (12.8 Ohm/square against 0.125 for met1). The bench covers it like any other layer, so `res_li1` comes out at 1.27 kOhm where the metals are single-digit ohms.

Names follow `libs.tech/klayout/tech/sky130A.map`, which calls the layers `li1` and `met1` to `met5`; the Magic deck calls the same layers `allli`/`locali` and `allm<n>`/`metal<n>`, so the bench's short names `li1` and `m1` to `m5` are unambiguous. This PDK stacks purposes in the datatype: 20 is the drawn shape, 16 the pin, 44 the via cut, 5 the label.

| Bench name | Magic deck | drawn | pin | Rsheet [mOhm/sq] |
|---|---|---|---|---|
| `li1` | `allli` / `locali` | 67/20 | 67/16 | 12800 |
| `m1` | `allm1` / `metal1` | 68/20 | 68/16 | 125 |
| `m2` | `allm2` / `metal2` | 69/20 | 69/16 | 125 |
| `m3` | `allm3` / `metal3` | 70/20 | 70/16 | 47 |
| `m4` | `allm4` / `metal4` | 71/20 | 71/16 | 47 |
| `m5` | `allm5` / `metal5` | 72/20 | 72/16 | 29 |

Five via levels, and the widest spread of cut sizes and resistances of any of the four PDKs:

| Level | deck name | cut | size | min spacing | mOhm/cut |
|---|---|---|---|---|---|
| li1-m1 | `mcon` | 67/44 | 0.17 | 0.19 | 9300 |
| m1-m2 | `m2c` | 68/44 | 0.15 | 0.17 | 4500 |
| m2-m3 | `m3c` | 69/44 | 0.20 | 0.20 | 3410 |
| m3-m4 | `via3` | 70/44 | 0.20 | 0.20 | 3410 |
| m4-m5 | `via4` | 71/44 | 0.80 | 0.80 | 380 |

There is one via family per level, so as in gf180mcuD there is no `vp_*` chain and no `gen_via3.py`. The via chains use a 16 um wide landing arm rather than the 12 um of the IHP benches, because `via4`'s eight 0.8 um cuts on 0.8 um spacing need 12 um of room.

Note that `cifinput` grows the via layers before forming the contact: `VIA3` by 60 nm per side and `VIA4` by 190 nm, so a drawn 0.8 um `via4` becomes 1.18 um inside Magic. Anything narrower than that will not form a contact even though the drawn cut looks legal.

## Table E is incomplete, and the reason is not the deck

Magic emits no resistor at all for `vc_m3_m4_*` and `vc_m4_m5_*`, at any `extresist` setting - swept over `MINDELAY` 0 and 1 and `THRESHOLD` 0, 1, 10 and 100 mOhm, always nothing. The other three levels are exact to 0.00 %. `analyse.py` skips a level whose `n=1` cell has no resistor, since it needs that value as the metal baseline, so table E covers li1-m1, m1-m2 and m2-m3 only.

The cause is the magnitude, not the contact. With a 16 um wide arm the m3-m4 chain is only 3.70 Ohm end to end (0.145 + 3.41 + 0.145) and the m4-m5 chain 0.62 Ohm, against 3.94 Ohm for m2-m3, which does come through. Magic appears to apply a coarse end-to-end floor somewhere between those two figures that no documented setting lifts.

Repeating the same structure with a narrow, resistive arm shows the contact values themselves are right:

| probe | arm | measured | deck arithmetic |
|---|---|---|---|
| m3-m4, one `via3` | 1 um wide, 49.5 um per arm | 8.0635 Ohm | 2 x 49.5 x 47 mOhm + 3410 mOhm = 8.063 |
| m4-m5, one `via4` | 2 um wide, 49.5 um per arm | 2.26195 Ohm | 24.75 x 47 + 24.75 x 29 + 380 mOhm = 2.261 |

So all five contact resistances in this PDK are correct, `via3`'s value is additionally covered by the m2-m3 row (both are 3410 mOhm), and only `via4`'s 380 mOhm has no row in table E. The probe cells are deliberately not part of the bench: giving one PDK a different via-chain geometry would cost the property that makes the four benches comparable.

## What is compared

| Column | How it is produced | What it is |
|---|---|---|
| deck | by hand from `$PDKPATH/libs.tech/magic/sky130A.tech`, extract section, variant `()` | the arithmetic the PDK specifies |
| Magic | `sak-pex.sh`, i.e. `make magic-pex` | Magic's implementation |
| kpex 2.5D | `kpex --2.5D` | a second implementation, reading its coefficients from the kpex tech protobuf |
| FasterCap | `kpex --fastercap` | a boundary-element field solve on the kpex process stack |

`make klayout-pex` with the default `KPEX_ENGINE=magic` is not a further opinion: kpex then drives Magic, and the coupling capacitors are bit-identical to `magic-pex`.

Where Magic and kpex 2.5D disagree, exactly one of them has a bug, and FasterCap arbitrates.

This PDK keeps its extraction rules in the main tech file rather than a separate `<pdk>-extract.tech`. The extract section opens at line 5006 with `style ngspice variants (),(orig),(si),(hrhc),(lrhc),(hrlc),(lrlc)`; the nominal resistances are the `variants (),(orig),(si)` block at 5095 and the nominal capacitances the one at 5266. Every coefficient is repeated per corner, so a value taken from the wrong block is a plausible-looking wrong number. The hand-maintained tables in `scripts/analyse.py` and `scripts/compare_engines.py` are transcribed from those two blocks only.

Unlike ihp-sg13cmos5l and gf180mcuD, this PDK's `klayout_pex_protobuf/sky130A_tech.pb.json` is consistent with its deck: every `sidewalls` and `substrates` value matches, and the computed-layer names resolve to layers the parasitics tables know.

## Structures

All in `layout/`, 58 cells, regenerated by `make layouts` from `scripts/gen_*.py`. Each isolates one term.

| Cells | Term | Geometry |
|---|---|---|
| `capsub_<layer>` | area and perimeter to substrate | a 50 x 50 um plate (A/P = 12.5) and a 0.5 x 50 um wire (A/P = 0.25), 60 um apart, so the two coefficients separate |
| `overlap_<lower>_<upper>` | plate-to-plate and edge fringe | a 10 x 10 um upper plate centred in a 30 x 30 um lower one; the five adjacent pairs plus `m1_m3` and `m1_m5` |
| `sidewall_m1_s<spacing>` | lateral coupling | two 0.5 x 50 um met1 wires at 0.2, 0.4, 0.8, 1.6, 3.2 um |
| `res_<layer>` | sheet resistance | 1 um wide wire, ports 99 um apart (99 squares, Magic measures between labels) |
| `vc_*` | contact resistance | via chains with 1, 2, 3, 4, 8 cuts, legal spacing, wide landing metal |
| `res_long_m1`, `res_long3_m1`, `res_tee_m1`, `tee_asym_m1`, `cross_m1` | extresist gating and topology | a 1000 um wire, with and without a middle port, and branched nets with distinct arm lengths |
| `rc_pair_m1`, `rc_tee_pair_m1` | coupling on a resistive net | two wires that also branch |
| `sky130_fd_sc_hd__inv_1`, `hier_test` | the `ext2spice hierarchy` defect | one standard cell, and the same cell with a 200 um met2 wire on its input |

Reaching that wire takes two cuts here, not one as in the other PDKs: the standard cell's pins are on `li1` and `met1` is already occupied by the power rails, so `gen_hier.py` builds `li1 -> mcon -> met1 pad -> via -> met2`. The pin is labelled `A` on the li1 label purpose 67/5, while the pin box that positions the cut is on 67/16 and is exactly one `mcon` wide.

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
- Read every coefficient from this PDK's own deck. Reusing another PDK's table minus a row is the one mistake that fails silently: the layer names line up, the numbers do not.
- Keep via cuts inside the landing metal and on legal spacing, and remember the `cifinput` growth above when sizing the metal around a cut.
- Structures meant not to couple must be more than `sidehalo` (8 um here) apart. The bench uses 60 um.
- Text on the pin datatype (`68/16` for met1) becomes a port. The pin box is OR'ed into the metal, so keep it inside the drawn shape.
