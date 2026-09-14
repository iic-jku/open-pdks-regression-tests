# gf180mcuD regression design: PDK selection and known failures.
# Every target lives in ../common.mk - run with "make <target>" from this directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# PDK this design is verified against. common.mk switches the environment to it
# via sak-pdk, so make in here can never verify against another PDK.
EXPECTED_PDK := gf180mcuD

# Cell name for the single-cell targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= gf180_nfet_03v3

# The gf180mcuD KLayout LVS wrapper writes <cell>.cir, not <cell>_extracted.cir
# like the IHP wrappers do (libs.tech/klayout/tech/lvs/run_lvs.py:347).
KLAYOUT_EXT_CIR = $(CELL).cir

# Known failures: tolerated by regression. See ../common.mk for the entry syntax.
# A listed step that passes is reported as UNEXPECTED PASS and fails the regression.
KNOWN_FAILS ?=

include $(MAKEFILE_DIR)/../common.mk

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# kpex engines and checked against expected values. Everything else lives in pex_bench/Makefile.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench, Magic and kpex 2.5D against expected values (usage: make pex-bench [FASTERCAP=1])
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench
