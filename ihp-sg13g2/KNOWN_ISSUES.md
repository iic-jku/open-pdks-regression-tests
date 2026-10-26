# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS pass on every cell that is not broken on purpose. Every `KNOWN_FAILS` entry is a Magic issue. Of the `KNOWN_FALSE_PASSES` entries one is a Magic issue and two are issues of the Magic + Netgen LVS flow.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## Magic DRC reports MIM.e on every MIM capacitor

`KNOWN_FAILS` entries: `sg13_cmim:magic-drc`, `sg13_rf_cmim:magic-drc`, `sg13_combined:magic-drc`, `sg13_combined_wo_rfcmim:magic-drc`, `sg13_combined_cmim_ontop:magic-drc`, `sg13_combined_cmim_ontop_wo_rfcmim:magic-drc`

Magic reports `MiM cap spacing to unrelated metal6 < 0.6um (MIM.e)` in a band along the inner edge of every `cmim` and `rfcmim` PCell. Magic builds the capacitor contact from the Vmim array (`grow 420`, `shrink 60` in the cifin rules), and that contact ends 0.06 um inside the edge of the TopMetal1 plate the PCell draws. The rim of the plate outside the contact counts as metal6 that is not connected to the capacitor. The IHP rule MIM.e is "Min. TopMetal1 space to MIM = 0.60"; the plate on top of the MIM is the capacitor's own top plate. KLayout DRC with the extra rules (`sg13g2_maximal.drc`, where MIM.e is checked) reports no MIM.e.

## Magic DRC still checks MIM.i, which IHP removed

`KNOWN_FAILS` entries (together with MIM.e above): `sg13_combined_cmim_ontop:magic-drc`, `sg13_combined_cmim_ontop_wo_rfcmim:magic-drc`

Magic reports `Via4 cannot contact MiM cap bottom plate (MIM.i)` (`spacing mimcap via4/m5 810` in the Magic DRC rules). IHP removed MIM.i in revision 0.2 of the SG13G2 layout rules (2024-03-08, change history: "Chapter 6.11: Remove MIM.i"), and the KLayout deck has no such rule.

## Magic DRC checks NBL.d and NBL.f without nets

`KNOWN_FAILS` entries: `sg13_combined:magic-drc`, `sg13_combined_wo_rfcmim:magic-drc`, `sg13_combined_cmim_ontop:magic-drc`, `sg13_combined_cmim_ontop_wo_rfcmim:magic-drc` (together with the MIM entries above), `sg13_hv_pmos_tap:magic-drc`, `sg13_lv_pmos_tap:magic-drc`, `sg13_short1:magic-drc`

The IHP rules are "NBL.d: Min. PWell width between nBuLay and NWell (different net) = 2.20" and "NBL.f: Min. nBuLay space to unrelated P+Activ = 0.50". The `ntap1` PCell always draws nBuLay under its NWell, and guard rings can carry nBuLay too. Magic checks both rules by geometry only (`spacing dnwell allnwell 2200 surround_ok`, `spacing dnwell allpactive 500 surround_ok`), so it reports an NWell of the same net that overlaps the nBuLay only partly, and the P+ source and drain of a PMOS in that same NWell. KLayout checks both rules per net and is clean on these cells. Both tools do catch a real violation, tested in separate cells: an NWell of another net 2.0 um from the nBuLay, and a substrate tie 0.30 um from it.

## Magic DRC reports nmosi.b and nmosi.d on every `isolbox`

`KNOWN_FAILS` entries: `sg13_dnwell_inv:magic-drc`, `sg13_dnwell_nmos:magic-drc`

Magic reads the NWell of the IHP `isolbox` PCell as its own type `isolbox`. The derived layers Magic uses for the nmosi rules (`style drc` in the cifout rules, starting with `pwell_in_dnwell = dnwell and-not nwell`) only count `nwell`, so the whole NWell ring around the isolated PWell is reported as missing (`N-well overlap of deep N-well < 0.62um inside (nmosi.d)`), and nmosi.b fires along the same ring. Other Magic rules do list `nwell,isolbox` together. In both cells the ring overlaps the nBuLay by 0.65 um (nmosi.d asks for 0.62), and KLayout DRC with the extra rules reports no nmosi violation.

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13g2-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um); KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## Magic + Netgen LVS ignores device parameters

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_w_mismatch:magic-lvs`

`sak-lvs.sh` judges Magic + Netgen LVS by the line `Circuits match uniquely` alone. Netgen writes that line once the topology matches and reports wrong device parameters separately (`Property errors were found.`), so a wrong W or L passes. In `sg13_lv_nmos_tap_w_mismatch` Netgen reports `w circuit1: 1.5e-07 circuit2: 3e-07 (delta=66.7%, cutoff=1%)` and still ends with `Circuits match uniquely`. Checking for the property errors alone does not help yet: the netgen setup of the PDK (`libs.tech/netgen/ihp-sg13g2_setup.tcl`) does not delete `mm_ok`, a Monte Carlo mismatch switch that Xschem writes to every device and that the layout cannot have, so almost every cell reports property errors. Two fixes are needed: `mm_ok` in the `property ... delete` lists of the netgen setup, and a Magic LVS verdict in `sak-lvs.sh` that fails on property errors.

The `lvsres` cells pass Magic + Netgen LVS only because of this verdict. The Xschem symbol `sg13g2_pr/lvsres.sym` writes every metal resistor as `1e-6` Ohm into the SPICE netlist, while Magic extracts the sheet resistance times L/W, so Netgen reports a property error on every `lvsres`, in `sg13_balun_lvsres` for example `value circuit1: 0.0055 circuit2: 1e-06 (delta=200%, cutoff=1%)` for 2 x 4 um of TopMetal2. A verdict that fails on property errors would fail them all, unless the symbol writes the same sheet resistance times L/W: with 0.0055 and 0.00738 Ohm written into the netlist of `sg13_ind_lvsres` by hand, Netgen ends with `Circuits match uniquely` and no property error.

## Magic + Netgen LVS cannot tell the leads of a coil apart

`KNOWN_FALSE_PASSES` entry: `sg13_ind_lvsres_swap:magic-lvs`

Magic extracts every metal resistor as an ideal resistor without a model (`device resistor None rm6 *metal6` and its siblings in `libs.tech/magic/ihp-sg13g2-extract.tech`), so to Netgen a TopMetal1 resistor and a TopMetal2 resistor are the same device. The two `lvsres` of the inductor sit in series on the coil net, Netgen merges them into one resistor between LA and LB (`Merged 1 series devices`), and that resistor has no direction. With LA and LB swapped in `sg13_ind_lvsres_swap`, Netgen still ends with `Circuits match uniquely`. KLayout keeps one device class per metal and catches the swap. The Magic tech README (`libs.tech/magic/README.md`) says these resistors wait for an `lvsres` model, and IHP-Open-PDK#1121 adds `lvsres` on the KLayout and Xschem side only.

## Not checked at `DRC_LEVEL=macro`: KLayout misses nmosi.c in `sg13_dnwell_inv_nmosi_c`

No list entry. `klayout-drc` runs at `DRC_LEVEL=macro`, which leaves out the IHP extra rules in `sg13g2_maximal.drc`, and nmosi.c is one of them, so the step passes `sg13_dnwell_inv_nmosi_c` legitimately (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)). With the extra rules (`DRC_LEVEL=regular`) KLayout would still miss it: the deck measures nmosi.c only against `NWell.with_holes`, the isolation ring, not against an NWell inside it, and reports `nmosi.c: 0 error(s)`. Should the regression ever run the extra rules, the step belongs in `KNOWN_FALSE_PASSES`.
