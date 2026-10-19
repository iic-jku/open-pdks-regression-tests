# Known Issues

Every entry of `KNOWN_FAILS` and `KNOWN_FALSE_PASSES` in the [Makefile](Makefile) has a section here. Remove both once the tool is fixed: the regression then reports the step as `UNEXPECTED PASS` (a known fail that passes) or `UNEXPECTED FAIL` (a known false pass that catches the error now) and fails.

KLayout DRC and LVS and Magic DRC pass on every cell that is not broken on purpose. Only Magic + Netgen LVS is affected.

## Magic + Netgen LVS fails on `sg13_cmomi`

`KNOWN_FAILS` entry: `sg13_cmomi:magic-lvs`

Magic does not extract the interdigitated MOM capacitor (`cap_cmomi`) from the layout.

Upstream: [magic#552](https://github.com/RTimothyEdwards/magic/issues/552)
