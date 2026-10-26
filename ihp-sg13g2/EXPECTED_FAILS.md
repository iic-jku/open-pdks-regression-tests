# Expected Failures

Cells in `layout/` that are broken on purpose, to check that a tool still catches the mistake. Every entry of `EXPECTED_FAILS` in the [Makefile](Makefile) has a section here: what is broken in the cell, and which DRC and LVS steps have to catch it.

Unlike [KNOWN_ISSUES.md](KNOWN_ISSUES.md), which shrinks as bugs get fixed, this file only grows: its entries are tests, not bugs. If a tool misses the error in one of these cells because of a bug, that step belongs in `KNOWN_FALSE_PASSES`, and the bug in `KNOWN_ISSUES.md`.

## `sg13_dnwell_inv_nmosi_c`: PMOS NWell too close to a tap in the isolated PWell

`EXPECTED_FAILS` entry: `sg13_dnwell_inv_nmosi_c:magic-drc`

A copy of `sg13_dnwell_inv` from before its fix. The NWell of the PMOS ends 0.30 um above the ptap inside the isolated PWell. The IHP rule nmosi.c asks for 0.39 um ("Min. NWell space to Iso-PWell-Activ", tested inside a closed NWell AND nBuLay ring). Magic reports it as `N-well space to diffusion in P-well (nmosi.c)`. `klayout-drc` has no entry and has to pass: nmosi.c is one of the IHP extra rules in `sg13g2_maximal.drc`, which `DRC_LEVEL=macro` does not run (and the deck would miss this case even with them, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)). The circuit is unchanged, so both LVS steps pass.

As long as the `isolbox` issue in KNOWN_ISSUES.md is open, Magic DRC also fails this cell for nmosi.b and nmosi.d, so the entry alone does not prove that Magic still finds nmosi.c. Look for nmosi.c in `verification/drc/sg13_dnwell_inv_nmosi_c.magic.drc/sg13_dnwell_inv_nmosi_c.magic.drc.rpt`.

## The `sg13_lv_nmos_tap_*` cells: one error per kind of rule

Copies of `sg13_lv_nmos_tap` with exactly one error each, so that every DRC and LVS step has a cell it must fail: a width, a space, an enclosure and an extension rule for DRC, a short, an open and a wrong device parameter for LVS. `sg13_lv_nmos_tap` itself passes every step and is the counter-test. Where an error sits inside a PCell (the transistor or the substrate tap), the cell holds a static copy of that PCell with the change (`nmos_cnt_c`, `nmos_gat_c`, `ptap1_cnt_c`), so that regenerating the PCells cannot repair it.

## `sg13_lv_nmos_tap_m1_a`: Metal1 0.10 um wide

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_m1_a:klayout-drc`, `sg13_lv_nmos_tap_m1_a:magic-drc`

A Metal1 stub 0.10 um wide and 0.40 um long on the drain pad. M1.a asks for 0.16 um ("Min. Metal1 width"). KLayout reports `M1.a`, Magic `Metal1 width < 0.16um (M1.a)`. The stub belongs to the drain net, both LVS steps pass.

## `sg13_lv_nmos_tap_m1_b`: drain and source Metal1 0.12 um apart

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_m1_b:klayout-drc`, `sg13_lv_nmos_tap_m1_b:magic-drc`

A copy of `sg13_lv_nmos_tap` with the drain Metal1 pad widened from 0.30 um to 0.45 um, which leaves 0.12 um to the source pad. The IHP rule M1.b asks for 0.18 um ("Min. Metal1 space"). It is a basic rule of the `macro` level, so both DRC flows have to report it: KLayout as `M1.b`, Magic as `Metal1 spacing < 0.18um (M1.b)`. Both pads are drawn in the top cell, so the cell also catches a DRC run that loads the top cell empty, as `gds flatglob *` did. The pads do not touch, the circuit is unchanged, and both LVS steps pass.

## `sg13_lv_nmos_tap_cnt_c`: drain contact 0.04 um inside Activ

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_cnt_c:klayout-drc`, `sg13_lv_nmos_tap_cnt_c:magic-drc`

The left edge of the drain Activ moved from 0 to 0.03 um, so the drain contact is 0.04 um from it. Cnt.c asks for 0.07 um ("Min. Activ enclosure of Cont"). KLayout reports `Cnt.c`, Magic `N-diffusion overlap of N-diffusion contact < 0.07um (Cnt.c)`. Channel width and length stay the same, both LVS steps pass.

## `sg13_lv_nmos_tap_cnt_c_ptap`: substrate tap contacts 0.04 um inside Activ

`EXPECTED_FAILS` entry: `sg13_lv_nmos_tap_cnt_c_ptap:klayout-drc`

The same rule as `sg13_lv_nmos_tap_cnt_c`, at the substrate tap instead of the drain: the left edge of the tap Activ moved in by 0.10 um, so its two left contacts are 0.04 um from it. KLayout reports `Cnt.c` twice. Magic DRC misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md): the pair of cells shows that Magic checks Cnt.c at a drain contact and not at a substrate tap. Both LVS steps pass.

## `sg13_lv_nmos_tap_gat_c`: gate end cap 0.10 um

`EXPECTED_FAILS` entry: `sg13_lv_nmos_tap_gat_c:magic-drc`

The gate poly ends 0.10 um below the channel instead of 0.18 um (GatPoly, GatPoly.pin and HeatTrans alike). Gat.c asks for 0.18 um ("Min. GatPoly extension over Activ (end cap)"). Magic reports `Poly overhang of transistor < 0.18um (Gat.c)`. `klayout-drc` has no entry and has to pass: Gat.c is one of the IHP extra rules in `sg13g2_maximal.drc`, which `DRC_LEVEL=macro` does not run. With `DRC_LEVEL=regular` KLayout reports `Gat.c` as well. Both LVS steps pass.

## `sg13_lv_nmos_tap_short_ds`: drain and source shorted

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_short_ds:klayout-lvs`, `sg13_lv_nmos_tap_short_ds:magic-lvs`

A Metal1 bridge joins the drain and the source pad. The layout has three nets where the schematic has four, and the D and S pins sit on one net. The bridge keeps every Metal1 rule, both DRC steps pass.

## `sg13_lv_nmos_tap_open_g`: gate not connected to its pin

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_open_g:klayout-lvs`, `sg13_lv_nmos_tap_open_g:magic-lvs`

The gate contact with its pad, pin and label sits 0.30 um higher, and the gate poly ends 0.20 um below it, so the G pin no longer reaches the transistor gate. The gate poly keeps 0.092 um2 (Gat.e asks for 0.09) and the 0.20 um gap keeps Gat.b (0.18), so both DRC steps pass.

## `sg13_lv_nmos_tap_w_mismatch`: W in the schematic differs from the layout

`EXPECTED_FAILS` entry: `sg13_lv_nmos_tap_w_mismatch:klayout-lvs`

The layout is `sg13_lv_nmos_tap` unchanged, the schematic has `w=0.30u` instead of `0.15u`. KLayout LVS compares W and fails. Magic + Netgen LVS misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). Both DRC steps pass.

## The `sg13_*_lvsres_*` cells: one error per coil

Copies of `sg13_ind_lvsres` and `sg13_balun_lvsres` with one error each. A coil is one net from pin to pin, and only the metal resistors (`lvsres`) in its leads let LVS tell the pins apart. `sg13_ind_lvsres` is a two-turn TopMetal2 spiral with a TopMetal1 underpass and one `lvsres` on each lead, TopMetal2 on LA and TopMetal1 on LB. `sg13_balun_lvsres` is a stacked transformer: a TopMetal2 primary P1/P2 with an `lvsres` on the P1 lead, and a TopMetal1 secondary with the centre tap CT and an `lvsres` on each side of the ring, so the secondary reads S1, CT, S2 in a chain. Each copy keeps the schematic of its base cell. [../scripts/gen_lvsres_cells.py](../scripts/gen_lvsres_cells.py) generates all five layouts, and every one passes both DRC steps.

## `sg13_ind_lvsres_short`: coil without metal resistors

`EXPECTED_FAILS` entries: `sg13_ind_lvsres_short:klayout-lvs`, `sg13_ind_lvsres_short:magic-lvs`

`sg13_ind_lvsres` without its two `lvsres`, so LA and LB are one net through the coil, which is what every RF block without metal resistors looks like to LVS. The schematic has two resistors between the pins. KLayout reports `Netlists don't match`, Netgen ends with `Top level cell failed pin matching`.

## `sg13_ind_lvsres_swap`: LA and LB labels swapped

`EXPECTED_FAILS` entry: `sg13_ind_lvsres_swap:klayout-lvs`

The LA label sits on the underpass lead and LB on the outer lead. KLayout extracts one device class per metal (`lvsres layer=TopMetal2` and `lvsres layer=TopMetal1`), so the TopMetal2 resistor ends on LB instead of LA and the netlists do not match. Magic + Netgen LVS misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## `sg13_balun_lvsres_swap`: S1 and CT labels swapped

`EXPECTED_FAILS` entries: `sg13_balun_lvsres_swap:klayout-lvs`, `sg13_balun_lvsres_swap:magic-lvs`

The S1 label sits on the centre tap and CT on the S1 lead. The centre tap is the net between the two secondary resistors and a lead is not, so both flows see the swap: KLayout reports `Netlists don't match`, Netgen pairs S1 with CT (`**Mismatch**`) and ends with `Top level cell failed pin matching`.

<!--
Template for a new cell:

## `<cell>`: <what is broken, in one line>

`EXPECTED_FAILS` entries: `<cell>:klayout-lvs`, `<cell>:magic-lvs`

What exactly is broken, which checks have to catch it, and why a correct tool can see it.
-->
