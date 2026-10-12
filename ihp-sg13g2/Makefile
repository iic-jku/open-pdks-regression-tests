# ihp-sg13g2 regression design: PDK selection and known failures.
# Every target lives in ../common.mk - run with "make <target>" from this directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# PDK this design is verified against. common.mk switches the environment to it
# via sak-pdk, so make in here can never verify against another PDK.
EXPECTED_PDK := ihp-sg13g2

# Cell name for the single-cell targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= sg13_combined

# Steps of regression that do not simply pass. ../common.mk has the entry syntax and what
# each outcome is reported as.
#   KNOWN_FAILS         tool bug: the step fails although it should pass (KNOWN_ISSUES.md)
#   EXPECTED_FAILS      the cell is broken on purpose, the step has to fail (EXPECTED_FAILS.md)
#   KNOWN_FALSE_PASSES  the cell is broken on purpose, but a tool bug lets the step pass
#                       (KNOWN_ISSUES.md)
KNOWN_FAILS ?= sg13_cmomi:magic-lvs \
	sg13_cmim:magic-drc sg13_rf_cmim:magic-drc \
	sg13_combined:magic-drc sg13_combined_wo_rfcmim:magic-drc \
	sg13_combined_cmim_ontop:magic-drc sg13_combined_cmim_ontop_wo_rfcmim:magic-drc \
	sg13_hv_pmos_tap:magic-drc sg13_lv_pmos_tap:magic-drc sg13_short1:magic-drc \
	sg13_dnwell_inv:magic-drc sg13_dnwell_nmos:magic-drc
EXPECTED_FAILS ?= sg13_dnwell_inv_nmosi_c:magic-drc
KNOWN_FALSE_PASSES ?= sg13_dnwell_inv_nmosi_c:klayout-drc

include $(MAKEFILE_DIR)/../common.mk

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# kpex engines and checked against expected values. Everything else lives in pex_bench/Makefile.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench, Magic and kpex 2.5D against expected values (usage: make pex-bench [FASTERCAP=1])
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench

pex-bench-defects: ## Reproduce the six PEX defects of pex_bench/report on their smallest cases (usage: make pex-bench-defects)
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench-defects
.PHONY: pex-bench-defects
