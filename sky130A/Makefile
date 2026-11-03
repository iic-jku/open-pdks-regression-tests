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
KNOWN_FAILS ?= sky130_diode_pd2nw_05v5_lvt:magic-lvs sky130_diode_pd2nw_05v5_hvt:magic-lvs \
	sky130_diode_pd2nw_05v5_lvt:magic-drc sky130_diode_pd2nw_05v5_hvt:magic-drc \
	sky130_npn_11v0_W1p00L1p00:magic-lvs sky130_npn_11v0_W1p00L1p00:magic-drc \
	sky130_cap_vpp_11p5x11p7_m1m2m3m4_shieldl1m5:magic-lvs sky130_cap_vpp_11p5x11p7_m1m2_noshield:magic-lvs \
	sky130_cap_vpp_08p6x07p8_m1m2_shieldl1:magic-lvs sky130_cap_vpp_04p4x04p6_m1m2_shieldl1:magic-lvs \
	sky130_photodiode:klayout-drc sky130_photodiode:magic-drc sky130_photodiode:magic-lvs \
	sky130_pnp_05v5_W3p40L3p40:magic-pex3 sky130_pnp_05v5_W3p40L3p40:klayout-pex3 \
	sky130_pfet_01v8_ring_pcell:magic-drc sky130_pfet_01v8_ring_pcell:magic-lvs \
	sky130_pfet_01v8_lvt_ring_pcell:magic-drc sky130_pfet_01v8_lvt_ring_pcell:magic-lvs \
	sky130_pfet_01v8_hvt_ring_pcell:magic-drc sky130_pfet_01v8_hvt_ring_pcell:magic-lvs \
	sky130_pfet_g5v0d10v5_ring_pcell:magic-drc sky130_pfet_g5v0d10v5_ring_pcell:magic-lvs \
	sky130_cap_var_lvt:magic-lvs sky130_cap_var_hvt:magic-lvs sky130_cap_var_hvt_varac5:magic-lvs \
	sky130_res_high_po_0p35:magic-drc sky130_res_high_po_0p69:magic-drc \
	sky130_res_xhigh_po_0p35:magic-drc sky130_res_xhigh_po_0p69:magic-drc sky130_combined:magic-drc \
	sky130_pfet_g5v0d16v0:magic-drc
EXPECTED_FAILS ?= sky130_nfet_05v0_nvt_tap_hvdifftap16:magic-drc sky130_diode_pd2nw_05v5_psd8:magic-drc
KNOWN_FALSE_PASSES ?= sky130_nfet_05v0_nvt_tap_hvdifftap16:klayout-drc sky130_diode_pd2nw_05v5_psd8:klayout-drc \
	sky130_cap_var_hvt_varac5:klayout-drc sky130_cap_var_hvt_varac5:magic-drc \
	sky130_nfet_01v8_tap_licon15:klayout-drc sky130_nfet_01v8_tap_licon15:magic-drc

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
