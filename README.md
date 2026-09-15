# Open-PDKs Regression Tests for DRC / LVS / PEX

(c) 2026 Julian Schwarz and Simon Dorrer

Institute for Integrated Circuits and Quantum Computing, Johannes Kepler University (JKU), Linz, Austria

> [!WARNING]
> This repository is a Work in Progress.

## Description

Files for DRC / LVS / PEX regression tests for the Open-PDKs ihp-sg13g2, ihp-sg13cmos5l, gf180mcuD and sky130A.

| PDK | DRC / LVS / PEX regression | PEX bench |
|---|---|---|
| ihp-sg13g2 | yes | yes |
| ihp-sg13cmos5l | yes | yes, Magic only for now (see its README) |
| gf180mcuD | yes | yes |
| sky130A | coming soon | yes |

The PEX bench in each `<pdk>/pex_bench/` is a set of metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand, extracted with Magic and kpex and checked against pinned values. [ihp-sg13g2/pex_bench/README.md](ihp-sg13g2/pex_bench/README.md) describes how it was built and what it found.
