# Findings and work-arounds for the ihp-sg13g2 PDK

Things in this PDK that are easy to get wrong and frustrating to troubleshoot. The ihp-sg13cmos5l counterpart is [../ihp-sg13cmos5l/FINDINGS.md](../ihp-sg13cmos5l/FINDINGS.md).

## Schottky diode

Needs a database unit of 1 nm for a correct extraction and a passing LVS.

## Taps and the substrate net (`sub!`)

Devices with a built-in guard ring need the `DigiSub` layer.

**Example 1:** The RF NMOS has a built-in guard ring, so the bulk connection of the PCell already is the Metal1 contact of that guard ring. Without `DigiSub`, the substrate net (`sub!`) is shorted to VSS.

**Example 2:** The Schottky diode has a TIE connection that already is the Metal1 connection of the ptap. Without `DigiSub`, the substrate net (`sub!`) is shorted to VSS.

**Work-around:** Draw a `DigiSub` rectangle over the affected active area.

**Known affected devices:** `rf_cmim`, `rf_lv_nmos`, `rf_hv_nmos` and `schottky`.

## Vias

Via arrays are only DRC clean as 3x1, 2x2 or larger. A 2x1 array just misses, a single via is far off.

## cap_cmomi and cap_cmomf pins

The pins must lie outside of the device marker, `Recog.mom` for `cap_cmomi` and `Recog.momf` for `cap_cmomf`. The LVS extractor derives its ports as `metal<n>_pin.and(<marker>)`, so every metal pin polygon inside the marker counts as a device port, and it needs exactly two. The marker spans the whole device including the bus connections, so a pin dropped on a bus is counted on top of the two MkPins the PCell already draws. At four ports the device is not extracted and the deck stops with an error.

A top-level pin drawn right on top of a PCell pin fails the same way, but only in deep mode: the extractor counts the pin polygons without merging them, and deep mode keeps the top-level shape and the PCell shape apart. `sak-lvs.sh` runs deep. The KLayout GUI runs flat by default, merges the two and passes.

**Symptom:** `cap_cmomi: expected exactly 2 port regions under its recognition marker, found 4` (or the same for `cap_cmomf`) in the KLayout log, then `Errors encountered during netlist extraction`. The run stops without a `.lvsdb`, and `sak-lvs.sh` exits with 5.

**Work-around:** Run a short metal stub out past the marker boundary and put the pin and its label on the stub. Moving only the label does nothing, it is the pin polygon that gets counted. Leaving out the top-level pins altogether passes KLayout LVS but not Magic + Netgen LVS: Magic then makes no ports from the labels (a label on the PCell's own pin is only a net name to it), the layout netlist has no subcircuit, Netgen finds nothing to compare, and `sak-lvs.sh` exits with 5 instead of failing on the known Magic issue (see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)).

## Metal resistors (`lvsres`) on coils

A coil is one net from pin to pin. A metal resistor in a lead breaks it, so that LVS can tell the pins apart: the `lvsres` PCell in the layout and the symbol `sg13g2_pr/lvsres.sym` in the schematic, both from IHP-Open-PDK#1121. `sg13_ind_lvsres` and `sg13_balun_lvsres` are drawn this way. Three things to get right:

**Length.** The symbol ignores its `l` parameter. The CDL netlist always carries the length of the layer, 1 um on Metal1 to Metal5, 1.64 um on TopMetal1 and 2 um on TopMetal2, the defaults the PCell sets for each layer. KLayout LVS compares L and W of every `lvsres` (an L 1 % longer fails), so draw every resistor with that length, and give resistors that have to be told apart different widths.

**Cut the trace under the PCell.** Placed on top of a drawn trace, the resistor of the PCell overlaps metal of the parent cell, and Magic DRC reports `Can't overlap those layers` on every resistor, while KLayout DRC and both LVS flows accept it. Cut the trace under the resistor body: the PCell draws its own metal 0.2 um past both ends and closes the gap.

**No `IND` over the coil.** The KLayout LVS deck takes TopMetal1 and TopMetal2 inside `IND` (27/0) out of the conductors (`topmetal1_con` and `topmetal2_con` in `general_derivations.lvs`), since it extracts the IHP inductor PCells there. A drawn coil under `IND` falls apart: with an `IND` box over the turns of `sg13_ind_lvsres`, its two resistors end on two separate nets and KLayout LVS fails, while Magic ignores `IND` and passes. The only DRC rule that looks at `IND` is TM2.bR (5 um space next to a TopMetal2 line wider than 5 um that runs parallel for more than 50 um), so a coil with metal resistors keeps its TopMetal2 lines at 5 um or below, or 5 um apart.
