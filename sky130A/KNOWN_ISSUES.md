# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

Observed on the IIC-OSIC-TOOLS nightly image of 2026-10-22 (digest `sha256:4d34e47a6121`) with KLayout 0.30.12, Magic 8.3.685 and Netgen 1.5.325, PDK open_pdks `1689ac3`. Line numbers refer to the files of that PDK version: the Magic tech file `libs.tech/magic/sky130A.tech` and the KLayout decks `libs.tech/klayout/drc/sky130A_mr.drc` and `libs.tech/klayout/lvs/sky130.lvs`.

The LVS entries are for a `sak-lvs.sh` that fails Magic + Netgen LVS on property errors and passes `-rd convert_subckts=true -rd scale=true` to the KLayout deck (see [FINDINGS.md](FINDINGS.md), "KLayout LVS needs two deck switches for Xschem netlists"). With the `sak-lvs.sh` of the image above, every `klayout-lvs` step fails and the `sky130_combined:magic-lvs` entry is an `UNEXPECTED PASS`.

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

Magic DRC reports nine rule classes on the same layout, among them `MV Diffusion in N-well to P-tap spacing < 0.76um (diff/tap.20 + diff/tap.17,19)` 139 times, and transistor rules such as `MV NMOS minimum length < 0.5um (poly.13)` and `N-Diffusion overhang of nFET < 0.25um (poly.7)` at the poly over the diffusion of the device. KLayout DRC passes the cell. The device layers are those of `sky130_fd_pr__rf_npn_11v0_W1p00L1p00` in `libs.ref/sky130_fd_pr/gds/sky130_fd_pr.gds` (XOR empty on every device layer; the cell adds the outer guard ring of the PCell and the pins). Measured on the drawn geometry against the periphery rules of the SkyWater PDK documentation, one marker class is a real error of that layout: the DNWELL spans 0.40 to 9.35 um, and the Nwell reaches 0.4 um beyond it only on 1.08 um long pieces next to each corner. Along the rest of each side the Nwell edge is at 0.35 and 9.40 um, 0.05 um outside the DNWELL. `nwell.5` asks for 0.4 um, exempt only inside UHVI or `areaid.lw`, and the cell has neither. Magic reports it as `N-well overlap of Deep N-well < 0.4um outside, 1.03um inside (nwell.5a, 7)` 8 times; `sky130A_mr.drc` has no `nwell.5` check. The transistor markers come from Magic reading the poly ring over the base as an MV gate; the rules do not say whether transistor rules apply to it (only `poly.12` exempts a `gated_npn`). `diff/tap.20` is met: the collector tap ring in the Nwell is 0.765 um from the P tap ring (0.76 um). The step stays in `KNOWN_FAILS`: the cell is the PDK's own device, not broken on purpose.

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

## Full-RC PEX leaves device terminals unconnected

`KNOWN_FAILS` entries: `sky130_short1:magic-pex3`, `sky130_short1:klayout-pex3`, `sky130_photodiode:magic-pex3`, `sky130_photodiode:klayout-pex3`

Full-RC extraction (`magic-pex3`, and `klayout-pex3` with kpex driving Magic) loses the connection between a device terminal and its pin in two cells, while the C-coupled netlist (`magic-pex2`) has it:

- `sky130_short1`: the sources of both NMOS are nodes of their own, `X0 VDD VDD VDD.t10 VDD.t9 sky130_fd_pr__nfet_g5v0d10v5 ... as=0 ps=0` and `X1 VDD VDD VDD.t1 VDD.t0 sky130_fd_pr__nfet_01v8 ...`, and `VDD.t10` and `VDD.t1` appear in no other element. In the C-coupled netlist the sources are on `VDD`. The single `_tap` cells of the same transistors do not show it.
- `sky130_photodiode`: the anode of the extracted diode is the node `w_n338_n339#` (`D0 w_n338_n339# C ...`), which no resistor connects to the pin A; the C-coupled netlist has `D0 A C`.

Why is not known. A simulation of these netlists would leave the terminals floating. `scripts/check_pex_ports.py` passes them, since every port still reaches an element; `scripts/check_pex_modes.py` compares the device terminals with the C-coupled netlist and fails both steps. It finds no other cell here.

## Magic + Netgen LVS: `VM` of the varactors is compared

`KNOWN_FAILS` entry: `sky130_combined:magic-lvs`

The `cap_var_lvt` and `cap_var_hvt` symbols write `VM` into the SPICE netlist (`format=... W=@W L=@L VM=@VM m=@VM`), `XC2 net1 VDD VSS sky130_fd_pr__cap_var_lvt W=1 L=0.18 VM=1` in `sky130_combined`. Magic extracts `w` and `l` only. The netgen setup (`libs.tech/netgen/sky130A_setup.tcl`) handles the varactors together with the MOS devices (lines 173-195) and deletes `as ad ps pd mult sa sb sd nf nrd nrs area perim topography` for them, but not `vm`. The topology matches (`Final result: Circuits match uniquely.`), but Netgen reports `Property VM in circuit2 has no matching property in circuit1` and `Property errors were found.`, and `sak-lvs.sh` fails the step on that. With `vm` added to both delete lines the three varactor cells and `sky130_combined` match without property errors, and a doubled `W` or `m` is still reported (tested on a copy of the setup).

`sky130_cap_var_lvt`, `sky130_cap_var_hvt` and `sky130_cap_var_hvt_varac5` report the same line, but they fail `magic-lvs` on pin matching already, see "Magic does not combine the top cell with a PCell below it".

## KLayout LVS reads no area and perimeter from the diode symbol

`KNOWN_FAILS` entries: `sky130_diode_pd2nw_05v5:klayout-lvs`, `sky130_diode_pd2nw_05v5_lvt:klayout-lvs`, `sky130_diode_pd2nw_05v5_hvt:klayout-lvs`, `sky130_diode_pd2nw_05v5_psd8:klayout-lvs`, `sky130_diode_pd2nw_11v0:klayout-lvs`, `sky130_diode_pw2nd_05v5:klayout-lvs`, `sky130_diode_pw2nd_05v5_lvt:klayout-lvs`, `sky130_diode_pw2nd_05v5_nvt:klayout-lvs`, `sky130_diode_pw2nd_11v0:klayout-lvs`, and `sky130_combined:klayout-lvs` (with the two sections below)

The `diode.sym` symbol writes `XD1 A C sky130_fd_pr__diode_pd2nw_05v5 area=2.025e+11 perim=1.8e+06`. The deck's netlist reader knows the diode parameters only as `A` and `P` and reads the schematic diode with `A=0 P=0`; the extraction has `A=2.025e+11 P=1.8e+06`, and the comparison fails. With the CDL rewritten to `A=0.2025 P=1.8`, in micrometers as `scale=true` expects, all nine diode cells match; with `A=2.025e+11 P=1.8e+06` they still fail.

The deck also extracts `diode_pw2nd_05v5_lvt`, `_nvt` and `_11v0` reversed: their `tA` and `tC` terminal layers are swapped against `diode_pw2nd_05v5` (lines 2145-2157 of `sky130.lvs`), and the extracted line of `sky130_diode_pw2nd_05v5_lvt` reads `XD$1 C A`. In a cell with one diode this does not change the result, since the comparison is free to swap the two top-level pins.

## KLayout LVS: MIM capacitors and varactors do not match the schematic devices

`KNOWN_FAILS` entries: `sky130_cap_mim_m3_1:klayout-lvs`, `sky130_cap_mim_m3_2:klayout-lvs`, `sky130_cap_var_lvt:klayout-lvs`, `sky130_cap_var_hvt:klayout-lvs`, `sky130_cap_var_hvt_varac5:klayout-lvs`, `sky130_cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5:klayout-lvs`, `sky130_cap_vpp_11p5x11p7_m1m2_noshield:klayout-lvs`, `sky130_cap_vpp_08p6x07p8_m1m2_shieldl1:klayout-lvs`, `sky130_cap_vpp_04p4x04p6_m1m2_shieldl1:klayout-lvs`, and `sky130_combined:klayout-lvs`

- **MIM.** The deck extracts the two MIM options as `sky130_fd_pr__model__cap_mim` and `sky130_fd_pr__model__cap_mim_m4` (lines 2339-2346). The models and symbols are `sky130_fd_pr__cap_mim_m3_1` and `sky130_fd_pr__cap_mim_m3_2`, which are not in the deck's `DEVICE_LIST` (line 201) of subcircuits it reads as devices, so the schematic line `XC1 C0 C1 sky130_fd_pr__cap_mim_m3_1 W=2 L=2` stays a call of an empty subcircuit and the schematic has no device.
- **Varactors.** Both sides have the device with the same terminals, but the schematic one has no value: the CDL line `XC1 C0 C1 B sky130_fd_pr__cap_var_hvt W=1 L=0.18` becomes a device with `C=0 A=0 P=0`, the extraction has `A=1.8e+11 P=2.36e+06`.
- **VPP capacitors.** The CDL line carries no value (`XC1 C0 C1 B sky130_fd_pr__cap_vpp_04p4x04p6_m1m2_shieldl1`), the schematic device gets `C=0`, the extracted one `C=2e-16`. The deck extracts `cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5` with a four-terminal extractor (`VPP4Extractor`, line 2544), and the extracted device has a fourth terminal on a net of its own, against three terminals in the schematic.

## KLayout LVS joins the isolated P-well of `sky130_res_iso_pw` to the substrate

`KNOWN_FAILS` entry: `sky130_res_iso_pw:klayout-lvs`

`ptap_conn` (line 1158 of `sky130.lvs`) excludes taps in Nwell but not in DNWELL, and `connect_global(ptap_conn, substrate_name)` (line 1862) joins every P tap to the substrate. The two ends of the resistor sit on P taps inside DNWELL and are extracted as one net: `XR$1 R0|R1 R0|R1 B sky130_fd_pr__res_iso_pw`. The schematic resistor also has `R=0` against `R=30500` extracted; whether that alone fails the comparison is not tested. Magic extracts the isolation correctly, and `magic-lvs` passes.

The same short hits `sky130_dnwell_nmos` and `sky130_dnwell_inv`, where it does not change the result: their isolated P-well, the NMOS bulk and source, is extracted as one net with the substrate ring, `S,VSS`, and KLayout still reports a match. The schematic VSS pin connects to no device, so it has no partner in the comparison, and the layout net `S,VSS` is matched to the schematic net S. The layouts are right and the step passes, but on a shorted netlist.

## KLayout LVS stops on `sky130_npn_11v0_W1p00L1p00`

`KNOWN_FAILS` entry: `sky130_npn_11v0_W1p00L1p00:klayout-lvs`

The extraction of `sky130_fd_pr__npn_11v0_W1p00L1p00` (line 2115 of `sky130.lvs`) aborts on KLayout 0.30.12 with `'extract_devices': There are multiple conversion constructors available to convert object of type PolygonWithProperties to type Region for argument #1 ('other') in Region::&`. No netlist and no `.lvsdb` are written, and `sak-lvs.sh` exits with 5.

## KLayout LVS has no 16 V MOS

`KNOWN_FAILS` entries: `sky130_nfet_g5v0d16v0:klayout-lvs`, `sky130_pfet_g5v0d16v0:klayout-lvs`

The deck has no extraction for `nfet_g5v0d16v0` and `pfet_g5v0d16v0` (the names do not occur in `sky130.lvs`), and they are not in its `DEVICE_LIST`. Neither side has a device, the layout netlist has no circuit to compare, and the comparison fails.
