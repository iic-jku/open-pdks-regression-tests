# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS and gdscheck DRC pass on every cell that is not broken on purpose. Every `KNOWN_FAILS` entry is an issue of Magic or of a Magic flow. The `KNOWN_FALSE_PASSES` entry is a Magic issue.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## Magic DRC still checks MIM.i, which IHP removed

`KNOWN_FAILS` entries (together with NBL.d below): `sg13_combined_cmim_ontop:magic-drc`, `sg13_combined_cmim_ontop_wo_rfcmim:magic-drc`

Magic reports `Via4 cannot contact MiM cap bottom plate (MIM.i)` (`spacing mimcap via4/m5 810` in the Magic DRC rules). IHP removed MIM.i in revision 0.2 of the SG13G2 layout rules (2024-03-08, change history: "Chapter 6.11: Remove MIM.i"), and the KLayout deck has no such rule.

## Magic DRC checks NBL.d without nets

`KNOWN_FAILS` entries: `sg13_combined:magic-drc`, `sg13_combined_wo_rfcmim:magic-drc`, `sg13_combined_cmim_ontop:magic-drc`, `sg13_combined_cmim_ontop_wo_rfcmim:magic-drc` (together with MIM.i above), `sg13_hv_pmos_tap:magic-drc`, `sg13_lv_pmos_tap:magic-drc`

The IHP rule is "NBL.d: Min. PWell width between nBuLay and NWell (different net) = 2.20". The `ntap1` PCell always draws nBuLay under its NWell, and guard rings can carry nBuLay too. Magic checks the rule by geometry only (`spacing dnwell allnwell 2200 surround_ok`), so it reports an NWell of the same net that overlaps the nBuLay only partly. KLayout checks the rule per net and is clean on these cells. The same problem with "NBL.f: Min. nBuLay space to unrelated P+Activ = 0.50", where Magic reported the P+ source and drain of a PMOS in that NWell, is fixed since IHP-Open-PDK#1340 (`spacing dnwell allpactivetap 500 surround_ok`, P+ taps only), which made `sg13_short1` pass. Both tools do catch a real violation, tested in separate cells: an NWell of another net 2.0 um from the nBuLay, and a substrate tie 0.30 um from it.

## Magic DRC reports nmosi.b and nmosi.d on every `isolbox`

`KNOWN_FAILS` entries: `sg13_dnwell_inv:magic-drc`, `sg13_dnwell_nmos:magic-drc`

Magic reads the NWell of the IHP `isolbox` PCell as its own type `isolbox`. The derived layers Magic uses for the nmosi rules (`style drc` in the cifout rules, starting with `pwell_in_dnwell = dnwell and-not nwell`) only count `nwell`, so the whole NWell ring around the isolated PWell is reported as missing (`N-well overlap of deep N-well < 0.62um inside (nmosi.d)`), and nmosi.b fires along the same ring. Other Magic rules do list `nwell,isolbox` together. In both cells the ring overlaps the nBuLay by 0.65 um (nmosi.d asks for 0.62), and KLayout DRC with the extra rules reports no nmosi violation.

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13g2-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um). KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## Magic + Netgen LVS: `wfeed` of the RF MIM capacitor is compared

`KNOWN_FAILS` entries: `sg13_rf_cmim:magic-lvs`, `sg13_combined:magic-lvs`, `sg13_combined_cmim_ontop:magic-lvs` (both contain the RF MIM capacitor)

Xschem writes `XC1 C0 C1 CX cap_rfcmim w=10.0e-6 l=10.0e-6 wfeed=5.0e-6 m=1`, Magic extracts `X0 C0 C1 CX cap_rfcmim l=10u w=10u`. The netgen setup derives area and perimeter of `cap_rfcmim` from `w` and `l` and deletes `ic w l`, but not `wfeed`, which the layout extraction does not have. Netgen reports `Property wfeed in circuit2 has no matching property in circuit1` and `Property errors were found.`, and `sak-lvs.sh` fails the step on that.

## Not checked at `DRC_LEVEL=macro`: KLayout misses nmosi.c in `sg13_dnwell_inv_nmosi_c`

No list entry. `klayout-drc` runs at `DRC_LEVEL=macro`, which leaves out the IHP extra rules in `sg13g2_maximal.drc`, and nmosi.c is one of them, so the step passes `sg13_dnwell_inv_nmosi_c` legitimately (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)). With the extra rules (`DRC_LEVEL=regular`) KLayout would still miss it: the deck measures nmosi.c only against `NWell.with_holes`, the isolation ring, not against an NWell inside it, and reports `nmosi.c: 0 error(s)`. Should the regression ever run the extra rules, the step belongs in `KNOWN_FALSE_PASSES`. gdscheck, whose `core` suite includes the extra rules, reports nmosi.c on the cell, so `sg13_dnwell_inv_nmosi_c:gdscheck-drc` is an `EXPECTED_FAILS` entry.
