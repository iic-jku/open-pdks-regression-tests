# Findings and work-arounds for the ihp-sg13g2 pdk
This document is intended to help designers avoid mistakes that can get frustrating to troubleshoot
##  Schottky Diode
Needs the database units at 1nm for correct extraction/LVS pass.
## Taps/psub(sub!)
When working with devices that have a built-in guardring the use of the digisub layer is mandatory.   
```Example 1:``` The RF NMOS has a built-in guardring so the bulk connection of the pcell already corresponds to the Metal1 contact of the guardring. This, without the use of the digisub layer, causes the psub (sub!) net to be shorted to VSS.   
```Example 2:``` Schottky Diode has a TIE connection that already represents the Metal1 connection of the ptap and thus, without the use of the digisub layer, causes the psub (sub!) net to be shorted to VSS.   
```Workaround:``` Draw a digisub rectangle over the affected active area.   
```Known affected devices:```rf_cmim, rf_lv_nmos, rf_hv_nmos and schottky

## Vias
Vias are only drc clean when 3x1 or 2x2 or greater. The 2x1 are just short of being drc clean and the 1x1 are way off.

## cap_cmomi
The pins must lie outside of the bus connection. The LVS extractor derives its ports as `metal<n>_pin.and(recog_mom)`, so every metal pin polygon inside the Recog.mom marker counts as a device port, and it needs exactly two. The marker spans the whole device including the bus connections, so a pin dropped on a bus is counted on top of the two MkPins the PCell already draws. At four ports the device is not extracted, and if it was the only device in the cell the layout netlist comes out empty.
```Symptom:``` `cap_cmomi: expected exactly 2 port regions under the Recog.mom marker, found 4` in the KLayout log, then `Errors encountered during netlist extraction` and an empty `.SUBCKT`.
```Workaround:``` Run a short metal stub out past the Recog.mom boundary and put the pin and its label on the stub. Moving only the label does nothing, it is the pin polygon that gets counted.
