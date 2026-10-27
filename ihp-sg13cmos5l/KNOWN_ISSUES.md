# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS and Magic DRC pass on every cell that is not broken on purpose. Two of the three `KNOWN_FAILS` entries are the same Magic + Netgen LVS issue, the third one is in Magic full-RC PEX. Of the `KNOWN_FALSE_PASSES` entries one is a Magic issue and one an issue of the Magic + Netgen LVS flow.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13cmos5l-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um); KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## Magic + Netgen LVS ignores device parameters

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_w_mismatch:magic-lvs`

`sak-lvs.sh` judges Magic + Netgen LVS by the line `Circuits match uniquely` alone. Netgen writes that line once the topology matches and reports wrong device parameters separately (`Property errors were found.`), so a wrong W or L passes. In `sg13_lv_nmos_tap_w_mismatch` Netgen reports `w circuit1: 1.5e-07 circuit2: 3e-07 (delta=66.7%, cutoff=1%)` and still ends with `Circuits match uniquely`. Checking for the property errors alone does not help yet: the netgen setup of the PDK (`libs.tech/netgen/ihp-sg13cmos5l_setup.tcl`) does not delete `mm_ok`, a Monte Carlo mismatch switch that Xschem writes to every device and that the layout cannot have, so almost every cell reports property errors. Two fixes are needed: `mm_ok` in the `property ... delete` lists of the netgen setup, and a Magic LVS verdict in `sak-lvs.sh` that fails on property errors.

## Magic full-RC PEX keeps a second pin name as a port with nothing attached

`KNOWN_FAILS` entry: `sg13_lv_nmos_tap_short_ds:magic-pex3`

In `sg13_lv_nmos_tap_short_ds` a Metal1 bridge joins the D and S pins on purpose (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)), so one net carries two pin names. A PEX step checks the extraction, not the cell, so the right verdict is a pass: catching the short is the job of the LVS steps, and both do. Magic's `ext2spice short` setting decides how such a net is written, and `sak-pex.sh` leaves it at the default `none`, which keeps one name and removes the others. `magic-pex1` and `magic-pex2` do that, their netlist starts with `.subckt sg13_lv_nmos_tap_short_ds_pex G B S`. Full-RC extraction (`magic-pex3`) lists `G B D S` instead, but every element sits on S and none on D, so D is neither removed nor connected, and `scripts/check_pex_ports.py` fails the step on the dangling port. Whether the dangling D comes from Magic's extresist output or from the netlist processing in `sak-pex.sh` is not investigated. `ext2spice short resistor` would keep both names in every mode, joined by a zero-ohm resistor.
