# Findings and work-arounds for the ihp-sg13cmos5l PDK

Things in this PDK that are easy to get wrong and frustrating to troubleshoot. The ihp-sg13g2 counterpart is [../ihp-sg13g2/FINDINGS.md](../ihp-sg13g2/FINDINGS.md).

## No DigiSub layer

This PDK has no `DigiSub` layer, so the ihp-sg13g2 work-around for devices with a built-in guard ring (a `DigiSub` rectangle over the active area, see the ihp-sg13g2 findings) does not exist here. The cells in this directory only pass LVS with tap extraction disabled, which is what `sak-lvs.sh` does for both flows.

## No NBuLay layer

`NBuLay` does not exist in this PDK. A layout copied from ihp-sg13g2 can still carry shapes on it: this PDK's layer list does not show the layer, so the shapes are invisible, but DRC and LVS still flag them. Delete them after copying.

## cap_cmomi and cap_cmomf pins

The pins must lie outside of the device marker, `Recog.mom` for `cap_cmomi` and `Recog.momf` for `cap_cmomf`. The LVS extractor derives its ports as `metal<n>_pin.and(<marker>)`, so every metal pin polygon inside the marker counts as a device port, and it needs exactly two. The marker spans the whole device including the bus connections, so a pin dropped on a bus is counted on top of the two the PCell already draws. At four ports the device is not extracted and the deck stops with an error.

A top-level pin drawn right on top of a PCell pin fails the same way, but only in deep mode: the extractor counts the pin polygons without merging them, and deep mode keeps the top-level shape and the PCell shape apart. `sak-lvs.sh` runs deep. The KLayout GUI runs flat by default, merges the two and passes.

**Symptom:** `cap_cmomi: expected exactly 2 port regions under its recognition marker, found 4` (or the same for `cap_cmomf`) in the KLayout log. The run stops without a `.lvsdb`, and `sak-lvs.sh` exits with 5.

**Work-around:** Run a short metal stub out past the marker boundary and put the pin and its label on the stub. Moving only the label does nothing, it is the pin polygon that gets counted. Leaving out the top-level pins altogether passes KLayout LVS but not Magic + Netgen LVS: Magic then makes no ports from the labels (a label on the PCell's own pin is only a net name to it), the layout netlist has no subcircuit, Netgen finds nothing to compare, and `sak-lvs.sh` exits with 5 instead of failing on the known Magic issue (see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)).

The extractor lives in the ihp-sg13g2 deck (`custom_mom_extractor.lvs`), so this applies to both PDKs.

## Metal resistors (`lvsres`) on coils

A coil is one net from pin to pin, and a metal resistor in a lead lets LVS tell its pins apart, see the ihp-sg13g2 findings. This PDK has no `lvsres` PCell (IHP-Open-PDK#1121 adds it to ihp-sg13g2 only), so `sg13_ind_lvsres` and `sg13_balun_lvsres` draw the resistor by hand: a rectangle on the resistor layer of the metal (126/29 on TopMetal1, 50/29 on Metal4) across the full width of the trace, drawn in the same cell as the trace. Its length is the one the Xschem symbol writes for that layer, 1.64 um on TopMetal1 and 1 um on Metal1 to Metal4, since KLayout LVS compares L and W. The KLayout deck is the ihp-sg13g2 one, so the `IND` trap of the ihp-sg13g2 findings applies here as well. The symbol offers Metal5 and TopMetal2, which this PDK does not have: a resistor on them in a schematic can never match the layout.
