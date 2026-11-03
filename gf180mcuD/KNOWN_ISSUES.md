# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

Observed on the IIC-OSIC-TOOLS nightly image of 2026-10-22 (digest `sha256:4d34e47a6121`) with KLayout 0.30.12, Magic 8.3.685 and Netgen 1.5.325, PDK open_pdks `1689ac3`. Line numbers refer to the files of that PDK version: the Magic tech file `libs.tech/magic/gf180mcuD.tech` and the KLayout rule decks under `libs.tech/klayout/tech/`.

KLayout DRC passes on every cell that is not broken on purpose. Every `magic-drc` entry is a cell it passes and Magic does not.

## KLayout LVS fails on `gf180_nfet_03v3_tap_nostrap`

`KNOWN_FAILS` entry: `gf180_nfet_03v3_tap_nostrap:klayout-lvs`

The `Bulk Tie` option of the `gf180mcu` `nfet` PCell butts the P+ tie against the source. COMP is silicided, so source and bulk are one net, and the schematic says so (bulk tied to the source, pins D, S and G). The cell leaves out the Metal1 strap between the source contact and the tie contact that `gf180_nfet_03v3_tap` has, so the butted junction is the only connection.

Magic + Netgen LVS joins the two and passes. The KLayout deck does not: it derives `nsd` and `ptap` as separate layers and connects each of them only to `contact` (`rule_decks/general_connections.lvs`), never to each other. The extracted transistor then has its bulk on `SUB` instead of on the source, and the netlists do not match.

The cell exists to show this. Once the deck connects butted diffusions, the step passes and the entry has to go.

## Magic + Netgen LVS fails on `gf180_cap_pmos_03v3_b` and `gf180_cap_pmos_06v0_b`

`KNOWN_FAILS` entries: `gf180_cap_pmos_03v3_b:magic-lvs`, `gf180_cap_pmos_06v0_b:magic-lvs`

The p-type MOS varactor is a P+ gate area over a P+ substrate tap: the KLayout deck derives it as `pgate_lv_base.and(ptap)` (`rule_decks/moscap_derivations.lvs`), and Magic's own device line agrees, `device subcircuit cap_pmos_03v3_b pvaractor *ppdiff`, with the substrate diffusion `ppdiff` as its terminal.

Magic's GDS import does not produce that diffusion. The `import` style defines `pfetarea` as COMP and Poly2 without Nplus and then paints Nwell over it (`layer nwell pfetarea grow 310`, "Always force nwell under pfet"). The diffusion next to the gate therefore comes in as `pdiffc` (`mvpdiffc` at 6 V) instead of `psc`, the `pvaractor` has no `ppdiff` terminal, and the extracted subcircuit is empty. Netgen reports `has no elements and/or nodes. Not checked.`

KLayout LVS extracts both devices and passes.

## KLayout LVS fails on `gf180_cap_nmos_03v3_nofmt`

`KNOWN_FAILS` entry: `gf180_cap_nmos_03v3_nofmt:klayout-lvs`

The cell is `gf180_cap_nmos_03v3` without the `lvs_format` work-around on the instance (see [FINDINGS.md](FINDINGS.md), "Passive symbols and the KLayout deck"). The `gf180mcu_fd_pr` symbol then writes a subcircuit call into the CDL netlist:

```
XC1 C0 C1 cap_nmos_03v3 c_width=1u c_length=1u
```

The KLayout deck extracts the device as `C$1 C0 C1 4.4e-15 cap_nmos_03v3 A=1P P=4U` and reads schematic capacitors only as `C` elements with `W`/`L` (`SubcircuitModelsReader` in `rule_decks/custom_classes.lvs`), so the netlists do not match. Magic + Netgen LVS reads the SPICE netlist, which is the same with and without the work-around, and passes.

The cell exists to show this. Once the PDK symbols carry an `lvs_format`, or the deck reads the subcircuit form, the step passes and the entry has to go.

## Magic + Netgen LVS fails on `gf180_diode_nw2ps_03v3`, `gf180_diode_nw2ps_06v0`, `gf180_diode_dw2ps` and `gf180_diode_pw2dw`

`KNOWN_FAILS` entries: `gf180_diode_nw2ps_03v3:magic-lvs`, `gf180_diode_nw2ps_06v0:magic-lvs`, `gf180_diode_dw2ps:magic-lvs`, `gf180_diode_pw2dw:magic-lvs`

The extract section of the Magic tech file (`libs.tech/magic/gf180mcuD.tech`, lines 4174-4179) defines diodes only for `diode_pd2nw_03v3`, `diode_nd2ps_03v3`, `diode_pd2nw_06v0`, `diode_nd2ps_06v0`, `diode_nd2ps_06v0_nvt` and `sc_diode`. There is no device line for the Nwell-to-substrate diodes `diode_nw2ps_*` or for the deep Nwell diodes `diode_dw2ps` and `diode_pw2dw`. The extracted subcircuit is empty and Netgen reports `has no elements and/or nodes. Not checked.`

KLayout LVS extracts `diode_nw2ps_03v3`/`_06v0` and passes on those two cells.

## KLayout LVS fails on `gf180_diode_dw2ps` and `gf180_diode_pw2dw`

`KNOWN_FAILS` entries: `gf180_diode_dw2ps:klayout-lvs`, `gf180_diode_pw2dw:klayout-lvs`

The KLayout deck extracts these diodes under names with a voltage suffix, `diode_dw2ps_03v3`/`_06v0` and `diode_pw2dw_03v3`/`_06v0` (`rule_decks/diode_extraction.lvs`, lines 179, 187, 197 and 206). The ngspice models and the `gf180mcu_fd_pr` symbols have no suffix: `.model diode_dw2ps`, `.model diode_pw2dw`, `diode_dw2ps.sym`, `diode_pw2dw.sym`. The extracted device, for example `D$1 A C diode_dw2ps_03v3 A=3.23P P=7.2U`, matches the schematic device `D1 A C diode_dw2ps area='1.7u * 1.9u' ...` in terminals and area, but not in its device class, and LVS fails.

## Magic + Netgen LVS fails on `gf180_nplus_s`, `gf180_pplus_s` and `gf180_nwell`

`KNOWN_FAILS` entries: `gf180_nplus_s:magic-lvs`, `gf180_pplus_s:magic-lvs`, `gf180_nwell:magic-lvs`

The Magic tech file extracts these resistors from the tile types `rnds`, `rpds` and `rnw` (lines 4162, 4163 and 4166), but its GDS import (`cifinput` style `import`) has no rule that produces them: there is `layer ndiffres` and `layer pdiffres` for the salicide-blocked diffusion resistors (lines 1640 and 1801), but no `ndiffsilicide`, `pdiffsilicide` or `rnwell`. The resistor body imports as plain diffusion or Nwell, both ends end up on one net, the extracted cell has no device and one pin fewer, and Netgen reports `(no matching pin)` for `R0`.

KLayout LVS extracts all three and passes.

## Magic + Netgen LVS fails on `gf180_rm1`

`KNOWN_FAILS` entry: `gf180_rm1:magic-lvs`

The GDS layer map of the Magic tech file reads `Metal1_Res` (110/11) into the wrong CIF layer: `calma MET2RES 110 11` (line 2610), followed by `calma MET2RES 110 12`. `MET1RES` never gets any data, so `layer rm1 MET1 and RESDEF and MET1RES` (line 2308) is always empty and `layer m1 MET1,MET1TXT and-not MET1RES` keeps the whole resistor as Metal1. The two ends are one net and Netgen reports `(no matching pin)` for `R0`. Magic's own GDS output writes `rm1` as 110/11 (`layer MET1RES rm1`, `calma 110 11`, line 1134), so a layout written by Magic does not survive a round trip either. With line 2610 changed to `calma MET1RES 110 11` in a copy of the tech file, the resistor body of this cell imports as `rmetal1` instead of `metal1`.

`gf180_rm2` and `gf180_rm3` pass. KLayout LVS passes on all three.

## Magic + Netgen LVS fails on `gf180_pnp_05p00x00p42`, `gf180_pnp_05p00x05p00` and `gf180_pnp_10p00x10p00`

`KNOWN_FAILS` entries: `gf180_pnp_05p00x00p42:magic-lvs`, `gf180_pnp_05p00x05p00:magic-lvs`, `gf180_pnp_10p00x10p00:magic-lvs`

The Magic tech file tells the four vertical PNPs apart by the area of their second terminal (lines 4135-4138):

```
device msubcircuit pnp_10p00x00p42 pnp pwell,space/w *pdiff error a2>4.1 a2<4.3
device msubcircuit pnp_05p00x00p42 pnp pwell,space/w *pdiff error a2>2.0 a2<2.2
device msubcircuit pnp_10p00x10p00 pnp pwell,space/w *pdiff error a2>99.0 a2<101.0
device msubcircuit pnp_05p00x05p00 pnp pwell,space/w *pdiff error a2>24.0 a2<26.0
```

After the GDS import that terminal has zero area and perimeter: the `.ext` record of every PNP reads `device msubckt pnp_10p00x00p42 ... "w_160_160#" 0 0 "a_44_44#" 0 0`, while the NPNs carry their emitter area (`"a_1320_1320#" 0 1000000,4000` for `npn_05p00x05p00`). No `a2` condition holds, and Magic falls back to the first line. Every PNP is extracted as `pnp_10p00x00p42`, and Netgen reports a device mismatch.

`gf180_pnp_10p00x00p42` passes only because it is the first line. KLayout LVS passes on all four.

## KLayout LVS, Magic + Netgen LVS and Magic DRC fail on `gf180_sc_diode`

`KNOWN_FAILS` entries: `gf180_sc_diode:klayout-lvs`, `gf180_sc_diode:magic-lvs`, `gf180_sc_diode:magic-drc`

The cell is kept as a finding: the `gf180mcu` `sc_diode` PCell, the KLayout deck and Magic disagree on what the Schottky diode is. The PCell draws the anode, 0.62 x 1.0 um of COMP without implant, between two N+ cathode stripes with a 0.28 um gap on each side, all under the Schottky marker (241/0) in DNWELL. The schematic follows that geometry: one `sc_diode` with the anode area, `r_w=0.62u r_l=1u`.

- **KLayout** (`rule_decks/diode_extraction.lvs`, lines 209-224) takes the marker as the P terminal and each cathode stripe as an N terminal and extracts two diodes, `D$1 A C sc_diode A=0.36P P=2.72U` and `D$2` alike: the areas are those of the cathode stripes, and `combine` is off.
- **Magic** builds `schottky` as `SCHOTTKY and DIFF` without implants, then `grow 140` / `shrink 140` (`libs.tech/magic/gf180mcuD.tech`, line 1598), which closes exactly the 0.28 um gaps. It extracts three diodes: `D0 A C sc_diode area=0.18p` and two more, `area=0.28p` each, whose anodes are the gaps, on nets of their own.

The PDK has neither a Magic generator nor an LVS test case for this device.

KLayout DRC passes the cell, Magic DRC does not. It reports `Both LV and MV devices cannot be in the same deep N-well (DN.11)` over the whole DNWELL, although the cell has one device and no Dualgate, and `Diffusion spacing < 0.28um (DF.3a)` in a band 0.10 um wide at x = 1.04 to 1.14 um. That band lies inside the anode COMP (x = 0.64 to 1.26 um), where the layout has no diffusion edge. Why Magic reports either is not known.

## KLayout LVS does not extract a bipolar transistor under a MIM capacitor

`KNOWN_FAILS` entry: `gf180_combined_cmim_ontop:klayout-lvs`

`gf180_combined_cmim_ontop` is `gf180_combined` with its 46 x 46 um MIM capacitor over all devices instead of beside them, one of them the NPN of `gf180_npn_00p54x02p00`. The KLayout deck takes every BJT under the top plate of MIM option B (`FuseTop`, 75/0) out of the extraction: `bjt_exclude = dualgate.join(poly2).join(resistor).join(esd).join(sab).join(fusetop)` (`lvs/rule_decks/bjt_derivations.lvs`, lines 30-31), and emitter, base and collector are derived `.not(npn_exclude)` (lines 42-44, the PNP layers `.not(pnp_exclude)` at lines 82-84). The extracted netlist has 15 of the 16 devices, the NPN is missing. A 20 x 20 um MIM over `gf180_npn_00p54x02p00`, `gf180_npn_05p00x05p00` or `gf180_pnp_10p00x00p42` alone drops the BJT in the same way (tested in cells outside the regression).

KLayout DRC has no rule against a BJT under a MIM capacitor and passes the cell. Magic + Netgen LVS extracts all 16 devices and passes. `gf180_combined`, with the same schematic and the MIM beside the devices, passes KLayout LVS.

## Magic DRC measures PP.8a and NP.8a on an implant of its own

`KNOWN_FAILS` entries: `gf180_cap_nmos_03v3:magic-drc`, `gf180_cap_nmos_03v3_nofmt:magic-drc`, `gf180_cap_nmos_06v0:magic-drc`, `gf180_cap_pmos_03v3:magic-drc`, `gf180_cap_pmos_06v0:magic-drc`, `gf180_diode_dw2ps:magic-drc`, `gf180_diode_pw2dw:magic-drc`, `gf180_nfet_03v3_mintap:magic-drc`, and `gf180_dnwell_inv:magic-drc` (together with the contact issue below)

Magic reports `Minimum PPLUS area >= 0.35um^2 (PP.8a)` or `Minimum NPLUS area >= 0.35um^2 (NP.8a)` at small taps. It does not check the drawn Nplus and Pplus. Its DRC rebuilds the implant from the diffusion types (`templayer check_pplus` and `check_nplus` in `style drc` of the cifoutput section, lines 1407-1419): device diffusion grows by 0.16 um, tap diffusion (`psd`, `nsd`) by only 0.02 um (`bloat-or *psd,*mvpsd * 20`). Then it checks the area (`cifarea check_pplus 350000`, lines 2811-2812). A 0.46 um tap thus counts as a 0.50 um square, 0.25 um^2. The drawn implant of every reported tap has 0.60 to 0.76 um^2. KLayout DRC checks PP.8a and NP.8a on the drawn layers and reports nothing.

`gf180_nfet_03v3_mintap` shows it on its own: the NMOS of `gf180_nfet_03v3_ring` with a single tap as B instead of the guard ring, as small as the rules allow, 0.46 um of COMP (`DF.9`) in a 0.78 um square of Pplus (0.61 um^2).

## Magic DRC merges contacts up to 0.29 um apart

`KNOWN_FAILS` entries: `gf180_dnwell_nmos:magic-drc`, `gf180_dnwell_inv:magic-drc`, `gf180_nfet_03v3_ring_cogap:magic-drc`

Magic reports `Diffusion contact width < 0.23um (CO.1 + 2 * CO.6)` at the corners of guard rings. Its GDS import builds the diffusion contact types from the contact cuts with `grow 145` and `shrink 140` (`nsc` at lines 2108-2116, `psc` alike), which merges cuts up to 0.29 um apart into one shape. Where the cuts of a ring column and a ring row sit offset at a corner, the merged shape has notches narrower than 0.23 um, and Magic reports them as contact width. The GF180MCU rule CO.2a asks for 0.25 um between contacts.

`gf180_nfet_03v3_ring_cogap` is `gf180_nfet_03v3_ring` with the end contacts of both side columns moved to 0.29 um from the corner contacts of the top and bottom rows; Magic reports 15 markers. With the end contacts 0.29 um from the corners, every ring type tested fails Magic DRC (the inner and the outer ring of the deep Nwell cells, the rings of `gf180_nfet_03v3_ring` and `gf180_pfet_03v3_ring`); at 0.30 or 0.37 um, or without the end contacts, none does. KLayout DRC passes all of them.

## Magic DRC reports DF.8 at every NPN

`KNOWN_FAILS` entries: `gf180_npn_00p54x02p00:magic-drc`, `gf180_npn_00p54x04p00:magic-drc`, `gf180_npn_00p54x08p00:magic-drc`, `gf180_npn_00p54x16p00:magic-drc`, `gf180_npn_05p00x05p00:magic-drc`, `gf180_npn_10p00x10p00:magic-drc`

The NPN cells are the fixed layouts of the PDK. Magic reports `P-well must surround N-diffusion inside deep N-well by 0.43um (DF.8)` once in each (`cifmaxwidth ndiff_missing_pwell 0`, lines 2806-2807). In every one of them the emitter lies 0.90 um inside the LVPWELL, more than the 0.43 um (3.3 V) or 0.60 um (5/6 V) the rule asks for. KLayout DRC passes all six. Why Magic misses the LVPWELL is not known.

## Magic DRC reports the PNP diffusions outside an Nwell

`KNOWN_FAILS` entries: `gf180_pnp_05p00x00p42:magic-drc`, `gf180_pnp_05p00x05p00:magic-drc`, `gf180_pnp_10p00x00p42:magic-drc`, `gf180_pnp_10p00x10p00:magic-drc`

The PNP cells are the fixed layouts of the PDK. Magic reports `P-diffusion and N-ohmic must be over N-well or deep N-well` five times in each (`cifmaxwidth missing_nwell 0`, lines 2799-2800). In all four the P+ emitter and the N+ base ring lie entirely inside the NWELL. KLayout DRC passes them. Why Magic does not see the NWELL there is not known.

## Magic DRC reports errors in some PCells only below the top cell

`KNOWN_FAILS` entries: `gf180_combined:magic-drc`, `gf180_combined_cmim_ontop:magic-drc` (both cells also contain an NPN, a deep Nwell cell and a MOS capacitor of the sections above)

Not classified yet. The combined cells place single cells of this directory as instances, so their PCells sit two levels below the top cell. There Magic reports errors that it does not report on the single cell, where the PCell is a direct child of the top cell:

| PCell | Magic DRC markers in the combined cells |
| --- | --- |
| `diode_nd2ps_03v3` | `CO.4` 8, `PP.8a` 3, `P-diffusion and N-ohmic must be over N-well or deep N-well` 1 |
| `diode_pd2nw_03v3` | `NP.8a` 3 |
| `npolyf_u`, `ppolyf_u` | `PP.8a` 3 each |
| `ppolyf_u_1k` | `PRES/LRES/HRES.7` 2 |
| `cap_nmos_03v3` | `CO.1 + 2 * CO.6` 2 |
| `dnwell_nmos` | `CO.1 + 2 * CO.6` 5 more than in the single cell |

The single cell is the odd case: the PCell loaded on its own as the top cell gets the same markers (12 for `diode_nd2ps_03v3`), and so do the single cell placed one level deeper and a copy flattened with KLayout, all without any wiring. A synthetic Metal1 width error is reported at every depth, so Magic does check the lower levels. KLayout DRC passes all of these. Whether the markers are real errors is open. If they are, Magic DRC passes the single cells falsely; the implant markers may be the issue of the PP.8a/NP.8a section above, which measuring the drawn implant would settle.

## Magic full-RC PEX keeps the second pin of a resistor it does not extract

`KNOWN_FAILS` entries: `gf180_nplus_s:magic-pex3`, `gf180_nplus_s:klayout-pex3`, `gf180_pplus_s:magic-pex3`, `gf180_pplus_s:klayout-pex3`, `gf180_nwell:magic-pex3`, `gf180_nwell:klayout-pex3`, `gf180_rm1:magic-pex3`, `gf180_rm1:klayout-pex3`

These are the four resistors Magic does not extract (see the Magic + Netgen LVS sections above): the body imports as plain diffusion, Nwell or Metal1, so both ends are one net that carries the pin names R0 and R1. `magic-pex1`, `magic-pex2` and `klayout-pex2` keep one name, their netlist starts with `.subckt gf180_nplus_s_pex B R1`. Full-RC extraction (`magic-pex3`) lists `B R0 R1` with nothing on R0, and `scripts/check_pex_ports.py` fails the step on the dangling port. `klayout-pex3`, kpex driving Magic in RC mode, writes the same header. It is the issue of `sg13_lv_nmos_tap_short_ds` in [../ihp-sg13g2/KNOWN_ISSUES.md](../ihp-sg13g2/KNOWN_ISSUES.md), and the entries go once Magic extracts these resistors.

## Magic full-RC PEX joins a P-well inside a deep Nwell to the substrate

`KNOWN_FAILS` entries: `gf180_dnwell_nmos:magic-pex3`, `gf180_dnwell_nmos:klayout-pex3`, `gf180_dnwell_inv:magic-pex3`, `gf180_dnwell_inv:klayout-pex3`, `gf180_npn_00p54x02p00:magic-pex3`, `gf180_npn_00p54x02p00:klayout-pex3`, `gf180_npn_00p54x08p00:magic-pex3`, `gf180_npn_00p54x08p00:klayout-pex3`, `gf180_npn_00p54x16p00:magic-pex3`, `gf180_npn_00p54x16p00:klayout-pex3`, `gf180_npn_05p00x05p00:magic-pex3`, `gf180_npn_05p00x05p00:klayout-pex3`

In these cells a P-well lies isolated inside a DNWELL: the LVPWELL of the NMOS in the `gf180_dnwell_*` cells, tied to its source S, and the base of the NPN. `magic-pex2` keeps it on its own net, `X0 S G D S nfet_03v3` in `gf180_dnwell_nmos` and `X0 C B E S npn_00p54x02p00`. Full-RC extraction (`magic-pex3`) joins it to the substrate: `X0 VSS G D VSS nfet_03v3`, and `X0 C S E VSUBS npn_00p54x02p00`, with the base on the substrate pin S and the substrate terminal on `VSUBS`, which is no port. The pin of the isolated net (S or B) is left without an element, and `scripts/check_pex_ports.py` fails the step. `klayout-pex3` writes the same netlists. The result is the same in three runs.

`gf180_npn_00p54x04p00` and `gf180_npn_10p00x10p00` get the same short and still pass: there the full-RC netlist keeps resistor fragments between B and S (`X0 C B E VSUBS npn_00p54x04p00` and `R0 B S 1.97113`), so every port has an element and the port check has nothing to report. The two cells have no entry, since the step passes; see [FINDINGS.md](FINDINGS.md).

## Magic DRC does not check NAT.6

`KNOWN_FALSE_PASSES` entry: `gf180_nfet_06v0_nvt_ring_nat:magic-drc`

NAT.6 is "Two or more COMPs if connected to different potential are not allowed under same NAT layer". Magic keeps no NAT layer of its own: its GDS import reads NAT only to tell native transistors and diodes from regular ones (`and NAT` and `and-not NAT` in the `layer` rules of the import style), so it cannot see which COMPs share one NAT shape. Its NAT rules are a spacing from native diffusion to a tap (line 2822, labelled `NAT.5 + NAT.6`) and the poly overhang of a native transistor (line 2852). `gf180_nfet_06v0_nvt_ring_nat` has NAT over its guard ring (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)): KLayout reports `NAT.6` twice, Magic nothing.

## Neither DRC checks MIMTM.10 outside the top plate

`KNOWN_FALSE_PASSES` entries: `gf180_cap_mim_2f0fF_via3:klayout-drc`, `gf180_cap_mim_2f0fF_via3:magic-drc`

MIMTM.10 reads "(a) There cannot be any Vian-2 touching MIM bottom plate Metaln-1. (b) MIM bottom plate Metaln-1 can only be connected through the higher Via (Vian-1)." For MIM option B on Metal5 the bottom plate is Metal4, Vian-2 is Via3 and Vian-1 is Via4. Both tools check the rule only at the top plate:

- KLayout: `topmin1_via.and(topmin1_metal.and(fusetop))` (`drc/rule_decks/mim_b.rb`, line 122), a Via3 inside the top plate (`FuseTop`).
- Magic: `spacing via3 *mimcap 50 touching_illegal` (lines 3191-3192), a Via3 within 0.05 um of the capacitor.

`gf180_cap_mim_2f0fF_via3` connects the bottom plate from a Metal4 tab through a Via3 1.5 um outside the top plate, down to a Metal3 pin (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)). Both DRC steps pass it. The checks themselves work: with the Via3 under the top plate, KLayout reports `MIMTM.10` once and Magic `MIMTM.10` eight times; the same tab with a Via4 up to Metal5 passes every step (both tested in cells outside the regression).

## Not caught: Magic + Netgen LVS passes the small diodes with the wrong area

No list entry. At the PCell default `wa = la = 0.36` the `gf180mcu` diode PCells draw the diode COMP 0.36 x 0.565 um (see [FINDINGS.md](FINDINGS.md)). In `gf180_diode_nd2ps_03v3`, `gf180_diode_nd2ps_06v0`, `gf180_diode_pd2nw_03v3` and `gf180_diode_pd2nw_06v0` both extractors read `A=0.2034P P=1.85U`, while the schematic has `area='0.36u * 0.36u '`, 0.1296 um^2. Netgen reports `area circuit1: 2.034e-13   circuit2: 1.296e-13   (delta=44.3%, cutoff=2%)` and `Property errors were found.`, and still ends with `Circuits match uniquely`, which is all `sak-lvs.sh` checks (see `sg13_lv_nmos_tap_w_mismatch` in [../ihp-sg13g2/KNOWN_ISSUES.md](../ihp-sg13g2/KNOWN_ISSUES.md)). The KLayout deck does not compare the diode area. Both LVS steps pass, so a `KNOWN_FAILS` entry would be an `UNEXPECTED PASS`. Once `sak-lvs.sh` fails on property errors, `magic-lvs` fails on these four cells, and they need an entry or a schematic with the drawn area.
