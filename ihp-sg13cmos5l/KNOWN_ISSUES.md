# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and Magic DRC pass on every cell that is not broken on purpose, KLayout LVS on every such cell but the two `lvsres` cells, which Xschem cannot netlist yet. The two MOM capacitor entries of `KNOWN_FAILS` are one Magic + Netgen LVS issue, the four `lvsres` entries one missing Xschem symbol. Of the `KNOWN_FALSE_PASSES` entries one is a Magic issue and one an issue of the Magic + Netgen LVS flow.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## No Xschem symbol for the metal resistor `lvsres`

`KNOWN_FAILS` entries: `sg13_ind_lvsres:klayout-lvs`, `sg13_ind_lvsres:magic-lvs`, `sg13_balun_lvsres:klayout-lvs`, `sg13_balun_lvsres:magic-lvs`

IHP-Open-PDK#1121 adds the metal resistor `lvsres` to ihp-sg13g2 only: the symbol `sg13g2_pr/lvsres.sym` and the PCell. This PDK has no `sg13cmos5l_pr/lvsres.sym`, so Xschem stops with `Symbol not found: sg13cmos5l_pr/lvsres.sym` and neither LVS step reaches the check. Everything else is in place: the KLayout LVS deck files that read and extract `lvsres` are links into the ihp-sg13g2 deck, and Magic extracts the TopMetal1 and Metal4 resistors as it does on ihp-sg13g2. With the link `sg13cmos5l_pr/lvsres.sym -> ../../../../ihp-sg13g2/libs.tech/xschem/sg13g2_pr/lvsres.sym` added to the PDK, the way it ships `rsil.sym` and the other shared symbols, both cells pass both LVS steps, and this PDK's versions of the three ihp-sg13g2 cells broken on purpose (`sg13_ind_lvsres_short`, `sg13_ind_lvsres_swap`, `sg13_balun_lvsres_swap`) give the same verdicts as there. They follow once the symbol exists: until then their LVS steps could not reach the check, and the regression would report them as `BROKEN`.

Upstream: IHP announced the ihp-sg13cmos5l port as a separate pull request in IHP-Open-PDK#1121.

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13cmos5l-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um); KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## Magic + Netgen LVS ignores device parameters

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_w_mismatch:magic-lvs`

`sak-lvs.sh` judges Magic + Netgen LVS by the line `Circuits match uniquely` alone. Netgen writes that line once the topology matches and reports wrong device parameters separately (`Property errors were found.`), so a wrong W or L passes. In `sg13_lv_nmos_tap_w_mismatch` Netgen reports `w circuit1: 1.5e-07 circuit2: 3e-07 (delta=66.7%, cutoff=1%)` and still ends with `Circuits match uniquely`. Checking for the property errors alone does not help yet: the netgen setup of the PDK (`libs.tech/netgen/ihp-sg13cmos5l_setup.tcl`) does not delete `mm_ok`, a Monte Carlo mismatch switch that Xschem writes to every device and that the layout cannot have, so almost every cell reports property errors. Two fixes are needed: `mm_ok` in the `property ... delete` lists of the netgen setup, and a Magic LVS verdict in `sak-lvs.sh` that fails on property errors.
