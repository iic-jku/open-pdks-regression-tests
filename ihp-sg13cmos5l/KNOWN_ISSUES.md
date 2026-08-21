# Known Issues
See issue: https://github.com/IHP-GmbH/ihp-sg13cmos5l/issues/91

## Magic + Netgen LVS fails on sg13_cmomi (`cmomi`)

The following test fails Magic+Netgen LVS:

- `sg13_cmomi` — interdigitated fringe capacitance MOM Cap - does not get extracted from the layout
- `sg13_combined` — yet to be found MAGIC+Netgen issue

**KLayout LVS passes on every cell**. Only Magic+Netgen LVS is affected.

See issue: https://github.com/RTimothyEdwards/magic/issues/552 regarding sg13_cmomi
