# Known Issues

## Magic + Netgen LVS fails on RF C-MIM (`cap_rfcmim`)

The following three tests fail Magic+Netgen LVS:

- `sg13_rf_cmim` — the RF C-MIM device itself
- `sg13_combined` — instantiates the RF C-MIM
- `sg13_combined_cmim_ontop` — instantiates the RF C-MIM

The `_wo_rfcmim` variants and the regular `sg13_cmim` all pass, and **KLayout LVS passes on every cell**. Only Magic+Netgen LVS is affected.

See issue: https://github.com/IHP-GmbH/IHP-Open-PDK/issues/1008