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

# Known failures: tolerated by regression. See ../common.mk for the entry syntax.
# A listed step that passes is reported as UNEXPECTED PASS and fails the regression.
KNOWN_FAILS ?= sg13_cmomi:magic-lvs

include $(MAKEFILE_DIR)/../common.mk

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# engines listed in pex_bench/Makefile (PEX_ENGINES) and checked against expected values.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench with the engines in pex_bench PEX_ENGINES against expected values (usage: make pex-bench)
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench
