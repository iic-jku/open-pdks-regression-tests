# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS and Magic DRC pass on every cell that is not broken on purpose. Two `KNOWN_FAILS` entries are the same Magic + Netgen LVS issue, the third is a gdscheck finding. The `KNOWN_FALSE_PASSES` entry is a Magic issue.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13cmos5l-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um). KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## gdscheck reads the via columns of the MOM capacitor as an array

`KNOWN_FAILS` entry: `sg13_cmomi:gdscheck-drc`

gdscheck 0.2.1 reports `V1.b1`, `V2.b1` and `V3.b1` on `sg13_cmomi`, as on the cell of the same name in `../ihp-sg13g2`. V1.b1 is one of the IHP extra rules: "Min. Via1 space in an array of more than 3 rows and more than 3 columns = 0.29", required in one direction only, the other direction needs V1.b. The IHP `cmomi` PCell places one column of vias per finger, and the columns of neighbouring fingers are offset, so the vias form no rows. gdscheck takes the staggered columns for an array and asks for 0.29 um between the columns. The KLayout deck reports nothing at `DRC_LEVEL=regular`, which runs the extra rules of `sg13cmos5l_maximal.drc`, and Magic DRC passes the cell as well.

Upstream: [gdscheck#63](https://github.com/aesc-silicon/gdscheck/issues/63).
