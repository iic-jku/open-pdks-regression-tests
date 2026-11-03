# Findings and work-arounds for the sky130A PDK

Things in this PDK that are easy to get wrong and frustrating to troubleshoot. The layouts in this directory are built from the `skywater130` KLayout PCells of the PDK. Where a PCell draws something that breaks a rule of the [SkyWater periphery rules](https://skywater-pdk.readthedocs.io/en/main/rules/periphery.html), the cell repairs it and the section below says what and why. Where a layout follows the rules and a tool still fails on it, the cell is left as it is and the failure is a `KNOWN_FAILS` entry, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

Observed on the IIC-OSIC-TOOLS nightly image of 2026-10-22 with KLayout 0.30.12 and Magic 8.3.685, PDK open_pdks `1689ac3`.

## The KLayout DRC deck misses rules

`sak-drc.sh` runs `libs.tech/klayout/drc/sky130A_mr.drc`, which has no check for several periphery rules. Every cell below broke one of them before it was repaired, and KLayout DRC passed it:

| Rule | What it asks | Cells that broke it | Magic DRC |
| --- | --- | --- | --- |
| `hvdifftap.16` | a tap butted to diffusion inside HVI reaches 0.7 um away from it | the four MV `_tap` cells | reports it |
| `hvdifftap.19` | HV Nwell encloses an N+ tap by 0.33 um | `sky130_pfet_g5v0d10v5_ring_pcell` | reports it |
| `hvdifftap.20` | P+ tap 0.43 um from an HV Nwell | `sky130_diode_pd2nw_11v0` | reports it |
| `hvdifftap.23` | diffusion or tap outside HVI 0.18 um from HVI | the three MV NMOS `_ring_pcell` cells | misses it |
| `licon.7` | a licon on an isolated tap is enclosed by 0.12 um in one direction | `sky130_dnwell_nmos` | reports it |
| `licon.15` | NPC encloses a poly licon by 0.1 um | every MOS cell | misses it |
| `n/psd.8` | no PSDM over N+ diffusion or tap, no NSDM over P+ | the four `sky130_diode_pd2nw_*` cells | reports follow-on errors |
| `varac.5` | Nwell encloses the varactor gate poly by 0.15 um | `sky130_cap_var_lvt`, `sky130_cap_var_hvt` | reports it for `lvt` only |

The sections below say what was wrong in each cell. `hvdifftap.19`, `hvdifftap.23` and `licon.7` were mistakes in how these cells were drawn, the others come from the PCells. Four cells keep one of these errors on purpose, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

The older deck in the same directory, `sky130A.lydrc`, checks all eight, but only with its `FEOL` switch set to `true` (it is `false` in the file), and `hvdifftap.16` along the butting edge instead of across the tap. On the cells here it also reports rules that hold: `hvdifftap.16` at the repaired MV `_tap` cells, for that reason, `licon.1` at the 0.19 x 2.0 um contacts of the `res_xhigh_po` resistors, which `licon.1b`/`licon.1c` allow for precision resistors (it exempts them under RPM only, not URPM), `licon.7` at the poly contacts of the `res_high_po` resistors, and `licon.17` at the varactor gate, where no licon touches both poly and diffusion. It is not part of the regression.

## Magic generates NPC and HVI itself

Magic's GDS import does not read the drawn NPC (`ignore NPC`, line 2356 of `libs.tech/magic/sky130A.tech`), and it keeps no HVI layer: it only turns diffusion inside HVI into its MV types. It generates both layers when it writes GDS. Magic DRC therefore cannot check NPC around a poly contact (`licon.15`) or a tap beside the HVI edge (`hvdifftap.23`) in a layout drawn elsewhere. For RPM it checks a layer of its own instead of the drawn one, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## KLayout LVS needs two deck switches for Xschem netlists

The `sky130_fd_pr` MOS symbols write their CDL line as a subcircuit call with W and L in micrometers, meant for `.option scale=1e-6`:

```
XM1 D G S S sky130_fd_pr__nfet_01v8 L=0.15 W=0.42 nf=1
```

The `sky130.lvs` deck reads such lines as devices only with `-rd convert_subckts=true` (`wants_subcircuit` in `SubcircuitModelsReader`); otherwise they stay calls of an empty subcircuit. And it only matches the micrometer values with `-rd scale=true` (`device_scaling(1000000)`). `sak-lvs.sh` passes neither switch, and the PDK's `run_lvs.py` has no option for `convert_subckts` at all. With both switches the MOS cells here pass KLayout LVS; with only one of them they do not. `klayout-lvs` is therefore not among the regression steps of this directory, see the [Makefile](Makefile).

## Bulk tie is butted against the source

`bulk = "bulk tie"` of the `nfet`/`pfet` PCells butts the tap against the source diffusion and gives it its own li1, not connected to the source li1. Source and bulk are one net through the silicide. The `_tap` cells tie the bulk to the source in the schematic and strap the tap li1 to the source li1, as the gf180mcuD `_tap` cells do with Metal1.

Inside HVI a tap butted to diffusion has to reach at least 0.7 um away from the butting edge (`hvdifftap.16`, "Min width tap butting diff on one or two sides"; the figure of the rule measures across the tap, like `difftap.4` and `difftap.5` for a tap bound by one or two diffusions). The bulk tie of the PCell reaches 0.45 um (`nfet`) or 0.39 um (`pfet`), and its `grw` parameter does not change that. The `_tap` cells of the MV devices (`nfet_03v3_nvt`, `nfet_05v0_nvt`, `nfet_g5v0d10v5`, `pfet_g5v0d10v5`) extend the tap to 0.7 um in the top cell, with its implant (0.125 um, `n/psd.5b`), HVI (0.18 um, `hvdifftap.22`) and, for the PMOS, the HV Nwell (0.33 um, `hvdifftap.19`).

## NPC around the poly contacts

The `nfet`, `pfet` and `cap_var` PCells draw NPC closer around their poly contacts than `licon.15` allows: in `nfet_01v8` and `cap_var_lvt` 0.06 um beside and 0.09 um above and below the 0.17 um contact, where the rule asks for 0.1 um. The cells add an NPC box 0.1 um around every poly contact. Neither DRC of the regression sees the difference, see above.

## Guard rings end on li1

`bulk = "guard ring"` of the MOS PCells and the `guard_ring_gen` PCell (with `con_lev = "li"`) draw the ring tap and li1 but no Metal1. The B pin of the `_ring` and `_ring_pcell` cells is therefore on li1 (`li1.pin` 67/16 plus `li1.label` 67/5), all other pins on Metal1 (68/16 plus 68/5).

## guard_ring_gen is not centred on its origin

The `guard_ring_gen` PCell does not place its ring around the origin. The `_ring_pcell` cells measure the hole of a probe instance and move the ring so that the hole is centred on the device.

## guard_ring_gen draws no well and no HVI

`guard_ring_gen` draws the tap ring only. Around a PMOS the cells widen the PCell's Nwell over the N+ ring, 0.18 um beyond the tap (`difftap.10`), 0.33 um for `pfet_g5v0d10v5` (`hvdifftap.19`), and keep the widened Nwell inside HVI with the enclosure the PCell uses (`hvnwell.9`). Around an MV NMOS the cells widen HVI over the ring, 0.18 um beyond the tap (`hvdifftap.22`); without that the ring lies 0.025 um outside the HVI edge, where `hvdifftap.23` asks for 0.18 um.

The added Nwell and HVI are drawn in the top cell, the ring is in the PCell. Magic evaluates its GDS import within each cell and does not combine the two, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## KLayout LVS findings behind the two switches

What the `sky130.lvs` deck does with the cells here once `convert_subckts=true` and `scale=true` are set:

- **Diode parameters.** The `diode.sym` symbol writes `area=` and `perim=`; the deck's reader only knows `A` and `P` and reads the schematic diode as `A=0 P=0`. With the CDL rewritten to `A=0.2025 P=1.8` all eight diode cells match.
- **Diode polarity.** The deck extracts `diode_pw2nd_05v5_lvt`, `_nvt` and `_11v0` reversed: their `tA`/`tC` terminal layers are swapped against `diode_pw2nd_05v5` (lines 2145-2157), and the extracted line reads `XD$1 C A`. In a single-diode cell this cannot be seen, since the comparison is free to swap the two top-level pins: a schematic with the diode deliberately reversed matches as well.
- **MIM capacitors.** The deck extracts the two MIM options as `sky130_fd_pr__model__cap_mim` and `sky130_fd_pr__model__cap_mim_m4`, while the models and symbols are `cap_mim_m3_1` and `cap_mim_m3_2`, so the device classes never match.
- **Isolated P-well.** `ptap_conn` (line 1158) excludes taps in Nwell but not in DNWELL, and `connect_global(ptap_conn, substrate_name)` (line 1862) joins every P tap to the substrate. The two ends of `sky130_res_iso_pw` sit on P taps inside DNWELL and are extracted as one net, `XR$1 R0|R1 R0|R1 B`. In `sky130_dnwell_nmos` and `sky130_dnwell_inv` the isolated P-well, which is the NMOS bulk and source, comes out as `S|VSS`, one net with the substrate ring. KLayout still reports these two cells as matching, since the schematic VSS pin connects to no device and drops out of the comparison: a pass for a layout the deck has shorted. Magic extracts the isolation correctly.
- **Three-terminal capacitors.** The reader turns an `X` line into a device by handing it on as a `C` element (`el = name[0]`, then `super`), past its own branch for three-terminal VPP capacitors, which only runs for lines that already start with `C` (line 358). The standard `C` element takes two nodes, so the schematic `cap_var_*` and `cap_vpp_*` instances, which have three, never become devices, while the layout side extracts them.
- **16 V MOS.** The deck has no extraction for `nfet_g5v0d16v0` and `pfet_g5v0d16v0` (the name does not occur in `sky130.lvs`), so KLayout extracts no device from these cells.
- **`npn_11v0`.** The extraction of `sky130_fd_pr__npn_11v0_W1p00L1p00` (line 2115) aborts on KLayout 0.30.12 with `There are multiple conversion constructors available to convert object of type PolygonWithProperties to type Region`, and no report is written.

## PCells widen length and width silently

`res_poly` raises `len` to its minimum without reporting it in its parameters: `res_high_po_*` and `res_xhigh_po_*` at the default `len=0.5` are drawn 0.62 um long. `res_iso_pw` ignores `w`/`len` and draws 2.65 x 26.5 um, and `mim_cap` draws the Metal4-Metal5 option at 2.16 x 2.16 um for `w = l = 2`. The cells take W and L from the resistor marker (66/13, 65/13 or 64/13) and from the capm shape. Magic + Netgen LVS accepted the wrong schematic value; only KLayout noticed.

The `res_diff` PCell names its types `res_nd_lvt`/`res_pd_lvt` where the models and symbols are `res_generic_nd`/`res_generic_pd`.

## The NPN layouts are off grid

The `npn_bjt` PCell draws the outer guard ring of all three NPNs off the 5 nm grid (`tap_OFFGRID`, `psdm_OFFGRID` at -6.666 / -6.517 um). The cells snap every layer to the grid after flattening.

## Diode area convention

`diode.sym` takes `area` and `perim` in the unit of its template, `area=1e12 perim=4e6` for a 1 x 1 um diode, which is also what Magic extracts. The cells follow it: `area=2.025e+11 perim=1.8e+06` for 0.45 x 0.45 um.

## The p_diode PCell

`p_diode` draws the P+ anode, an N+ cathode ring in the Nwell and an outer P+ substrate ring, with one PSDM rectangle over all three. PSDM over the N+ ring breaks `n/psd.8` ("Nsdm and psdm cannot overlap diff/tap regions of opposite doping"). Magic has no rule of that name, but reports errors at the ring that go away with the PSDM: `nsd.10b` and `psd.10b` (tap area) at pieces the size of one contact, `licon.7` and `difftap.11`. The outer ring has licons but no li1 over them (`licon.4`: a licon must overlap li1), and in `diode_pd2nw_11v0` it lies 0.37 um from the HV Nwell, where `hvdifftap.20` asks for 0.43 um.

The `sky130_diode_pd2nw_*` cells flatten the PCell, keep the anode and the cathode ring, draw PSDM around the anode only (0.125 um, `n/psd.5a`), and replace the outer ring by a 0.29 um ring with li1, 0.13 um from the Nwell (`difftap.11`), 0.43 um in `diode_pd2nw_11v0`, whose HVI is widened over it.

## Varactor

`gr = 1` of the `cap_var` PCell draws the substrate ring's tap and licons but no li1 over them (`licon.4`); the cells add li1 over the ring. The PCell's Nwell encloses the gate poly by 0.010 um at its ends, where `varac.5` asks for 0.15 um; the cells widen the Nwell to one rectangle that does. The ring tap is then 0.13 um from the Nwell, the minimum of `difftap.11`. The added li1 is drawn in the top cell, the ring is in the PCell, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for what Magic makes of that.

## 16 V MOS from the Magic generator

`nfet_g5v0d16v0` and `pfet_g5v0d16v0` have no KLayout PCell. The cells are drawn with `sky130::sky130_fd_pr__{n,p}fet_g5v0d16v0_draw` at the generator defaults (W = 5 um, L = 1.055 / 1.05 um, guard ring included). The generator labels S, G and B on li1 but not the drain; the cells add the D pin on the drain pad.

## Deep Nwell cells

`sky130_dnwell_nmos` and `sky130_dnwell_inv` follow `sg13_dnwell_nmos` and `sg13_dnwell_inv` and the gf180mcuD cells of the same name: an NMOS in the P-well inside a DNWELL (bulk on the source), and a PMOS/NMOS pair, pins D, S, G, VDD and VSS. The DNWELL edge is covered by an Nwell ring from 1.03 um inside (`nwell.6`) to 0.4 um outside, with an N+ tap ring on it (VDD), and a P+ substrate ring outside (VSS). The PMOS of the inverter sits in the left arm of the Nwell ring, so its bulk is the DNWELL.
