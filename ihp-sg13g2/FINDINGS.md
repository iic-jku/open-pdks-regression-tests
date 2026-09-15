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

## cap_cmomi pins

The pins must lie outside of the bus connection. The LVS extractor derives its ports as `metal<n>_pin.and(recog_mom)`, so every metal pin polygon inside the `Recog.mom` marker counts as a device port, and it needs exactly two. The marker spans the whole device including the bus connections, so a pin dropped on a bus is counted on top of the two MkPins the PCell already draws. At four ports the device is not extracted, and if it was the only device in the cell the layout netlist comes out empty.

**Symptom:** `cap_cmomi: expected exactly 2 port regions under the Recog.mom marker, found 4` in the KLayout log, then `Errors encountered during netlist extraction` and an empty `.SUBCKT`.

**Work-around:** Run a short metal stub out past the `Recog.mom` boundary and put the pin and its label on the stub. Moving only the label does nothing, it is the pin polygon that gets counted.
