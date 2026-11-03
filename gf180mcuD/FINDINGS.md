# Findings and work-arounds for the gf180mcuD PDK

Things in this PDK that are easy to get wrong and frustrating to troubleshoot. The layouts in this directory are built from the KLayout PCells of the PDK, observed with KLayout 0.30.12 and Magic 8.3.683 to 8.3.685 (IIC-OSIC-TOOLS 2026.09 and the nightly image of 2026-10-22).

## Two PCell libraries, neither complete

The PDK registers two KLayout libraries with the same device names: `gf180mcu` (gdsfactory based) and `gf180mcu_klayoutapi` (plain KLayout API). They draw different geometry for the same parameters.

| | `gf180mcu` | `gf180mcu_klayoutapi` |
|---|---|---|
| Gate contact | yes | none, the gate is bare Poly2 |
| `Bulk Tie` | butted against the source (see below) | separate tie, but off-grid (12 `OFFGRID` errors on COMP, Metal1 and Pplus) |
| `Guard Ring` | broken, see below | DRC clean |

The MOS cells here use `gf180mcu`, since a gate pin needs Metal1 (see "Pins on Poly2").

## Bulk Tie shorts source and bulk

The `Bulk Tie` of the `gf180mcu` `nfet`/`pfet` PCells is butted against the source: one COMP shape, half N+ and half P+. COMP is silicided, so source and bulk are one net. A schematic with a separate bulk pin cannot match.

**Work-around:** Tie the bulk to the source in the schematic, as the `_tap` cells do, and strap the tie contact to the source contact in Metal1. Without the strap only Magic sees the connection, see `gf180_nfet_03v3_tap_nostrap` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Guard Ring option of the gdsfactory PCells

`bulk = "Guard Ring"` of the `gf180mcu` `nfet` draws the ring COMP, implant and contacts but no Metal1, and the device inside violates 11 rule classes (33 errors: `CO.6`, `CO.10`, `DF.3b`, `NP.3d/3e`, `NP.5a/5b`, `PL.6`, `PP.3d/3e`, `PP.12`). Magic DRC fails it too, with nine rule classes of its own (61 markers, among them `PL.6`, `PL.4` and `CO.4`).

**Work-around:** The `_ring` cells use the device without bulk option and draw the guard ring themselves (ring width 0.36 um, COMP space 0.32 um at 3.3 V and 0.36 um at 5/6 V, 0.48/0.52 um above and below the gate, implant enclosure 0.16 um, Nwell enclosure 0.12/0.16 um, Dualgate enclosure 0.24 um; the dimensions of the DRC-clean `gf180mcu_klayoutapi` ring).

Around the native `nfet_06v0_nvt` the ring has to stay 0.3 um outside the NAT layer, which the PCell draws 2 um beyond the device COMP. A ring under NAT is a second COMP on another potential (`NAT.6`). Magic DRC does not check that, see `gf180_nfet_06v0_nvt_ring_nat` in [EXPECTED_FAILS.md](EXPECTED_FAILS.md).

## Pins on Poly2

Magic reads `Poly2_Label` (30/10) as plain text, not as a port (`labels POLYTXT text` in the tech file, while the metal label layers are `port`). A gate pin on Poly2 is fine for KLayout LVS but Magic + Netgen LVS then reports `(no pin, node is G)`.

The cells here put every pin on a metal label layer. `gf180_nfet_03v3_tap_poly2pin` keeps the gate pin on Poly2 to show the issue, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Passive symbols and the KLayout deck

The KLayout deck reads capacitors and resistors only as `C` and `R` elements with `W`/`L` (`SubcircuitModelsReader` in `rule_decks/custom_classes.lvs`), and bipolar transistors as `Q` elements. The `gf180mcu_fd_pr` symbols of these devices have no `lvs_format`, unlike the MOS and diode symbols, so the CDL netlist carries subcircuit calls such as `XC1 C0 C1 cap_nmos_03v3 c_width=1u c_length=1u` or `XQ1 C B E S npn_00p54x02p00`, and KLayout LVS fails. The deck has a switch for this (`schematic_translate`, which runs `gf180_xschem_klayout_spice_convert.py`), but `sak-lvs.sh` does not set it, `run_lvs.py` offers no option for it, and the script only rewrites models starting with `cap_nmos`, `ppolyf_u`, `nfet` and `pfet`.

**Work-around:** Set `lvs_format` on the instance: `"@name @pinlist @model W=@W L=@L"` for capacitors and resistors, `"@name @pinlist @model"` for bipolar transistors. The CDL line becomes `C1 C0 C1 cap_nmos_03v3 W=1u L=1u` or `Q1 C B E S npn_00p54x02p00`, the SPICE netlist for Magic is unchanged. `gf180_cap_nmos_03v3_nofmt` is the one cell without it, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## MOS capacitors need a tap

`cap_nmos_*` and `cap_pmos_*` come without a substrate or Nwell tap and fail `DF.14_LV` / `DF.13_LV` (a tap within 20 um). The cells here put a 0.46 um tap under the wide bottom bar of the diffusion Metal1, which straps it to the diffusion terminal; 0.36 um is too small for `DF.9` (0.2025 um^2 of COMP).

## Guard rings of the diode PCells are solid plates

With `pcmpgr=1` (the default of `diode_pw2dw` and `sc_diode`, and always for `diode_dw2ps`) the `gf180mcu` diode PCells draw the guard ring COMP and its Pplus as one solid rectangle over the whole device, while the ring contacts sit where a `cw` wide ring (0.36 um) would be. The device is then a single P+ diffusion, and the ring contacts have no Metal1 either.

**Work-around:** The cells cut the ring out of the plate (width `cw`, implant `cw` plus 0.16 um) after flattening the PCell, and cover the ring with Metal1.

## Deep Nwell

`deepnwell=1` of the `gf180mcu` `nfet`/`pfet` PCells draws DNWELL (and LVPWELL around an NMOS, 2.51 um inside the DNWELL edge, `LPW.3`), but no DNWELL tap, and its `pcmpgr=1` substrate ring has the solid-plate problem of the diode rings above. The `gf180_dnwell_*` cells therefore use `pcmpgr=0` and draw both rings themselves: an N+ tap ring inside the DNWELL, 1 um outside the LVPWELL, and the P+ substrate ring 2.5 um outside the DNWELL (`DF.18`), which is also the guard ring `DN.3` asks for. Two devices share one DNWELL.

A PMOS in DNWELL (bulk = DNWELL, extracted as a regular `pfet_03v3` since `consider_dn_dw_features` defaults to false) still needs an N+ tap inside its own Nwell (`DF.13_LV`); the DNWELL tap ring outside the Nwell does not count. `gf180_dnwell_inv` has a 0.46 um tap in the PMOS Nwell, strapped to the ring.

The deep Nwell diodes `diode_pw2dw` and `diode_dw2ps` are only extracted under `WELL_DIODE_MK` (153/51), so the `gf180_dnwell_*` cells have no diode device, and their VDD and VSS pins connect to no device in either netlist.

## PCell defaults that fail `DF.9`

`DF.9` asks for 0.2025 um^2 of COMP. The substrate tap of the diffusion and poly resistors is 0.36 um by `w_res + 0.14` um, 0.2016 um^2 at the default `w_res = 0.42` of `nplus_u`, `pplus_u`, `nplus_s`, `pplus_s`, `npolyf_s` and `ppolyf_s`. The contacts of `diode_pw2dw` at its default `la = 0.74` are 0.36 x 0.48 um. The cells use 1 x 1 um.

## Small diodes are larger than their parameters

At the default `wa = la = 0.36` the `diode_nd2ps` and `diode_pd2nw` PCells draw the diode COMP 0.36 x 0.565 um, 0.2034 um^2, which is the smallest area of 0.36 um width that meets `DF.9`. A schematic with the PCell parameters (`area='0.36u * 0.36u '`, 0.1296 um^2) is 36 % smaller than the layout. Both extractors read the drawn area (`A=0.2034P P=1.85U`). Only Netgen reports the difference, as a property error that `sak-lvs.sh` does not count, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The `gf180_diode_nd2ps_*` and `gf180_diode_pd2nw_*` cells keep the PCell parameters in their schematics and show the mismatch.

**Work-around:** Take `area` and `pj` from the drawn COMP.

## Metal resistors

The `metal_resistor` PCell draws the `Metal<n>_Res` marker (110/11 to 110/13) but no `RES_MK` (110/5). The design manual asks for both: "Metal resistor should draw Metal1_Res to Metal5_Res for LVS purpose" (section 4.1, note 11), and "RES_MK layer is necessary for all resistors" (section 13.0 a, so that no dummy COMP is generated under them). The `gf180_rm*` cells add `RES_MK` over the marker in the top cell; the PCell stays as it is.

KLayout needs only `Metal<n>_Res` (`rm1_res = metal1.and(metal1_res)`), Magic both: its GDS import builds `rm1`..`rm3` as `MET<n> and RESDEF and MET<n>RES`, and `RESDEF` only receives 110/5, since the specific datatypes 110/11..15 are mapped to `MET<n>RES` first. Magic writes `RES_MK` itself for every metal resistor. It evaluates these import rules within each cell, though, so `RES_MK` in the top cell does nothing for the metal in the PCell, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

The PCell also widens `w_res` to the minimum width of the metal (0.28 um on Metal2 and Metal3) without reporting it in its parameters. Take W and L from the drawn marker.

## Silicided diffusion resistors

`nplus_s` and `pplus_s` have no Xschem symbol of their own. The cells use `nplus_u.sym` and `pplus_u.sym` with `model=nplus_s` / `model=pplus_s`.

## Symbol defaults

`nfet_06v0_nvt.sym` has `model=nfet_06v0` in its template, so a freshly placed native transistor netlists as a regular 6 V NMOS. Set `model=nfet_06v0_nvt` on the instance.

## MIM capacitor wiring

MIMTM.10 allows the bottom plate of a MIM capacitor to be connected only through the via above it, Via4 for option B on Metal5, and forbids any Via3 touching it. Neither DRC checks a Via3 outside the top plate, so a Via3 under a tab of the bottom plate passes both, see `gf180_cap_mim_2f0fF_via3` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

A BJT under the top plate (`FuseTop`, 75/0) is not extracted by KLayout LVS, while KLayout DRC has no rule against it, see `gf180_combined_cmim_ontop` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

**Work-around:** Connect the bottom plate from a Metal4 tab through Via4 up to Metal5, as `gf180_combined` does. Magic checks `MiM bottom plate surrounds contact < 0.4um (MIMTM.2)` on the whole plate including the tab, KLayout only near the top plate: give the Via4 at least 0.4 um of Metal4 on every side (0.37 um failed Magic DRC). Keep BJTs out from under the MIM.

## Dummy fill rules at `DRC_LEVEL=macro`

`macro` leaves out the density and antenna rules, but the dummy COMP rules run. `DCF.1a` reports an area of 20 um or more without COMP, such as a large MIM capacitor beside the devices. Areas under NDMY (111/5), `RES_MK`, Pad or `IND_MK` are exempt.

**Work-around:** `gf180_combined` covers its MIM with NDMY. Magic DRC, both LVS steps and all PEX steps give the same results with it as without.

## Full-RC PEX of devices in a deep Nwell

`magic-pex3` and `klayout-pex3` (kpex driving Magic) join a P-well isolated in a DNWELL to the substrate: the LVPWELL of the `gf180_dnwell_*` NMOS and the base of every NPN, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The port check catches it where a pin is left without an element. On `gf180_npn_00p54x04p00` and `gf180_npn_10p00x10p00` it does not: their full-RC netlist puts the substrate terminal on `VSUBS`, which is no port, and keeps resistor fragments of a few Ohm between B and S (`X0 C B E VSUBS npn_00p54x04p00` with `R0 B S 1.97113`). Every port has an element, so the port check passes a netlist that shorts base and substrate. `scripts/check_pex_modes.py` compares the device terminals of the full-RC netlist with the C-coupled one (`EXT_MODE=2`) and fails the step.

**Work-around:** Simulate such a cell with the C-coupled netlist, or check the full-RC one with `scripts/check_pex_modes.py` first.

## Variant D stack

`gf180mcuD` is 5LM with MIM option B (`mim_cap=2`, i.e. 2 fF/um^2) and the 1k high-Rs poly (`poly_res=1k`), see `run_lvs.py --variant=D`. `cap_mim_1f0fF`, `cap_mim_1f5fF`, `ppolyf_u_2k` and `ppolyf_u_3k` belong to other variants and have no cell here.
