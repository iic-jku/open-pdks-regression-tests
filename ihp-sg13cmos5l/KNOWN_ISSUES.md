# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS and Magic DRC pass on every cell that is not broken on purpose. Two of the three `KNOWN_FAILS` entries are the same Magic + Netgen LVS issue, the third one is in Magic full-RC PEX. The `KNOWN_FALSE_PASSES` entry is a Magic issue.

## Magic + Netgen LVS fails on the MOM capacitors

`KNOWN_FAILS` entries: `sg13_cmomi:magic-lvs`, `sg13_cmomf:magic-lvs`

Magic does not extract the MOM capacitors, neither the interdigitated `cap_cmomi` nor the fringe `cap_cmomf`: the Magic tech file has no device for them and does not read their markers (`Recog.mom` 99/39, `Recog.momf` 99/40). The layout netlist keeps the two pins but no device, while the schematic has one, and Netgen ends with `has no elements and/or nodes. Not checked.`

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)

## Magic DRC does not check contacts in substrate taps

`KNOWN_FALSE_PASSES` entry: `sg13_lv_nmos_tap_cnt_c_ptap:magic-drc`

Magic reads a contact in a substrate tap (diffusion tagged `sub!` with the Substrate marker, as every IHP `ptap1` PCell draws it) as its own type `ptapc` (`ptapdiffcont`), not as `psc`. The DRC rules (`libs.tech/magic/ihp-sg13cmos5l-drc.tech`) have no rule for `ptapc` at all, neither directly nor through the aliases that contain it (`allpdiffcontlv`, `allpdiffconthv`): Cnt.a, Cnt.b and Cnt.c are never checked at a substrate tap. `sg13_lv_nmos_tap_cnt_c_ptap` has two contacts 0.04 um inside the tap Activ (Cnt.c asks for 0.07 um); KLayout reports both, Magic reports nothing. The same error at a drain contact (`sg13_lv_nmos_tap_cnt_c`) is caught by Magic.

## Magic full-RC PEX keeps a second pin name as a port with nothing attached

`KNOWN_FAILS` entries: `sg13_lv_nmos_tap_short_ds:magic-pex3`, `sg13_lv_nmos_tap_short_ds:klayout-pex3`

In `sg13_lv_nmos_tap_short_ds` a Metal1 bridge joins the D and S pins on purpose (see [EXPECTED_FAILS.md](EXPECTED_FAILS.md)), so one net carries two pin names. A PEX step checks the extraction, not the cell, so the right verdict is a pass: catching the short is the job of the LVS steps, and both do. Magic's `ext2spice short` setting decides how such a net is written, and `sak-pex.sh` leaves it at the default `none`, which keeps one name and removes the others. `magic-pex1` and `magic-pex2` do that, their netlist starts with `.subckt sg13_lv_nmos_tap_short_ds_pex G B S`. Full-RC extraction (`magic-pex3`) lists `G B D S` instead, but every element sits on S and none on D, so D is neither removed nor connected, and `scripts/check_pex_ports.py` fails the step on the dangling port. `klayout-pex3`, kpex driving Magic in RC mode, writes the same `G B D S` header with nothing on D. kpex does not call `sak-pex.sh`, and `sak-pex.sh` does not touch the port list after `ext2spice` either, so the dangling port is Magic's full-RC output. The PEX bench meets the same on its wide via chains, see [pex_bench/README.md](pex_bench/README.md#outputs-and-the-check). `ext2spice short resistor` would keep both names in every mode, joined by a zero-ohm resistor.
