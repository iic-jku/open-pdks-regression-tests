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
