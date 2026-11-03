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
CELL ?= gf180_nfet_03v3_tap

# The gf180mcuD KLayout LVS wrapper writes <cell>.cir, not <cell>_extracted.cir
# like the IHP wrappers do (libs.tech/klayout/tech/lvs/run_lvs.py:347).
KLAYOUT_EXT_CIR = $(CELL).cir

# Steps of regression that do not simply pass. ../common.mk has the entry syntax and what
# each outcome is reported as.
#   KNOWN_FAILS         tool bug: the step fails although it should pass (KNOWN_ISSUES.md)
#   EXPECTED_FAILS      the cell is broken on purpose, the step has to fail (EXPECTED_FAILS.md)
#   KNOWN_FALSE_PASSES  the cell is broken on purpose, but a tool bug lets the step pass
#                       (KNOWN_ISSUES.md)
KNOWN_FAILS ?= gf180_nfet_03v3_tap_nostrap:klayout-lvs gf180_cap_nmos_03v3_nofmt:klayout-lvs \
	gf180_diode_dw2ps:klayout-lvs gf180_diode_pw2dw:klayout-lvs gf180_sc_diode:klayout-lvs \
	gf180_combined_cmim_ontop:klayout-lvs \
	gf180_cap_pmos_03v3_b:magic-lvs gf180_cap_pmos_06v0_b:magic-lvs gf180_nfet_03v3_tap_poly2pin:magic-lvs \
	gf180_diode_nw2ps_03v3:magic-lvs gf180_diode_nw2ps_06v0:magic-lvs \
	gf180_diode_dw2ps:magic-lvs gf180_diode_pw2dw:magic-lvs gf180_sc_diode:magic-lvs \
	gf180_nplus_s:magic-lvs gf180_pplus_s:magic-lvs gf180_nwell:magic-lvs gf180_rm1:magic-lvs \
	gf180_rm2:magic-lvs gf180_rm3:magic-lvs \
	gf180_pnp_05p00x00p42:magic-lvs gf180_pnp_05p00x05p00:magic-lvs gf180_pnp_10p00x10p00:magic-lvs \
	gf180_cap_nmos_03v3:magic-drc gf180_cap_nmos_03v3_nofmt:magic-drc gf180_cap_nmos_06v0:magic-drc \
	gf180_cap_pmos_03v3:magic-drc gf180_cap_pmos_06v0:magic-drc \
	gf180_diode_dw2ps:magic-drc gf180_diode_pw2dw:magic-drc gf180_nfet_03v3_mintap:magic-drc \
	gf180_dnwell_nmos:magic-drc gf180_dnwell_inv:magic-drc gf180_nfet_03v3_ring_cogap:magic-drc \
	gf180_npn_00p54x02p00:magic-drc gf180_npn_00p54x04p00:magic-drc gf180_npn_00p54x08p00:magic-drc \
	gf180_npn_00p54x16p00:magic-drc gf180_npn_05p00x05p00:magic-drc gf180_npn_10p00x10p00:magic-drc \
	gf180_pnp_05p00x00p42:magic-drc gf180_pnp_05p00x05p00:magic-drc \
	gf180_pnp_10p00x00p42:magic-drc gf180_pnp_10p00x10p00:magic-drc \
	gf180_sc_diode:magic-drc gf180_combined:magic-drc gf180_combined_cmim_ontop:magic-drc \
	gf180_nplus_s:magic-pex3 gf180_nplus_s:klayout-pex3 gf180_pplus_s:magic-pex3 gf180_pplus_s:klayout-pex3 \
	gf180_nwell:magic-pex3 gf180_nwell:klayout-pex3 gf180_rm1:magic-pex3 gf180_rm1:klayout-pex3 \
	gf180_dnwell_nmos:magic-pex3 gf180_dnwell_nmos:klayout-pex3 \
	gf180_dnwell_inv:magic-pex3 gf180_dnwell_inv:klayout-pex3 \
	gf180_npn_00p54x02p00:magic-pex3 gf180_npn_00p54x02p00:klayout-pex3 \
	gf180_npn_00p54x08p00:magic-pex3 gf180_npn_00p54x08p00:klayout-pex3 \
	gf180_npn_00p54x16p00:magic-pex3 gf180_npn_00p54x16p00:klayout-pex3 \
	gf180_npn_05p00x05p00:magic-pex3 gf180_npn_05p00x05p00:klayout-pex3 \
	gf180_npn_00p54x04p00:magic-pex3 gf180_npn_00p54x04p00:klayout-pex3 \
	gf180_npn_10p00x10p00:magic-pex3 gf180_npn_10p00x10p00:klayout-pex3 \
	gf180_combined:magic-pex3 gf180_combined:klayout-pex3 \
	gf180_combined_cmim_ontop:magic-pex3 gf180_combined_cmim_ontop:klayout-pex3
EXPECTED_FAILS ?= gf180_nfet_06v0_nvt_ring_nat:klayout-drc
KNOWN_FALSE_PASSES ?= gf180_nfet_06v0_nvt_ring_nat:magic-drc \
	gf180_cap_mim_2f0fF_via3:klayout-drc gf180_cap_mim_2f0fF_via3:magic-drc

include $(MAKEFILE_DIR)/../common.mk

# PEX bench: dummy metal layouts with hand-computable parasitics, extracted with Magic and the
# kpex engines and checked against expected values. Everything else lives in pex_bench/Makefile.
FASTERCAP ?= 0

pex-bench: ## Run the PEX bench, Magic and kpex 2.5D against expected values (usage: make pex-bench [FASTERCAP=1])
	$(MAKE) -C $(MAKEFILE_DIR)/pex_bench pex-bench FASTERCAP=$(FASTERCAP)
.PHONY: pex-bench
