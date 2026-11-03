# Expected Failures

Cells in `layout/` that are broken on purpose, to check that a tool still catches the mistake. Every entry of `EXPECTED_FAILS` in the [Makefile](Makefile) has a section here: what is broken in the cell, and which DRC and LVS steps have to catch it.

Unlike [KNOWN_ISSUES.md](KNOWN_ISSUES.md), which shrinks as bugs get fixed, this file only grows: its entries are tests, not bugs. If a tool misses the error in one of these cells because of a bug, that step belongs in `KNOWN_FALSE_PASSES`, and the bug in `KNOWN_ISSUES.md`.

Each cell is a copy of a cell of this directory with one of the repairs of [FINDINGS.md](FINDINGS.md) left out, so the error is the one the PCell draws. The PCells are written as plain cells (`<pcell>_<rule>`, without PCell context), so that a PCell refresh cannot change them. The cell they are copied from is the counter-test: it passes the steps listed here.

## `sky130_nfet_05v0_nvt_tap_hvdifftap16`: MV bulk tie too short

`EXPECTED_FAILS` entry: `sky130_nfet_05v0_nvt_tap_hvdifftap16:magic-drc`

`sky130_nfet_05v0_nvt_tap` without the tap extension: the bulk tie of the PCell reaches 0.45 um from the source, where `hvdifftap.16` asks for 0.7 um inside HVI (see [FINDINGS.md](FINDINGS.md), "Bulk tie is butted against the source"). Magic reports `MV Butting tap length < 0.7um (diff/tap.16)` three times. KLayout DRC misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The circuit is unchanged, LVS passes.

## `sky130_diode_pd2nw_05v5_psd8`: PSDM over the cathode ring

`EXPECTED_FAILS` entry: `sky130_diode_pd2nw_05v5_psd8:magic-drc`

`sky130_diode_pd2nw_05v5` with the PSDM rectangle of the `p_diode` PCell put back over the whole diode, so it covers the N+ cathode ring. `n/psd.8` forbids PSDM over N+ tap (see [FINDINGS.md](FINDINGS.md), "The p_diode PCell"). Magic has no rule of that name, but reports the ring: `nsd.10b` 4 times, `psd.10b` 2 times, `licon.7` 60 times and `difftap.11` 32 times. KLayout DRC misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The circuit is unchanged, LVS passes.

## `sky130_cap_var_hvt_varac5`: Nwell too close to the varactor gate

No `EXPECTED_FAILS` entry: both DRC steps miss the error and are `KNOWN_FALSE_PASSES`, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

`sky130_cap_var_hvt` with the Nwell of the `cap_var` PCell, which encloses the gate poly by 0.010 um at its ends; `varac.5` asks for 0.15 um (see [FINDINGS.md](FINDINGS.md), "Varactor"). The circuit is unchanged.

## `sky130_nfet_01v8_tap_licon15`: NPC too small around the poly contacts

No `EXPECTED_FAILS` entry: both DRC steps miss the error and are `KNOWN_FALSE_PASSES`, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

`sky130_nfet_01v8_tap` with the NPC of the `nfet` PCell, 0.06 um beside and 0.09 um above and below the two poly contacts; `licon.15` asks for 0.1 um (see [FINDINGS.md](FINDINGS.md), "NPC around the poly contacts"). The circuit is unchanged, LVS passes.

<!--
Template for a new cell:

## `<cell>`: <what is broken, in one line>

`EXPECTED_FAILS` entries: `<cell>:klayout-lvs`, `<cell>:magic-lvs`

What exactly is broken, which checks have to catch it, and why a correct tool can see it.
-->
