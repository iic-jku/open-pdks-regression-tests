# Makefile for the IIC Open-PDK regression tests.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))


.DEFAULT_GOAL := help

# Cell name for verification targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= sg13_lv_nmos_tap

# Floating-point precision (significant digits) for Xschem's ev function
# Override with: make <target> EV_PRECISION=<digits>
EV_PRECISION ?= 5

EXT_MODE ?= 3

# Folder structure
XSCHEM_SCH_DIR  := schematic/xschem
LAY_DIR         := layout
NET_SCH_DIR     := netlist/schematic
NET_LAY_DIR     := netlist/layout
NET_PEX_DIR		:= netlist/pex
LVS_RPT_DIR     := verification/lvs
DRC_RPT_DIR     := verification/drc

# Auto-discovered cells from all .gds files in $(LAY_DIR)/
LAYOUT_CELLS := $(patsubst $(LAY_DIR)/%.gds,%,$(wildcard $(LAY_DIR)/*.gds))


# Help Target
help: ## Show this help message
	@echo 'Usage: make <target> [CELL=<cellname>] [EV_PRECISION=<digits>] [VERSION=<version>]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z0-9_.-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'CELL defaults to $(CELL). Override to verify subcells.'
	@echo 'EV_PRECISION defaults to 5 significant digits for Xschem ev function.'
.PHONY: help
# ================================================================================================

# LVS-Netlist Targets
klayout-lvs-netlist: ## Export CDL schematic netlist from Xschem for KLayout LVS (usage: make klayout-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(XSCHEM_SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 1; \
		set top_is_subckt 1; \
		set lvs_ignore 0; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_klayout.cdl; \
		xschem netlist \
	' $(XSCHEM_SCH_DIR)/$(CELL).sch
.PHONY: klayout-lvs-netlist

magic-lvs-netlist: ## Export SPICE schematic netlist from Xschem for Magic + Netgen LVS (usage: make magic-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(XSCHEM_SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 0; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_magic.spice; \
		xschem netlist \
	' $(XSCHEM_SCH_DIR)/$(CELL).sch
.PHONY: magic-lvs-netlist
# ================================================================================================

# LVS Targets
klayout-lvs: ## Run KLayout LVS of the CELL cell (usage: make klayout-lvs [CELL=<cellname>])
	$(MAKE) klayout-lvs-netlist CELL=$(CELL)
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	python3 $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/run_lvs.py \
		--layout=$(LAY_DIR)/$(CELL).gds \
		--netlist=$(NET_SCH_DIR)/$(CELL)_klayout.cdl \
		--topcell=$(CELL) \
		--run_dir=$(LVS_RPT_DIR) \
		--run_mode=deep
	mv $(LVS_RPT_DIR)/$(CELL)_extracted.cir $(NET_LAY_DIR)/$(CELL)_klayout.cir
	@grep -q "Comparison mode: PASS (netlists match)" $$(ls -t $(LVS_RPT_DIR)/lvs_run_*.log 2>/dev/null | head -1) 2>/dev/null || exit 1
.PHONY: klayout-lvs

magic-lvs: ## Run Magic + Netgen LVS of the CELL cell (usage: make magic-lvs [CELL=<cellname>])
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(MAKE) magic-lvs-netlist CELL=$(CELL)
	./sak-lvs.sh -d -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_magic.spice -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	mv $(LVS_RPT_DIR)/$(CELL).ext.spc $(NET_LAY_DIR)/$(CELL)_magic.ext.spc
	rm -f $(LVS_RPT_DIR)/$(CELL).sch.spc
	rm -f $(LVS_RPT_DIR)/ext_$(CELL).tcl
	rm -f $(LVS_RPT_DIR)/*.ext
.PHONY: magic-lvs
# ================================================================================================

# DRC Targets
klayout-drc: ## Run KLayout DRC of the CELL cell (usage: make klayout-drc [CELL=<cellname>])
	mkdir -p $(DRC_RPT_DIR)
	python3 $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py \
		--path=$(LAY_DIR)/$(CELL).gds \
		--topcell=$(CELL) \
		--run_dir=$(DRC_RPT_DIR) \
		--no_feol \
		--no_density \
		--disable_extra_rules \
		--mp=32 \
		--density_thr=32
	@grep -q "KLayout DRC Check Passed: No DRC violations detected in the layout" $$(ls -t $(DRC_RPT_DIR)/drc_run_*.log 2>/dev/null | head -1) 2>/dev/null || exit 1
.PHONY: klayout-drc

magic-drc: ## Run Magic DRC of the CELL cell (usage: make magic-drc [CELL=<cellname>])
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -m -f "*" -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds $(CELL)
	rm -f $(DRC_RPT_DIR)/drc_$(CELL).tcl
.PHONY: magic-drc
# ================================================================================================

# PEX Targets
klayout-pex: ## Run Parasitic Extraction with KPEX of the CELL cell (usage: make klayout-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>])
	mkdir -p $(NET_PEX_DIR)
	PDK_UNDERSCORED=$$(echo $$PDK | sed -e 's/-/_/g'); \
	case $(EXT_MODE) in \
		1) echo "WARNING: KPEX does not support C-decoupled (C) mode yet, using C-coupled (CC) mode instead."; KPEX_MODE=CC ;; \
		2) KPEX_MODE=CC ;; \
		3) KPEX_MODE=RC ;; \
		*) echo "Invalid EXT_MODE: $(EXT_MODE). Use 1, 2, or 3."; exit 1;; \
	esac; \
	kpex \
	--pdk $$PDK_UNDERSCORED \
	--cell $(CELL) \
	--schematic $(XSCHEM_SCH_DIR)/$(CELL).sch \
	--gds $(LAY_DIR)/$(CELL).gds \
	--magic \
	--magic_mode $$KPEX_MODE \
	--out_dir $(NET_PEX_DIR) \
	--out_spice $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
#	--2.5D
#	--mode $$KPEX_MODE
	sed -i 's/$(CELL)/$(CELL)_pex/g' $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
	rm -rf $(NET_PEX_DIR)/$(CELL)__$(CELL)
	rm -f $(CELL).nodes $(CELL).sim
.PHONY: klayout-pex

magic-pex: ## Run Parasitic Extraction with Magic of the CELL cell (usage: make magic-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>])
	mkdir -p $(NET_PEX_DIR)
	sak-pex.sh -d -m $(EXT_MODE) -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	sed -i 's/$(CELL)/$(CELL)_pex/g' $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	rm -f $(NET_PEX_DIR)/pex_$(CELL).tcl $(NET_PEX_DIR)/$(CELL).ext $(NET_PEX_DIR)/$(CELL).res.ext
.PHONY: magic-pex

regression: ## Run full verify (klayout-verify + magic-verify) for every .gds in $(LAY_DIR)/
	rm -rf netlist
	rm -rf verification
	@failed=""; \
	for cell in $(LAYOUT_CELLS); do \
		echo "[REGRESSION] Running verify for: $$cell"; \
		cell_tools=""; \
		$(MAKE) klayout-lvs CELL=$$cell || cell_tools="$${cell_tools:+$$cell_tools, }KLAYOUT-LVS"; \
		$(MAKE) klayout-drc CELL=$$cell || cell_tools="$${cell_tools:+$$cell_tools, }KLAYOUT-DRC"; \
		$(MAKE) klayout-pex CELL=$$cell EXT_MODE=1|| cell_tools="$${cell_tools:+$$cell_tools, }KLAYOUT-PEX_EXT_MODE_1"; \
		$(MAKE) klayout-pex CELL=$$cell EXT_MODE=2|| cell_tools="$${cell_tools:+$$cell_tools, }KLAYOUT-PEX_EXT_MODE_2"; \
		$(MAKE) klayout-pex CELL=$$cell EXT_MODE=3|| cell_tools="$${cell_tools:+$$cell_tools, }KLAYOUT-PEX_EXT_MODE_3"; \
		$(MAKE) magic-lvs CELL=$$cell || cell_tools="$${cell_tools:+$$cell_tools, }MAGIC-LVS"; \
		$(MAKE) magic-drc CELL=$$cell || cell_tools="$${cell_tools:+$$cell_tools, }MAGIC-DRC"; \
		$(MAKE) magic-pex CELL=$$cell EXT_MODE=1|| cell_tools="$${cell_tools:+$$cell_tools, }MAGIC-PEX_EXT_MODE_1"; \
		$(MAKE) magic-pex CELL=$$cell EXT_MODE=2|| cell_tools="$${cell_tools:+$$cell_tools, }MAGIC-PEX_EXT_MODE_2"; \
		$(MAKE) magic-pex CELL=$$cell EXT_MODE=3|| cell_tools="$${cell_tools:+$$cell_tools, }MAGIC-PEX_EXT_MODE_3"; \
		if [ -n "$$cell_tools" ]; then \
			echo "[REGRESSION] FAILED: $$cell ($$cell_tools)"; \
			failed="$$failed $$cell($$cell_tools)"; \
		else \
			echo "[REGRESSION] PASSED: $$cell"; \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	if [ -n "$$failed" ]; then \
		echo "[REGRESSION] SUMMARY: FAILED cells:$$failed"; \
		echo "========================================"; \
		exit 1; \
	else \
		echo "[REGRESSION] SUMMARY: All cells PASSED"; \
		echo "========================================"; \
	fi
.PHONY: regression