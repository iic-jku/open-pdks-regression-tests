# Expected Failures

Cells in `layout/` that are broken on purpose, to check that a tool still catches the mistake. Every entry of `EXPECTED_FAILS` in the [Makefile](Makefile) has a section here: what is broken in the cell, and which DRC and LVS steps have to catch it.

Unlike [KNOWN_ISSUES.md](KNOWN_ISSUES.md), which shrinks as bugs get fixed, this file only grows: its entries are tests, not bugs. If a tool misses the error in one of these cells because of a bug, that step belongs in `KNOWN_FALSE_PASSES`, and the bug in `KNOWN_ISSUES.md`.

## `sg13_dnwell_inv_nmosi_c`: PMOS NWell too close to a tap in the isolated PWell

`EXPECTED_FAILS` entry: `sg13_dnwell_inv_nmosi_c:magic-drc`

A copy of `sg13_dnwell_inv` from before its fix. The NWell of the PMOS ends 0.30 um above the ptap inside the isolated PWell. The IHP rule nmosi.c asks for 0.39 um ("Min. NWell space to Iso-PWell-Activ", tested inside a closed NWell AND nBuLay ring). Magic reports it as `N-well space to diffusion in P-well (nmosi.c)`. KLayout DRC misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The circuit is unchanged, so both LVS steps pass.

As long as the `isolbox` issue in KNOWN_ISSUES.md is open, Magic DRC also fails this cell for nmosi.b and nmosi.d, so the entry alone does not prove that Magic still finds nmosi.c. Look for nmosi.c in `verification/drc/sg13_dnwell_inv_nmosi_c.magic.drc/sg13_dnwell_inv_nmosi_c.magic.drc.rpt`.

<!--
Template for a new cell:

## `<cell>`: <what is broken, in one line>

`EXPECTED_FAILS` entries: `<cell>:klayout-lvs`, `<cell>:magic-lvs`

What exactly is broken, which checks have to catch it, and why a correct tool can see it.
-->
