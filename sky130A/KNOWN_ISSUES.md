# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

Observed on the IIC-OSIC-TOOLS nightly image of 2026-10-22 (digest `sha256:4d34e47a6121`) with KLayout 0.30.12, Magic 8.3.685 and Netgen 1.5.325, PDK open_pdks `1689ac3`. Line numbers refer to the files of that PDK version: the Magic tech file `libs.tech/magic/sky130A.tech` and the KLayout decks `libs.tech/klayout/drc/sky130A_mr.drc` and `libs.tech/klayout/lvs/sky130.lvs`.

KLayout LVS is not among the regression steps of this directory: it needs two deck switches that `sak-lvs.sh` does not pass, see [FINDINGS.md](FINDINGS.md) ("KLayout LVS needs two deck switches for Xschem netlists"), which also lists what the deck finds with both switches set.

## Magic + Netgen LVS and Magic DRC fail on `sky130_diode_pd2nw_05v5_lvt` and `sky130_diode_pd2nw_05v5_hvt`

`KNOWN_FAILS` entries: `sky130_diode_pd2nw_05v5_lvt:magic-lvs`, `sky130_diode_pd2nw_05v5_hvt:magic-lvs`, `sky130_diode_pd2nw_05v5_lvt:magic-drc`, `sky130_diode_pd2nw_05v5_hvt:magic-drc`

Magic extracts two diodes from the one low- or high-Vt diode: `sky130_fd_pr__diode_pd2nw_05v5_lvt` with 0.1736 um^2 and a regular `sky130_fd_pr__diode_pd2nw_05v5` with 0.0289 um^2, which is exactly the 0.17 x 0.17 um contact in its middle. Netgen reports one device too many. Magic DRC reports `P-diode overlap of N-diode contact < 0.04um (licon.5a)` eight times around the same contact, which the diffusion encloses by 0.14 um.

The GDS import first builds the right contact type (`layer pdilvtc pdilvtcbase`, line 3311), but later paints it over: `templayer pdiccopy` (lines 3724-3729) selects every diode contact on P+ diffusion outside HVI, without excluding LVTN or HVTP, and `layer pdic pdiccopy` turns it into a plain `pdic`. With `and-not LVTN` and `and-not HVTP` added to `pdiccopy` in a copy of the tech file, Magic extracts one `diode_pd2nw_05v5_lvt` with the full 0.2025 um^2, and its DRC reports nothing on either cell.

## Magic + Netgen LVS and Magic DRC fail on `sky130_npn_11v0_W1p00L1p00`

`KNOWN_FAILS` entries: `sky130_npn_11v0_W1p00L1p00:magic-lvs`, `sky130_npn_11v0_W1p00L1p00:magic-drc`

The cell is the fixed layout of the PDK, drawn by the `npn_bjt` PCell. The Magic tech file selects this transistor by its emitter area (lines 5983-5984):

```
device msubcircuit sky130_fd_pr__npn_11v0_W1p00L1p00 npn *mvndiff \
	dnwell space/w error a1>0.99 a1<1.01
```

Magic extracts the emitter of the fixed layout with an area of 1.9724 um^2, so the condition never holds and Magic falls back to the generic line before it, `sky130_fd_pr__npn_11v0 ... a1=area` (line 5982). There is no `sky130_fd_pr__npn_11v0` model, only `sky130_fd_pr__npn_11v0_W1p00L1p00`, and Netgen reports a device mismatch.

Magic DRC reports nine rule classes on the same layout, among them `MV Diffusion in N-well to P-tap spacing < 0.76um (diff/tap.20 + diff/tap.17,19)` 139 times, and transistor rules such as `MV NMOS minimum length < 0.5um (poly.13)` and `N-Diffusion overhang of nFET < 0.25um (poly.7)` at the poly over the diffusion of the device. KLayout DRC passes the cell. Which of the markers are real is not known; the layout is the PDK's own.

## Magic + Netgen LVS fails on the four `sky130_cap_vpp_*` cells

`KNOWN_FAILS` entries: `sky130_cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5:magic-lvs`, `sky130_cap_vpp_11p5x11p7_m1m2_noshield:magic-lvs`, `sky130_cap_vpp_08p6x07p8_m1m2_shieldl1:magic-lvs`, `sky130_cap_vpp_04p4x04p6_m1m2_shieldl1:magic-lvs`

The Magic tech file has no device line for the VPP (MOM) capacitors: it mentions `sky130_fd_pr__cap_vpp_*` only in a comment (line 107), so Magic cannot extract the capacitor from its geometry. The extracted cell has its pins and no device, and Netgen reports `has no elements and/or nodes. Not checked.` A layout drawn with Magic's own generator (`sky130::sky130_fd_pr__cap_vpp_*_draw`), which places the fixed cell of `libs.ref` as a named subcell, does not get further through `sak-lvs.sh`, which flattens the layout first: the extraction then writes no subcircuit at all.

This is the same situation as `sg13_cmomi:magic-lvs` in ihp-sg13g2.

## KLayout DRC, Magic DRC and Magic + Netgen LVS fail on `sky130_photodiode`

`KNOWN_FAILS` entries: `sky130_photodiode:klayout-drc`, `sky130_photodiode:magic-drc`, `sky130_photodiode:magic-lvs`

The cell is the PDK's own fixed photodiode, placed by the `photodiode` PCell: a 3 x 3 um DNWELL under the photo marker `areaid.po` (81/81) with the cathode tap in its middle, an N+ ring on a DNWELL ring around it, and the P+ substrate ring as the anode.

**KLayout DRC.** `sky130A_mr.drc` checks the 6.3 um DNWELL spacing `dnwell.2` on `dnwell.not(uhvi.or(vhvi))` (lines 293-296). The photodiode DNWELL sits 5.3 um from the ring and is reported four times. The older deck in the same directory, `sky130A.lydrc`, exempts it (`dnwell.not(uhvi).not(areaid_po)`, line 206) and checks it with its own rule instead, `photo.4 : mini. photodiode spacing to dnwell : 5.3um` (line 332), which the cell meets; `sky130A_mr.drc` has no `photo.*` rule at all.

**Magic DRC.** Magic reports `N-well overlap of Deep N-well < 0.4um outside, 1.03um inside (nwell.5a, 7)` four times, at the 3 x 3 um photodiode DNWELL. The layout of the PDK has no Nwell ring around it but a 0.84 um Nwell inside it, 1.08 um from each edge, as the `photo.8` and `photo.9` rules ask. KLayout DRC does not report it.

**Magic + Netgen LVS.** The Magic tech file imports the device region as type `photo` (`layer photo DNWELL` and `and PHOTO`, lines 2420-2421) but has no device line for `sky130_fd_pr__photodiode`. What it extracts instead is the parasitic diode of the DNWELL to the substrate, `D0 A C sky130_fd_pr__model__parasitic__diode_ps2dn area=9`, and Netgen reports a device mismatch.

## Magic full-RC extraction crashes on `sky130_pnp_05v5_W3p40L3p40`

`KNOWN_FAILS` entries: `sky130_pnp_05v5_W3p40L3p40:magic-pex3`, `sky130_pnp_05v5_W3p40L3p40:klayout-pex3`

`make magic-pex EXT_MODE=3` on the PDK's fixed 3.4 x 3.4 um PNP ends in a segmentation fault of Magic during the resistance extraction (`Processing cell sky130_pnp_05v5_W3p40L3p40_pex for resistance extraction.`, `Extracting C`, `Segmentation fault (core dumped)`), and no netlist is written. `klayout-pex3`, kpex driving Magic in RC mode, fails the same way: `MAGIC failed with status code -11`. The C-decoupled and C-coupled extractions pass, and so does the full-RC extraction of the 0.68 x 0.68 um PNP.

## Magic does not combine the top cell with a PCell below it

`KNOWN_FAILS` entries: `sky130_pfet_01v8_ring_pcell:magic-drc`, `sky130_pfet_01v8_ring_pcell:magic-lvs`, `sky130_pfet_01v8_lvt_ring_pcell:magic-drc`, `sky130_pfet_01v8_lvt_ring_pcell:magic-lvs`, `sky130_pfet_01v8_hvt_ring_pcell:magic-drc`, `sky130_pfet_01v8_hvt_ring_pcell:magic-lvs`, `sky130_pfet_g5v0d10v5_ring_pcell:magic-drc`, `sky130_pfet_g5v0d10v5_ring_pcell:magic-lvs`, `sky130_cap_var_lvt:magic-lvs`, `sky130_cap_var_hvt:magic-lvs`, `sky130_cap_var_hvt_varac5:magic-lvs`

Magic applies the rules of its GDS import within each cell. In these cells a ring is drawn by a PCell and completed in the top cell, see [FINDINGS.md](FINDINGS.md): in the PMOS `_ring_pcell` cells the N+ ring of `guard_ring_gen` gets its Nwell (and HVI) in the top cell, in the varactors the substrate ring of `cap_var` gets the li1 over its licons. GDS merges layers across the hierarchy, and KLayout DRC passes the cells; Magic does not combine them.

- **PMOS `_ring_pcell`.** Magic DRC reports `Can't overlap those layers` 4 times, `nwell.4` 5 times and `LU.3` twice, for `pfet_g5v0d10v5` also `diff/tap.18,20` 4 times and `nwell.8` 16 times. Magic + Netgen LVS finds no connection between the ring and the well: the extracted netlist has the node `w_n61_n76#` without a pin, the schematic pin B has no match, and Netgen ends with `Top level cell failed pin matching.`
- **Varactors.** Magic DRC passes. Magic + Netgen LVS fails in the same way on B: the li1 ring with the pin is not connected to the substrate ring below it.

`sak-lvs.sh` flattens the layout with Magic's `flatten` after `gds read`, which is too late. The same layouts flattened with KLayout pass Magic DRC and Magic + Netgen LVS (tested on `sky130_pfet_01v8_ring_pcell` and `sky130_cap_var_lvt` outside the regression).

## Magic DRC checks RPM on a layer of its own

`KNOWN_FAILS` entries: `sky130_res_high_po_0p35:magic-drc`, `sky130_res_high_po_0p69:magic-drc`, `sky130_res_xhigh_po_0p35:magic-drc`, `sky130_res_xhigh_po_0p69:magic-drc`, and `sky130_combined:magic-drc` (which contains `sky130_res_high_po_0p35` and `sky130_res_xhigh_po_0p35`, two markers)

Magic reports `Width of RPM/URPM < 1.27um (rpm.1)` once on each of the 0.35 um and 0.69 um wide poly resistors. Their RPM (or URPM) is drawn 1.270 um wide, the minimum of `rpm.1a`, and KLayout DRC passes them. Magic does not check the drawn layer: it rebuilds RPM from the resistor (`templayer rpm_generate`: `bloat-all xhrpoly,uhrpoly xpc`, `grow 620`, `shrink 420`, lines 1744-1750) and checks the width of that (`cifwidth rpm_generate 1270`, line 4427). For these two widths the rebuilt layer is narrower than 1.27 um.

Magic's own generator draws the same resistor with an RPM of only 0.75 um: `sky130::sky130_fd_pr__res_high_po_0p35` at its defaults writes RPM from 0.365 to 1.115 um around a 0.35 um resistor. Magic DRC passes that layout, and KLayout DRC reports `rpm.1a` on it (tested outside the regression).

## Magic DRC reports nwell.8 on its own 16 V PMOS

`KNOWN_FAILS` entry: `sky130_pfet_g5v0d16v0:magic-drc`

The cell is drawn by Magic's own generator, `sky130::sky130_fd_pr__pfet_g5v0d16v0_draw`, at its defaults (see [FINDINGS.md](FINDINGS.md)). Magic DRC reports `Spacing of HV nwell to HV nwell < 2.0um (nwell.8)` twice. The layout has one Nwell, a single polygon with a 2.57 um wide hole for the drain, so there is no second Nwell to keep 2 um from; `hvnwell.8` asks for 2 um between nwells on different nets. KLayout DRC passes the cell. Why Magic reports it is not known.

## KLayout DRC misses the deliberate errors of four cells

`KNOWN_FALSE_PASSES` entries: `sky130_nfet_05v0_nvt_tap_hvdifftap16:klayout-drc`, `sky130_diode_pd2nw_05v5_psd8:klayout-drc`, `sky130_cap_var_hvt_varac5:klayout-drc`, `sky130_nfet_01v8_tap_licon15:klayout-drc`

`sky130A_mr.drc` has no check for `hvdifftap.16`, `n/psd.8`, `varac.5` and `licon.15`, so KLayout DRC passes the four cells of [EXPECTED_FAILS.md](EXPECTED_FAILS.md) that break them. [FINDINGS.md](FINDINGS.md) ("The KLayout DRC deck misses rules") lists the other periphery rules the deck does not check.

## Magic DRC does not check varac.5 on the high-Vt varactor

`KNOWN_FALSE_PASSES` entry: `sky130_cap_var_hvt_varac5:magic-drc`

Magic checks `varac.5` on the layer `var_poly_no_nwell`, which it builds from `varactor,mvvaractor` only (lines 1506-1509), and reports `N-well overlap of varactor poly < 0.15um (varac.5)` where that layer is not empty (`cifmaxwidth var_poly_no_nwell 0`, line 4880). The high-Vt varactor is a type of its own, `varhvt` (line 174), and is not among them. `sky130_cap_var_hvt_varac5` encloses the gate poly by 0.010 um and passes Magic DRC; the same error in `sky130_cap_var_lvt`, before that cell was repaired, was reported twice.

## Magic DRC does not check NPC

`KNOWN_FALSE_PASSES` entry: `sky130_nfet_01v8_tap_licon15:magic-drc`

Magic's GDS import ignores the drawn NPC (`ignore NPC`, line 2356), and Magic writes NPC itself, 0.1 um around every poly contact, when it writes GDS (lines 1126-1135). It has no rule on NPC, so it cannot report the 0.06 um NPC of `sky130_nfet_01v8_tap_licon15` (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)).

## Not caught: full-RC PEX leaves device terminals unconnected

No list entry: the steps pass. Full-RC extraction (`magic-pex3`, and `klayout-pex3` with kpex driving Magic) loses the connection between a device terminal and its pin in two cells, while the C-coupled netlist (`magic-pex2`) has it:

- `sky130_short1`: the sources of both NMOS are nodes of their own, `X0 VDD VDD VDD.t10 VDD.t9 sky130_fd_pr__nfet_g5v0d10v5 ... as=0 ps=0` and `X1 VDD VDD VDD.t1 VDD.t0 sky130_fd_pr__nfet_01v8 ...`, and `VDD.t10` and `VDD.t1` appear in no other element. In the C-coupled netlist the sources are on `VDD`. The single `_tap` cells of the same transistors do not show it.
- `sky130_photodiode`: the anode of the extracted diode is the node `w_n338_n339#` (`D0 w_n338_n339# C ...`), which no resistor connects to the pin A; the C-coupled netlist has `D0 A C`.

Why is not known. `scripts/check_pex_ports.py` checks that every port reaches an element, which still holds, so the steps pass; a simulation of these netlists would leave the terminals floating. Comparing the device terminals of the full-RC netlist with the C-coupled one finds both cells, and no other cell that has a full-RC netlist.
