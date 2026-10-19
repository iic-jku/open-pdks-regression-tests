# Expected Failures

Cells in `layout/` that are broken on purpose, to check that a tool still catches the mistake. Every entry of `EXPECTED_FAILS` in the [Makefile](Makefile) has a section here: what is broken in the cell, and which DRC and LVS steps have to catch it.

Unlike [KNOWN_ISSUES.md](KNOWN_ISSUES.md), which shrinks as bugs get fixed, this file only grows: its entries are tests, not bugs. If a tool misses the error in one of these cells because of a bug, that step belongs in `KNOWN_FALSE_PASSES`, and the bug in `KNOWN_ISSUES.md`.

## `sg13_lv_nmos_tap_m1_b`: drain and source Metal1 0.12 um apart

`EXPECTED_FAILS` entries: `sg13_lv_nmos_tap_m1_b:klayout-drc`, `sg13_lv_nmos_tap_m1_b:magic-drc`

A copy of `sg13_lv_nmos_tap` with the drain Metal1 pad widened from 0.30 um to 0.45 um, which leaves 0.12 um to the source pad. The IHP rule M1.b asks for 0.18 um ("Min. Metal1 space"). It is a basic rule of the `macro` level, so both DRC flows have to report it: KLayout as `M1.b`, Magic as `Metal1 spacing < 0.18um (M1.b)`. Both pads are drawn in the top cell, so the cell also catches a DRC run that loads the top cell empty, as `gds flatglob *` did. The pads do not touch, the circuit is unchanged, and both LVS steps pass.

<!--
Template for a new cell:

## `<cell>`: <what is broken, in one line>

`EXPECTED_FAILS` entries: `<cell>:klayout-lvs`, `<cell>:magic-lvs`

What exactly is broken, which checks have to catch it, and why a correct tool can see it.
-->
