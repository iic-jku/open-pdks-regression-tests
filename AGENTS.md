# Repository conventions

Guidance for coding agents and contributors working in this repo (DRC / LVS / PEX regression tests for the open-source PDKs `ihp-sg13g2`, `ihp-sg13cmos5l`, `gf180mcuD`, and `sky130A`).

## What this repo tests

The tests check the tools and the PDK decks, not a design. The cells under `<pdk>/layout/` and `<pdk>/schematic/xschem/` are the test input. Never change a cell to make a step pass: a failing step is either a tool or PDK bug (`KNOWN_FAILS`), a cell broken on purpose (`EXPECTED_FAILS`), a real regression to report, or a drawing error in a cell meant to be clean. Only a drawing error is fixed in the cell, with the rule and the measured values in the commit message.

## Environment

- Run every target inside the IIC-OSIC-TOOLS container (https://github.com/iic-jku/IIC-OSIC-TOOLS), tag `2026.11` or later (`README.md`). CI uses `ghcr.io/iic-jku/iic-osic-tools:nightly`, and the lists in the Makefiles follow that image.
- Each PDK folder switches the shell to its own PDK (`EXPECTED_PDK`) with `sak-pdk-script.sh` when make parses its `Makefile`, so the PDK of the container does not matter. `PDK_ROOT` must be set.
- Run make inside the folder or with `make -C <pdk> <target>`. `make -f <pdk>/Makefile` resolves the relative paths against the current directory and does not work.

## Repository layout

| Path | Contents |
| --- | --- |
| `common.mk` | Every target (DRC, LVS, PEX, regression, clean), included by the `Makefile` of each PDK folder and of each `pex_bench/` |
| `scripts/` | `check_pex_ports.py` (run after every extraction) and `check_pex_modes.py` (after every full-RC extraction), `make_fastercap_expected.sh` (FasterCap references of the benches) |
| `<pdk>/Makefile` | `EXPECTED_PDK`, the default `CELL`, the lists `KNOWN_FAILS`, `EXPECTED_FAILS`, `KNOWN_FALSE_PASSES`, and the `pex-bench` targets that forward to `pex_bench/` |
| `<pdk>/README.md` | Every target, the regression rules, and the status of every cell ("Supported Cells") |
| `<pdk>/KNOWN_ISSUES.md`, `<pdk>/EXPECTED_FAILS.md`, `<pdk>/FINDINGS.md` | Why each list entry is there, what is broken in each cell broken on purpose, PDK pitfalls |
| `<pdk>/layout/`, `<pdk>/schematic/xschem/` | One GDS and one schematic per cell, with the same name, and the folder's `xschemrc` |
| `<pdk>/pex_bench/` | PEX bench: `Makefile`, generators in `scripts/`, generated `layout/`, `expected/` results, and for `ihp-sg13g2` the `report/` |
| `doc/fig/` | Figures of the root `README.md` (layout renders, the hand-written SVG of the regression flow, funding logos) |
| `.github/workflows/` | `regression-<pdk>.yml` per PDK on top of `regression-common.yml`, `license-check.yml` |

## Makefiles

- `common.mk` holds every target. A PDK `Makefile` only sets variables, includes it, and forwards `pex-bench` and `clean-all` to `pex_bench/`. Change a flow in `common.mk`, never copy a target into a PDK folder.
- `.DEFAULT_GOAL := help`, and `make help` lists every target from its `## ` comment. Give every new target a `## ` comment.
- Variables are set with `?=` and overridden on the command line, for example `CELL=<cell>`, `EXT_MODE=<1|2|3>`, `CTHRESH=<fF>`, `DRC_LEVEL=<precheck|macro|regular>`, `DRC_JOBS=<n>`, `GDSCHECK_SUITE=<suite>`, `KPEX_REDUCE=<none|floating|ticer>`, `PEX_SUB_NET=<net>`, `STEPS=<pattern>`, `LAYOUT_CELLS="<cell> ..."`. `SAK_DRC`, `SAK_LVS` and `SAK_PEX` point every target of `common.mk` at another copy of a sak script, for example the one of an open IIC-OSIC-TOOLS pull request.
- The DRC engines are KLayout (`klayout-drc`, the sign-off deck), Magic (`magic-drc`) and gdscheck (`gdscheck-drc`). gdscheck has rule decks for `ihp-sg13g2`, `ihp-sg13cmos5l` and `gf180mcuD` only, so `sky130A/Makefile` sets `GDSCHECK_STEP` empty and its regression leaves the step out.
- `klayout-pex` runs the kpex 2.5D engine through `sak-pex.sh -k` and passes no schematic (`-S`): kpex's device check would fail the full-RC step of every cell broken on purpose, and PEX steps may not be in `EXPECTED_FAILS`.
- `make regression` discovers the cells from `layout/*.gds`. A new cell needs a GDS and a schematic of the same name, nothing else.

## Regression lists

- `KNOWN_FAILS` lists steps that fail because of a tool or PDK bug, each with a section in `KNOWN_ISSUES.md`. `EXPECTED_FAILS` lists the DRC and LVS steps of cells broken on purpose, each with a section in `EXPECTED_FAILS.md`. `KNOWN_FALSE_PASSES` lists the DRC and LVS steps that miss a deliberate error because of a bug, each with a section in `KNOWN_ISSUES.md`.
- An entry is `<cell>:<step>` or `<cell>`. A step may be in one list only, and PEX steps may only be in `KNOWN_FAILS`. The regression refuses to run otherwise.
- When an upstream fix turns an entry into an UNEXPECTED PASS, remove the entry and its section in the same commit, update the cell status in the folder `README.md`, and name the fixing version in the commit message, for example "Drop the MIM.e known fails, fixed in Magic 8.3.700".
- Every list change also updates the status of the cell in "Supported Cells" of the folder `README.md`.

## PEX bench

- The layouts in `pex_bench/layout/` are written by `pex_bench/scripts/gen_*.py`. Change the generator, run `make -C <pdk>/pex_bench layouts`, and confirm with `make -C <pdk>/pex_bench layouts-check`. Never edit a bench GDS by hand.
- `gen_hier.py` copies the inverter from the standard-cell library of the PDK, so `layouts-check` also reports a difference when the PDK changes that cell.
- `pex_bench/expected/results.json` is the reference of `make pex-bench`. `make -C <pdk>/pex_bench pex-bench-expected` overwrites it. Re-bless only after a deliberate change or an understood tool change, and name the tool version in the commit message, for example "PEX bench: re-bless kpex 2.5D for kpex 0.9.0".
- `FASTERCAP=1` adds the FasterCap field solve, which takes minutes. `scripts/make_fastercap_expected.sh` produces the converged references in `expected/fastercap/` and belongs on a large machine.

## CI

- `.github/workflows/license-check.yml` runs `reuse lint` on pushes and pull requests to `main`.
- `.github/workflows/regression-<pdk>.yml` (one per PDK, for one badge each) call `regression-common.yml`, which runs `make regression` and then `make pex-bench` of that PDK in `ghcr.io/iic-jku/iic-osic-tools:nightly`. They run on pushes and pull requests to `main` that touch more than documentation (`**.md`, `doc/**`), and on manual dispatch with an `image` input. There is no schedule: the IIC-OSIC-TOOLS test every nightly image against `main` with tests 26, 31, 35, 47, and 48, so a tool regression shows up there, and the lists here are updated in a commit that these workflows then check.
- A new PDK folder needs its own `regression-<pdk>.yml` and its badge in the root `README.md` (badge row and PDK table).

## Traps

- Generated output (`<pdk>/netlist/`, `<pdk>/verification/`, `pex_bench/netlist/`, `pex_bench/runs/`) is git-ignored. `make clean` deletes the first two, `make -C <pdk>/pex_bench pex-bench-clean` the bench outputs, and `make clean-all` both.
- The root `README.md` states the number of cells and bench layouts per PDK. Update it when adding or removing a cell.
- The PDK folders are also run by IIC-OSIC-TOOLS tests 26 (`ihp-sg13g2`), 31 (`ihp-sg13cmos5l`), 47 (`gf180mcuD`) and 48 (`sky130A`), and all bench folders by test 35. Renaming a target or a folder breaks those tests.

## License headers

The repo is licensed under Apache-2.0 (`LICENSE`), and `reuse lint` must pass.

- Scripts and Makefiles start with this header, below the shebang if there is one:

  ```
  # SPDX-FileCopyrightText: 2026 Julian Schwarz, Simon Dorrer, and Harald Pretl
  # Johannes Kepler University, Department for Integrated Circuits
  # SPDX-License-Identifier: Apache-2.0
  ```

- Workflows carry the two SPDX lines and a `# Description:` line.
- Layouts, schematics, documentation, expected results, and figures carry no header. `REUSE.toml` covers them by path. A new file in a path no annotation covers fails `reuse lint`, so extend `REUSE.toml` in the same change.
- The inverters copied from the PDK libraries (`pex_bench/layout/*_inv_1.gds`, also inside `hier_test.gds`) keep their original copyright holders in `REUSE.toml`.

## Writing style

These rules apply to documentation, code comments, commit messages, and pull request descriptions in this repo.

- No em-dashes, no double-hyphen dashes, and no semicolons in prose. Code is exempt. Use commas, colons, periods, or parentheses, and split long sentences instead.
- Plain, factual tone: numbers, paths, tool versions, and verdicts over adjectives, no filler.
- Never hard-wrap prose at a fixed column. Put each sentence or paragraph on one line and let the editor wrap it. When editing, never reflow neighboring lines.
- Keep comments short and accurate: say what is non-obvious and why, never restate what the code already shows.
- Commit subjects are imperative and start with the folder or area they touch when there is one, for example `gf180mcuD: ...`, `common.mk: ...`, `PEX bench: ...`.
