# sky130A regression design: PDK selection and known failures.
# Every target lives in ../common.mk - run with "make <target>" from this directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# PDK this design is verified against. common.mk switches the environment to it
# via sak-pdk, so make in here can never verify against another PDK.
EXPECTED_PDK := sky130A

# Cell name for the single-cell targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= sky130_nfet_01v8_tap

# Steps of regression that do not simply pass. ../common.mk has the entry syntax and what
# each outcome is reported as.
#   KNOWN_FAILS         tool bug: the step fails although it should pass (KNOWN_ISSUES.md)
#   EXPECTED_FAILS      the cell is broken on purpose, the step has to fail (EXPECTED_FAILS.md)
#   KNOWN_FALSE_PASSES  the cell is broken on purpose, but a tool bug lets the step pass
#                       (KNOWN_ISSUES.md)
KNOWN_FAILS ?=
EXPECTED_FAILS ?=
KNOWN_FALSE_PASSES ?=

include $(MAKEFILE_DIR)/../common.mk

# KLayout LVS is left out of regression: the sky130.lvs deck needs two switches for the Xschem
# netlists that sak-lvs.sh does not pass, so it fails on every cell (README.md, FINDINGS.md).
# make klayout-lvs still runs it on one cell.
REGRESSION_STEPS := $(filter-out klayout-lvs,$(REGRESSION_STEPS))

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# kpex engines and checked against expected values. Everything else lives in pex_bench/Makefile.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench, Magic and kpex 2.5D against expected values (usage: make pex-bench [FASTERCAP=1])
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench
