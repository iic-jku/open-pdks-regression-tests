# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS pass on every cell that is not broken on purpose. Every `KNOWN_FAILS` entry is a Magic issue; the one `KNOWN_FALSE_PASSES` entry is a KLayout DRC deck issue.

## Magic + Netgen LVS fails on `sg13_cmomi`

`KNOWN_FAILS` entry: `sg13_cmomi:magic-lvs`

Magic does not extract the interdigitated MOM capacitor (`cap_cmomi`) from the layout.

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

## KLayout DRC misses nmosi.c in `sg13_dnwell_inv_nmosi_c`

`KNOWN_FALSE_PASSES` entry: `sg13_dnwell_inv_nmosi_c:klayout-drc`

The cell is broken on purpose, see [EXPECTED_FAILS.md](EXPECTED_FAILS.md): the NWell of the PMOS is 0.30 um from a tap in the isolated PWell, nmosi.c asks for 0.39 um. KLayout misses it for two reasons. nmosi.c is one of the IHP extra rules in `sg13g2_maximal.drc`, which `klayout-drc` does not run at `DRC_LEVEL=macro`. And with the extra rules (`DRC_LEVEL=regular`) the deck measures nmosi.c only against `NWell.with_holes`, the isolation ring, not against an NWell inside it, and reports `nmosi.c: 0 error(s)`.
