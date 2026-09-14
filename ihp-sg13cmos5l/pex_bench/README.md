# PEX bench for the ihp-sg13cmos5l Open-PDK

Metal-only dummy layouts whose parasitics can be computed by hand from the PDK extraction deck, extracted with Magic and with the kpex engines, compared term by term, and checked against expected values.
It is the test that says whether the parasitic extractors in IIC-OSIC-TOOLS implement the deck.

This is the ihp-sg13g2 bench ported to ihp-sg13cmos5l. The geometry is unchanged, the layers and every coefficient are read from this PDK. See [../../ihp-sg13g2/pex_bench/README.md](../../ihp-sg13g2/pex_bench/README.md) for the investigation that built the bench, the report on the six defects it found, and the upstream issue drafts. Those defects are properties of the tools, not of the PDK.

Two results of this port are worth reading before trusting a number here:

- **kpex's sidewall coefficients for this PDK are ihp-sg13g2's.** `klayout_pex_protobuf/ihp-sg13cmos5l_tech.pb.json` holds the ihp-sg13g2 `sidewalls` list with the `Metal5` and `TopMetal2` rows removed and `allm6` relabelled `TopMetal1`; none of the six remaining values is from `ihp-sg13cmos5l-extract.tech`. Metal1 is 43.268 aF / +0.003 um in the deck and 28.735 / -0.057 in kpex. Because the two offsets pull in opposite directions the error grows with spacing: -5.7 % at 0.2 um, -32.3 % at 3.2 um. Table H is the row that shows it.

  The sidewall block is the worst of it but not all of it. A full audit of that file against this PDK's deck, in `klayout-pex-docu/Issue_cmos5l_sidewall_coefficients.md`, finds **36 of 107 coefficients** carrying the ihp-sg13g2 value: the 6 sidewall entries, 26 `sideoverlaps` and 4 substrate perimeters. The area quantities are correct throughout. Root cause is `cxx/gen_tech_pb/pdk/ihp_sg13.cpp`, which builds both PDKs from one function: wherever an `is_g2()` branch exists because the layer set differs the cmos5l value was entered, and wherever the layer exists in both but the value differs, the sg13g2 value stands.

  Do not conclude from a diff of the two tech files that the rest is fine - that was our first reading and it is wrong. A coefficient that is bad *because* it equals ihp-sg13g2's shows up as identical in such a diff. Only a comparison against this PDK's own deck finds it.
- **The table B / G deficit is lost, not moved to the substrate.** Magic gets the plate-to-plate term (100 um^2 x overlap coefficient) exactly right in all six pairs and under-delivers only the 40 um of edge fringe, by a fraction that falls monotonically with vertical separation: 94.1 % delivered for the adjacent thin-metal pairs, 90.7 % for m4-tm1, 83.2 % for m1-m3, 62.1 % for m1-tm1. `sidehalo` is 8 um while the lower plate extends 10 um past the upper one on every side, so the halo, not the plate edge, is what truncates the integration. The top-plate-to-substrate capacitance Magic emits alongside it does not absorb the deficit: it depends only on the upper layer (0.37505 fF for both `overlap_m2_m3` and `overlap_m1_m3`, 0.65826 fF for both `overlap_m4_tm1` and `overlap_m1_tm1`) while the deficits of those pairs differ by more than a factor of two.

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

cmos5l has four thin metals and one thick top metal. The top metal is named `tm1` throughout the bench, as in ihp-sg13g2, because it is the same physical layer: GDS 126, 18 mOhm/square, and the same family of coefficients. The Magic deck calls it `metal5` / `allm5`; the bridge is `calma MET5 126 0` in `libs.tech/magic/ihp-sg13cmos5l-cifin.tech`. The thin `m5` of ihp-sg13g2 does not exist here, so the count 5 is deliberately skipped rather than reused.

| Bench name | Magic deck | GDS | Rsheet [mOhm/sq] |
|---|---|---|---|
| `m1` | `allm1` / `metal1` | 8/0 | 110 |
| `m2` | `allm2` / `metal2` | 10/0 | 88 |
| `m3` | `allm3` / `metal3` | 30/0 | 88 |
| `m4` | `allm4` / `metal4` | 50/0 | 88 |
| `tm1` | `allm5` / `metal5` | 126/0 | 18 |

Vias: `via1` m1-m2, `via2` m2-m3, `via3` m3-m4 at 9000 mOhm/cut each, `via4` m4-tm1 at 2200 mOhm/cut.

## What is compared

| Column | How it is produced | What it is |
|---|---|---|
| deck | by hand from `$PDKPATH/libs.tech/magic/ihp-sg13cmos5l-extract.tech`, variant `()` | the arithmetic the PDK specifies |
| Magic | `sak-pex.sh`, i.e. `make magic-pex` | Magic's implementation |
| kpex 2.5D | `kpex --2.5D` | a second implementation, reading the identical coefficients from the kpex tech protobuf |
| FasterCap | `kpex --fastercap` | a boundary-element field solve on the kpex process stack |

**Both kpex columns are empty in this PDK today, and the bench does not ask for them.** The
kpex wheel ships the `sg13cmos5l` LVS deck without the 47 rule decks it `%include`s, so
`create_lvsdb` fails before an engine is even chosen and no kpex run of any kind succeeds on
an unmodified container. The bench therefore declares `PEX_ENGINES := magic` in its Makefile,
the regression test calls no kpex engine here, and `expected/results.json` holds only the deck
and Magic columns. Nothing is tolerated or hidden: the values are absent, not wrong. Once the
wheel ships the rule decks, put `kpex25 fastercap` back into `PEX_ENGINES` and bless the
columns with `make pex-bench-expected`. See `../../ihp-sg13g2/pex_bench/report/upstream_issues_kpex.md`.

`make klayout-pex` with the default `KPEX_ENGINE=magic` is not a further opinion: kpex then drives Magic, and the coupling capacitors are bit-identical to `magic-pex`.

Where Magic and kpex 2.5D disagree, exactly one of them has a bug, and FasterCap arbitrates.

The nominal `()` variant is the first of six in `style ngspice` (`(),(lvs),(hrhc),(lrhc),(hrlc),(lrlc)`). The deck repeats every coefficient per corner, so a value taken from the wrong block is a plausible-looking wrong number. The hand-maintained tables in `scripts/analyse.py` and `scripts/compare_engines.py` are transcribed from that block only.

## Structures

All in `layout/`, 54 cells, regenerated by `make layouts` from `scripts/gen_*.py`. Each isolates one term.

| Cells | Term | Geometry |
|---|---|---|
| `capsub_<layer>` | area and perimeter to substrate | a 50 x 50 um plate (A/P = 12.5) and a 0.5 x 50 um wire (A/P = 0.25), 60 um apart, so the two coefficients separate |
| `overlap_<lower>_<upper>` | plate-to-plate and edge fringe | a 10 x 10 um upper plate centred in a 30 x 30 um lower one; the four adjacent pairs plus `m1_m3` and `m1_tm1` |
| `sidewall_m1_s<spacing>` | lateral coupling | two 0.5 x 50 um Metal1 wires at 0.2, 0.4, 0.8, 1.6, 3.2 um |
| `res_<layer>` | sheet resistance | 1 um wide wire, ports 99 um apart (99 squares, Magic measures between labels) |
| `vc_*`, `vp_*` | contact resistance | via chains with 1, 2, 3, 4, 8 cuts, legal spacing, wide landing metal |
| `res_long_m1`, `res_long3_m1`, `res_tee_m1`, `tee_asym_m1`, `cross_m1` | extresist gating and topology | a 1000 um wire, with and without a middle port, and branched nets with distinct arm lengths |
| `rc_pair_m1`, `rc_tee_pair_m1` | coupling on a resistive net | two wires that also branch |
| `sg13cmos5l_inv_1`, `hier_test` | the `ext2spice hierarchy` defect | one standard cell from `sg13cmos5l_stdcell`, and the same cell with a 200 um Metal2 wire on its gate |

The m4-tm1 transition is covered by both a `vc` and a `vp` chain, as in ihp-sg13g2, even though the resistance per cut is the same: the bench tests each drawn via layer separately.

The geometry was carried over from ihp-sg13g2 unchanged and is not DRC clean for this PDK. That was a deliberate call: the bench measures extractor arithmetic on known shapes, and identical shapes across PDKs are what make the columns comparable. Fitting the shapes to this PDK's rules would move every hand-computed number.

## Outputs and the check

- `netlist/pex/<cell>_magic_pex_<mode>.spice`, `netlist/pex/kpex/2.5D/<cell>/`, `netlist/pex/kpex/fastercap/<cell>_a<amax>/` are the run outputs (ignored by git).
- `scripts/analyse.py` prints tables A to E (deck against Magic), `scripts/compare_engines.py` tables F to I (all engines against the field solve). Both write their values to JSON.
- `scripts/check_results.py` compares that JSON with `expected/results.json`: deck, Magic and kpex 2.5D values to 0.05 %, FasterCap to 5 % (the triangulation is rebuilt every run, so points scatter). FasterCap values are optional in the check, so the bench passes without a field solve.
- Its exit code says what drifted, so a CI test can triage without reading the log: `0` clean, `1` a deck value moved (the hand-maintained tables were edited), `2` only tool values moved, `3` the run is incomplete or the fresh file is missing or broken, `4` usage error or the expected file is missing.

`make pex-bench-expected` overwrites `expected/results.json` with a fresh run. Do that after a deliberate change (a new tool version that fixes a defect), never to make a failing check pass.

Unlike the ihp-sg13g2 bench this directory ships no `expected/fastercap/` matrices, so the FasterCap column stays empty until a field solve is run locally with `FASTERCAP=1`.

To produce a set, use `scripts/make_fastercap_expected.sh` in the repository root, which takes
the PDK as an argument and writes a `PROVENANCE.md` beside the matrices. What those matrices
contain, why there are a Raw and an Avg one, and how to choose `--delaunay_amax` and
`--tolerance` is written up once, in
[../../ihp-sg13g2/pex_bench/README.md](../../ihp-sg13g2/pex_bench/README.md#where-the-fastercap-numbers-come-from).

## Notes for anyone extending this

- Magic measures resistance between the label positions, not the wire ends. A 100 um wire with ports 0.5 um in from each end is 99 squares.
- Read every coefficient from this PDK's own deck. Reusing another PDK's table minus a row is the one mistake that fails silently: the layer names line up, the numbers do not.
- Keep via cuts inside the landing metal and on legal spacing. Cuts that fall off the metal make it look as though Magic is miscounting parallel vias when it is counting exactly what is there.
- Structures meant not to couple must be more than `sidehalo` apart. The bench uses 60 um.
- Text on the pin datatype (`8/2` for Metal1) becomes a port. The pin box is OR'ed into the metal, so keep it inside the drawn shape.
- kpex names the dummy nets `$2`, `$3` because there is no schematic to match against. `compare_engines.py` identifies them by magnitude, which only works because the bench shapes are deliberately very different in size.
