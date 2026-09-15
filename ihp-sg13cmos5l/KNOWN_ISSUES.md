# Known Issues

Every entry of `KNOWN_FAILS` in the [Makefile](Makefile) has a section here. Remove both once the step passes: the regression reports a listed step that passes as `UNEXPECTED PASS` and fails.

KLayout LVS passes on every cell. Only Magic + Netgen LVS is affected.

## Magic + Netgen LVS fails on `sg13_cmomi`

`KNOWN_FAILS` entry: `sg13_cmomi:magic-lvs`

Magic does not extract the interdigitated MOM capacitor (`cap_cmomi`) from the layout.

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)
