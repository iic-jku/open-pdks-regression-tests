# ihp-sg13g2 regression design: PDK selection and known failures.
# Every target lives in ../common.mk - run with "make <target>" from this directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# PDK this design is verified against. Checked against the environment, so
# "sak-pdk <other>" plus make in here is an error instead of a wrong result.
EXPECTED_PDK := ihp-sg13g2

# Cell name for the single-cell targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= sg13_lv_nmos_tap

# Known failures: tolerated by regression. See ../common.mk for the entry syntax.
# A listed step that passes is reported as UNEXPECTED PASS and fails the regression.
KNOWN_FAILS ?= sg13_combined:magic-lvs \
			sg13_rf_cmim:magic-lvs \
			sg13_combined_cmim_ontop:magic-lvs \
			sg13_cmomi:magic-lvs

include $(MAKEFILE_DIR)/../common.mk
