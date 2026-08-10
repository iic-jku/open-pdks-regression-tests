# Known Issues
See issue: https://github.com/IHP-GmbH/ihp-sg13cmos5l/issues/91

## Magic + Netgen LVS fails on RF C-MIM (`cap_rfcmim`)
The following tests fail Magic+Netgen LVS:

- `sg13_cap_mfringe` — fringe capacitance MOM Cap - magic does not extract it from the layout
- `sg13_combined` — instantiates the RF C-MIM

**KLayout LVS passes on every cell**. Only Magic+Netgen LVS is affected.

[REGRESSION] SUMMARY: FAILED cells: 
cap_cmomi_1(klayout-lvs magic-lvs) -- simply not extracted by lvs
cap_cmomi(klayout-lvs magic-lvs) 
mom_test.klay(klayout-lvs magic-lvs magic-pex1 magic-pex2 magic-pex3) 
sg13_cap_mfringe(klayout-lvs magic-lvs) -- deleted upstream, will return but this file was deleted
sg13_combined(magic-lvs)
