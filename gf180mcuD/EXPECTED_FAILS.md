# Expected Failures

Cells in `layout/` that are broken on purpose, to check that a tool still catches the mistake. Every entry of `EXPECTED_FAILS` in the [Makefile](Makefile) has a section here: what is broken in the cell, and which DRC and LVS steps have to catch it.

Unlike [KNOWN_ISSUES.md](KNOWN_ISSUES.md), which shrinks as bugs get fixed, this file only grows: its entries are tests, not bugs. If a tool misses the error in one of these cells because of a bug, that step belongs in `KNOWN_FALSE_PASSES`, and the bug in `KNOWN_ISSUES.md`.

## `gf180_nfet_06v0_nvt_ring_nat`: NAT over the guard ring

`EXPECTED_FAILS` entry: `gf180_nfet_06v0_nvt_ring_nat:klayout-drc`

`gf180_nfet_06v0_nvt_ring` with the NAT layer drawn 0.2 um around all of its COMP, so the guard ring lies under the same NAT shape as the native transistor. NAT.6 forbids that ("Two or more COMPs if connected to different potential are not allowed under same NAT layer"), see [FINDINGS.md](FINDINGS.md) ("Guard Ring option of the gdsfactory PCells"). The NAT stays inside the Dualgate, which reaches 0.24 um beyond the ring, so NAT.8 does not fire. KLayout reports `NAT.6` twice. Magic DRC misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). The circuit is unchanged, both LVS steps pass.

## `gf180_cap_mim_2f0fF_via3`: MIM bottom plate connected through Via3

No `EXPECTED_FAILS` entry: both DRC steps miss the error and are `KNOWN_FALSE_PASSES`, see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

A 5 x 5 um `cap_mim` (MIM option B on Metal5) whose bottom plate, Metal4, runs out in a Metal4 tab 1.2 um wide past the left edge of the top plate. A Via3 1.5 um outside the top plate connects the tab down to a Metal3 pad with the pin C1. MIMTM.10 allows the bottom plate to be connected only through the via above it, Via4, and forbids any Via3 touching it. `gf180_combined` and `gf180_combined_cmim_ontop` connect their MIM bottom plate the legal way, from the same kind of tab through Via4 up to Metal5. The circuit is right, both LVS steps pass.

## `gf180_diode_nd2ps_03v3`, `gf180_diode_nd2ps_06v0`, `gf180_diode_pd2nw_03v3`, `gf180_diode_pd2nw_06v0`: diode area of the PCell parameters

`EXPECTED_FAILS` entries: `gf180_diode_nd2ps_03v3:magic-lvs`, `gf180_diode_nd2ps_06v0:magic-lvs`, `gf180_diode_pd2nw_03v3:magic-lvs`, `gf180_diode_pd2nw_06v0:magic-lvs`

The layout is the PCell at its default `wa = la = 0.36`, which draws the diode COMP 0.36 x 0.565 um, 0.2034 um^2, to meet `DF.9` (see [FINDINGS.md](FINDINGS.md), "Small diodes are larger than their parameters"). The schematic keeps the PCell parameters, `area='0.36u * 0.36u '`, 0.1296 um^2. The GDS does not change when the PCell is fixed, so the cells stay a mismatch that LVS has to catch. Netgen reports `area circuit1: 2.034e-13   circuit2: 1.296e-13   (delta=44.3%, cutoff=2%)` and `Property errors were found.`, and `sak-lvs.sh` fails the step on that. KLayout LVS misses it, see `KNOWN_FALSE_PASSES` in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). Both DRC steps pass.

<!--
Template for a new cell:

## `<cell>`: <what is broken, in one line>

`EXPECTED_FAILS` entries: `<cell>:klayout-lvs`, `<cell>:magic-lvs`

What exactly is broken, which checks have to catch it, and why a correct tool can see it.
-->
