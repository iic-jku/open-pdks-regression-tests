# ihp-sg13cmos5l regression design: PDK selection and known failures.
# Every target lives in ../common.mk - run with "make <target>" from this directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# PDK this design is verified against. common.mk switches the environment to it
# via sak-pdk, so make in here can never verify against another PDK.
EXPECTED_PDK := ihp-sg13cmos5l

# Cell name for the single-cell targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= sg13_combined

# Steps of regression that do not simply pass. ../common.mk has the entry syntax and what
# each outcome is reported as.
#   KNOWN_FAILS         tool bug: the step fails although it should pass (KNOWN_ISSUES.md)
#   EXPECTED_FAILS      the cell is broken on purpose, the step has to fail (EXPECTED_FAILS.md)
#   KNOWN_FALSE_PASSES  the cell is broken on purpose, but a tool bug lets the step pass
#                       (KNOWN_ISSUES.md)
KNOWN_FAILS ?= sg13_cmomi:magic-lvs
EXPECTED_FAILS ?= sg13_lv_nmos_tap_m1_a:klayout-drc sg13_lv_nmos_tap_m1_a:magic-drc \
	sg13_lv_nmos_tap_m1_b:klayout-drc sg13_lv_nmos_tap_m1_b:magic-drc \
	sg13_lv_nmos_tap_cnt_c:klayout-drc sg13_lv_nmos_tap_cnt_c:magic-drc \
	sg13_lv_nmos_tap_cnt_c_ptap:klayout-drc \
	sg13_lv_nmos_tap_gat_c:magic-drc \
	sg13_lv_nmos_tap_short_ds:klayout-lvs sg13_lv_nmos_tap_short_ds:magic-lvs \
	sg13_lv_nmos_tap_open_g:klayout-lvs sg13_lv_nmos_tap_open_g:magic-lvs \
	sg13_lv_nmos_tap_w_mismatch:klayout-lvs
KNOWN_FALSE_PASSES ?= sg13_lv_nmos_tap_cnt_c_ptap:magic-drc sg13_lv_nmos_tap_w_mismatch:magic-lvs

include $(MAKEFILE_DIR)/../common.mk

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# engines listed in pex_bench/Makefile (PEX_ENGINES) and checked against expected values.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench with the engines in pex_bench PEX_ENGINES against expected values (usage: make pex-bench)
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench
