# Known Issues
See issue: https://github.com/IHP-GmbH/ihp-sg13cmos5l/issues/91

## Known Failing Cells

- `sg13_cmomi` — interdigitated fringe capacitance MOM Cap - does not get extracted from the layout
- `sg13_combined` — yet to be found MAGIC+Netgen issue

## Guard Rings currently not working
LVS-Fail expected for any cell that uses a guard ring (tap_ring)
