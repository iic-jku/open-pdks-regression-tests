# Known Issues

## Magic + Netgen LVS fails on sg13_cmomi (`cmomi`)

The following test fails Magic+Netgen LVS:

- `sg13_cmomi` — new interdigitated fringe capacitance (MOM Cap) - not extracted by LVS

**KLayout LVS passes on every cell**. Only Magic+Netgen LVS is affected.

See issue: https://github.com/RTimothyEdwards/magic/issues/552
