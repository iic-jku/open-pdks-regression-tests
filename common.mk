# Shared DRC / LVS / PEX regression logic for the Open-PDK regression designs.
#
# Included by the per-PDK Makefile, which selects the PDK and lists that PDK's
# known failures. Always run it from the design directory:
#     cd <pdk-dir> && make <target>      or      make -C <pdk-dir> <target>
# "make -f <pdk-dir>/Makefile" does NOT work: the relative paths below would
# then resolve against the current directory instead of the design directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz and Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

.DEFAULT_GOAL := help

# ================================================================================================
# Settings the per-PDK Makefile defines before including this file:
#   EXPECTED_PDK      PDK this design is written for. common.mk switches the environment
#                     to it (see "PDK selection" below), so a design can never be
#                     silently verified against the wrong PDK.
#   CELL              Default cell for the single-cell targets.
#   KNOWN_FAILS       Tolerated failures, see below.
#   REGRESSION_STEPS  Steps the regression runs per cell (optional, default below).
#   KLAYOUT_EXT_CIR   Name of the extracted netlist (optional, see below).
#   MAGIC_EXT_SPC     Same for the Magic+Netgen flow (optional, see below).
# ================================================================================================

# ================================================================================================
# PDK selection
#
# The design has to be verified against EXPECTED_PDK, so common.mk selects that PDK itself
# instead of trusting the PDK the shell happens to have. sak-pdk stays the single source of
# truth: the blank call lists the installed PDKs, and "sak-pdk <pdk>" prints the variables of
# that PDK, which are imported here and exported to every recipe (PDK, PDKPATH,
# STD_CELL_LIBRARY, KLAYOUT_PATH, ...). A PDK that sak-pdk does not offer cannot be selected
# and is an error, reported by check-pdk.
#
# sak-pdk itself is a shell alias for "source sak-pdk-script.sh", and aliases do not exist in
# a make recipe, so the script is called directly. Its exit code is unusable (it ends on an
# optional test), a "PDK=" line in its output is what marks success.
# ================================================================================================

# PDK the environment had before common.mk switched it (empty if it was unset).
INCOMING_PDK := $(PDK)

SAK_PDK_SCRIPT := $(firstword $(shell command -v sak-pdk-script.sh 2>/dev/null) \
			/foss/tools/sak/sak-pdk-script.sh)

# Variables "sak-pdk <pdk>" prints and common.mk hands on to the tools.
SAK_PDK_VARS := PDK_ROOT PDK PDKPATH STD_CELL_LIBRARY SPICE_USERINIT_DIR \
			KLAYOUT_PATH KLAYOUT_PYTHONPATH GF_PDK_OPTION

# Empty once the PDK is selected, reason and hint otherwise. check-pdk turns them into an
# error, rather than $(error) right here, so that "make help" keeps working without the PDK.
# Always set both, and free of quotes: check-pdk echoes them unconditionally.
PDK_ERROR :=
PDK_ERROR_HINT :=

ifeq ($(EXPECTED_PDK),)
PDK_ERROR := EXPECTED_PDK is not set.
PDK_ERROR_HINT := The PDK Makefile has to define it before it includes common.mk.
else ifneq ($(INCOMING_PDK),$(EXPECTED_PDK))
# PDKs installed in $PDK_ROOT, from the "Available PDKs:" block of the blank sak-pdk call.
# That call lists every entry of $PDK_ROOT, files (versions.txt) included, so keep the
# entries that are directories.
AVAILABLE_PDKS := $(filter $(notdir $(patsubst %/,%,$(wildcard $(PDK_ROOT)/*/))),\
			$(shell $(SAK_PDK_SCRIPT) 2>/dev/null | sed -n '/^Available PDKs:/,$$p' | tail -n +2))
ifeq ($(filter $(EXPECTED_PDK),$(AVAILABLE_PDKS)),)
PDK_ERROR := This design needs PDK=$(EXPECTED_PDK), which sak-pdk does not offer.
PDK_ERROR_HINT := Available PDKs: $(if $(AVAILABLE_PDKS),$(AVAILABLE_PDKS),none at all - is $(SAK_PDK_SCRIPT) there, is PDK_ROOT set?)
else
SAK_PDK_ENV := $(shell $(SAK_PDK_SCRIPT) $(EXPECTED_PDK) 2>/dev/null)
$(foreach kv,$(SAK_PDK_ENV),\
			$(if $(filter $(SAK_PDK_VARS),$(firstword $(subst =, ,$(kv)))),$(eval export $(kv))))
ifneq ($(PDK),$(EXPECTED_PDK))
PDK_ERROR := sak-pdk did not switch to PDK=$(EXPECTED_PDK).
PDK_ERROR_HINT := $(SAK_PDK_SCRIPT) $(EXPECTED_PDK) printed: $(SAK_PDK_ENV)
else
# Printed once: the sub-makes of regression inherit the exported PDK and skip this block.
$(info [PDK] switched to $(PDK) (environment had PDK=$(or $(INCOMING_PDK),<unset>)), PDKPATH=$(PDKPATH), STD_CELL_LIBRARY=$(STD_CELL_LIBRARY))
endif
endif
endif
# ================================================================================================

# PEX mode (1 = C-decoupled, 2 = C-coupled, 3 = full-RC)
# Override with: make <target> EXT_MODE=<1|2|3>
EXT_MODE ?= 1

# full-RC extresist threshold in mOhm (sak-pex.sh -t, only used in EXT_MODE=3; default: 10000 = 10 Ohm)
# Override with: make <target> THRESHOLD=<mOhm>
THRESHOLD ?= 10000

# full-RC extresist minres in mOhm (sak-pex.sh -r, only used in EXT_MODE=3; default: 1000 = 1 Ohm)
# Override with: make <target> MINRES=<mOhm>
MINRES ?= 1000

# full-RC extresist mindelay in ps (sak-pex.sh -y, only used in EXT_MODE=3; default: 1; 0 = gate by resistance)
# Override with: make <target> MINDELAY=<ps>
MINDELAY ?= 1

# kpex engine for klayout-pex: magic (drives Magic, default), 2.5D (kpex's analytical engine) or
# fastercap (field solve, capacitance only). See ihp-sg13g2/pex_bench for how the three compare.
# Override with: make klayout-pex KPEX_ENGINE=<magic|2.5D|fastercap>
KPEX_ENGINE ?= magic

# fastercap only: KLayout-side triangulation --delaunay_amax in um^2 (kpex default 50, coarse) and
# the FasterCap auto tolerance -a. FasterCap's -m is overridden by -a, so kpex's --mesh does nothing.
# Override with: make klayout-pex KPEX_ENGINE=fastercap KPEX_AMAX=<um2> KPEX_TOL=<frac>
KPEX_AMAX ?= 50
KPEX_TOL ?= 0.05

# KLayout DRC level: precheck, macro, or regular (sak-drc.sh -l, only used by klayout-drc; default: macro)
# Override with: make <target> DRC_LEVEL=<precheck|macro|regular>
DRC_LEVEL ?= macro

# Floating-point precision (significant digits) for Xschem's ev function
# Override with: make <target> EV_PRECISION=<digits>
EV_PRECISION ?= 5

# Folder structure
XSCHEM_SCH_DIR  := schematic/xschem
LAY_DIR         := layout
NET_SCH_DIR     := netlist/schematic
NET_LAY_DIR     := netlist/layout
NET_PEX_DIR     := netlist/pex
LVS_RPT_DIR     := verification/lvs
DRC_RPT_DIR     := verification/drc

# File name the KLayout LVS wrapper writes the extracted netlist to, inside its run dir.
# The PDK wrappers disagree: ihp-sg13g2 and ihp-sg13cmos5l write <cell>_extracted.cir
# (run_lvs.py:605), gf180mcuD writes <cell>.cir (run_lvs.py:347).
KLAYOUT_EXT_CIR ?= $(CELL)_extracted.cir

# Same for the Magic+Netgen LVS run dir.
MAGIC_EXT_SPC ?= $(CELL).ext.spc


# Auto-discovered cells from all .gds files in $(LAY_DIR)/
LAYOUT_CELLS := $(patsubst $(LAY_DIR)/%.gds,%,$(wildcard $(LAY_DIR)/*.gds))

# Steps executed by regression for every cell, in this order.
# Each name must have a matching branch in the case statement of the regression target.
# Override with: make regression REGRESSION_STEPS="<step> <step> ..."
REGRESSION_STEPS ?= klayout-drc klayout-lvs \
			magic-drc magic-lvs \
			magic-pex1 magic-pex2 magic-pex3

# Known failures: reported by regression, but do not make it exit non-zero.
# Entry syntax:  <cell>            tolerate every failing step of that cell (same as <cell>:*)
#                <cell>:<step>     tolerate only that step; list one entry per tolerated step
# Step names:    see REGRESSION_STEPS above
# A step listed here that PASSES is an unexpected pass (XPASS) and fails the
# regression: the entry has to be removed from KNOWN_FAILS. For a whole-cell
# entry (<cell> / <cell>:*) this is the case once every step of that cell passes.
# Override with: make regression KNOWN_FAILS="<entry> <entry> ..."
KNOWN_FAILS ?=
# ================================================================================================

# Help Target
help: ## Show this help message
	@echo 'Usage: make <target> [CELL=<cellname>] [EXT_MODE=<1|2|3>] [KPEX_ENGINE=<magic|2.5D|fastercap>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>] [DRC_LEVEL=<precheck|macro|regular>] [EV_PRECISION=<digits>]'
	@echo ''
	@echo 'Available targets:'
	@grep -h -E '^[a-zA-Z0-9_.-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'This design is verified against PDK=$(EXPECTED_PDK); common.mk selects it with sak-pdk, active now: PDK=$(or $(PDK),<unset>).'
	@if [ -n '$(PDK_ERROR)' ]; then echo '  [WARNING] $(PDK_ERROR)'; fi
	@if [ -n '$(PDK_ERROR_HINT)' ]; then echo '            $(PDK_ERROR_HINT)'; fi
	@echo 'CELL defaults to $(CELL). Override to verify subcells.'
	@echo 'EXT_MODE defaults to 1 (C-decoupled). 2=C-coupled, 3=full-RC.'
	@echo 'KPEX_ENGINE defaults to magic for klayout-pex. 2.5D=kpex analytical engine, fastercap=field solve (KPEX_AMAX, KPEX_TOL).'
	@echo 'THRESHOLD/MINRES/MINDELAY are full-RC (EXT_MODE=3) extresist settings for magic-pex (defaults 10000 mOhm / 1000 mOhm / 1 ps).'
	@echo 'DRC_LEVEL defaults to macro. Sets the KLayout DRC level for klayout-drc (precheck|macro|regular).'
	@echo 'EV_PRECISION defaults to 5 significant digits for Xschem ev function.'
	@echo 'REGRESSION_STEPS lists the steps regression runs per cell (currently: $(REGRESSION_STEPS)).'
	@echo 'KNOWN_FAILS tolerates failures in regression as "<cell>" (all steps) or "<cell>:<step>" (currently: $(KNOWN_FAILS)).'
	@echo 'A KNOWN_FAILS step that passes is reported as UNEXPECTED PASS and fails the regression.'
.PHONY: help
# ================================================================================================

# Guard, prerequisite of every target that starts a tool. The PDK selection above has already
# switched the environment to EXPECTED_PDK; all that is left here is to report a switch that
# could not happen, so a design is never verified against whatever PDK the shell happens to
# have, which fails in confusing ways (or, worse, passes).
# Both lines expand to nothing when there is nothing to report.
check-pdk:
	@$(if $(PDK_ERROR),echo '[ERROR] $(PDK_ERROR)'; echo '        $(PDK_ERROR_HINT)'; exit 1,:)
	@$(if $(CELL),,echo '[ERROR] CELL is not set. The PDK Makefile has to define a default cell.'; exit 1)
.PHONY: check-pdk
# ================================================================================================

# DRC Targets
klayout-drc: check-pdk ## Run KLayout DRC of the CELL cell (usage: make klayout-drc [CELL=<cellname>] [DRC_LEVEL=<precheck|macro|regular>])
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -k -l $(DRC_LEVEL) -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds
.PHONY: klayout-drc

magic-drc: check-pdk ## Run Magic DRC of the CELL cell (usage: make magic-drc [CELL=<cellname>])
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -m -f "*" -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds
.PHONY: magic-drc
# ================================================================================================

# LVS Targets
klayout-lvs-netlist: check-pdk ## Export CDL schematic netlist from Xschem for KLayout LVS (usage: make klayout-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(XSCHEM_SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 1; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_klayout.cdl; \
		xschem netlist \
	' $(XSCHEM_SCH_DIR)/$(CELL).sch
	@if grep -q "IS MISSING" $(NET_SCH_DIR)/$(CELL)_klayout.cdl 2>/dev/null; then \
		echo "[ERROR] Xschem could not resolve every symbol of $(CELL).sch, the netlist is incomplete:"; \
		grep "IS MISSING" $(NET_SCH_DIR)/$(CELL)_klayout.cdl | sed 's/^/          /'; \
		echo "        Check the symbol library paths in $(XSCHEM_SCH_DIR)/xschemrc."; \
		exit 1; \
	fi
.PHONY: klayout-lvs-netlist

klayout-lvs: check-pdk ## Run KLayout LVS of the CELL cell (usage: make klayout-lvs [CELL=<cellname>])
	$(MAKE) klayout-lvs-netlist CELL=$(CELL)
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	sak-lvs.sh -d -k -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_klayout.cdl -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	@ext="$(LVS_RPT_DIR)/$(CELL).klayout.lvs/$(KLAYOUT_EXT_CIR)"; \
	if [ ! -f "$$ext" ]; then \
		echo "[ERROR] Extracted netlist <$$ext> not found. Set KLAYOUT_EXT_CIR in the PDK"; \
		echo "        Makefile to the name this PDK's LVS wrapper uses. Present instead:"; \
		ls -1 "$(LVS_RPT_DIR)/$(CELL).klayout.lvs/" 2>/dev/null | sed 's/^/          /'; \
		exit 1; \
	fi; \
	echo "mv $$ext $(NET_LAY_DIR)/$(CELL)_klayout.cir"; \
	mv "$$ext" $(NET_LAY_DIR)/$(CELL)_klayout.cir
.PHONY: klayout-lvs

magic-lvs-netlist: check-pdk ## Export SPICE schematic netlist from Xschem for Magic + Netgen LVS (usage: make magic-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
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
	@if grep -q "IS MISSING" $(NET_SCH_DIR)/$(CELL)_magic.spice 2>/dev/null; then \
		echo "[ERROR] Xschem could not resolve every symbol of $(CELL).sch, the netlist is incomplete:"; \
		grep "IS MISSING" $(NET_SCH_DIR)/$(CELL)_magic.spice | sed 's/^/          /'; \
		echo "        Check the symbol library paths in $(XSCHEM_SCH_DIR)/xschemrc."; \
		exit 1; \
	fi
.PHONY: magic-lvs-netlist

magic-lvs: check-pdk ## Run Magic + Netgen LVS of the CELL cell (usage: make magic-lvs [CELL=<cellname>])
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(MAKE) magic-lvs-netlist CELL=$(CELL)
	sak-lvs.sh -d -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_magic.spice -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	@ext="$(LVS_RPT_DIR)/$(CELL).magic.lvs/$(MAGIC_EXT_SPC)"; \
	if [ ! -f "$$ext" ]; then \
		echo "[ERROR] Extracted netlist <$$ext> not found. Set MAGIC_EXT_SPC in the PDK"; \
		echo "        Makefile to the name this PDK's LVS flow uses. Present instead:"; \
		ls -1 "$(LVS_RPT_DIR)/$(CELL).magic.lvs/" 2>/dev/null | sed 's/^/          /'; \
		exit 1; \
	fi; \
	echo "mv $$ext $(NET_LAY_DIR)/$(CELL)_magic.ext.spc"; \
	mv "$$ext" $(NET_LAY_DIR)/$(CELL)_magic.ext.spc
.PHONY: magic-lvs
# ================================================================================================

# PEX Targets
# Output name: <CELL>_klayout_pex_<EXT_MODE>.spice for the Magic engine (unchanged), and
# <CELL>_klayout_<engine>_pex_<EXT_MODE>.spice for the kpex engines. The fastercap run directory is
# kept, since its capacitance matrices are the data the netlist was reduced from.
klayout-pex: check-pdk ## Run Parasitic Extraction with KPEX of the CELL cell (usage: make klayout-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [KPEX_ENGINE=<magic|2.5D|fastercap>])
	mkdir -p $(NET_PEX_DIR)
	PDK_UNDERSCORED=$$(echo $$PDK | sed -e 's/-/_/g'); \
	case $(EXT_MODE) in \
		1) echo "WARNING: KPEX does not support C-decoupled (C) mode yet, using C-coupled (CC) mode instead."; KPEX_MODE=CC ;; \
		2) KPEX_MODE=CC ;; \
		3) KPEX_MODE=RC ;; \
		*) echo "Invalid EXT_MODE: $(EXT_MODE). Use 1, 2, or 3."; exit 1;; \
	esac; \
	case $(KPEX_ENGINE) in \
		magic)     ENGINE_OPTS="--magic --magic_mode $$KPEX_MODE"; OUT=$(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice ;; \
		2.5D)      ENGINE_OPTS="--2.5D --mode $$KPEX_MODE"; OUT=$(NET_PEX_DIR)/$(CELL)_klayout_2.5D_pex_$(EXT_MODE).spice ;; \
		fastercap) [ "$(EXT_MODE)" = "3" ] && echo "WARNING: the FasterCap engine extracts capacitance only, EXT_MODE=3 gives no resistors."; \
		           ENGINE_OPTS="--fastercap --delaunay_amax $(KPEX_AMAX) --delaunay_b 0.5 --tolerance $(KPEX_TOL)"; OUT=$(NET_PEX_DIR)/$(CELL)_klayout_fastercap_pex_$(EXT_MODE).spice ;; \
		*) echo "Invalid KPEX_ENGINE: $(KPEX_ENGINE). Use magic, 2.5D, or fastercap."; exit 1;; \
	esac; \
	SCHEMATIC=""; [ -f $(XSCHEM_SCH_DIR)/$(CELL).sch ] && SCHEMATIC="--schematic $(XSCHEM_SCH_DIR)/$(CELL).sch"; \
	kpex \
	--pdk $$PDK_UNDERSCORED \
	--cell $(CELL) \
	$$SCHEMATIC \
	--gds $(LAY_DIR)/$(CELL).gds \
	$$ENGINE_OPTS \
	--out_dir $(NET_PEX_DIR) \
	--out_spice $$OUT || { echo "[ERROR] kpex failed, see $(NET_PEX_DIR)/$(CELL)__$(CELL)/kpex.log"; exit 1; }; \
	[ -f $$OUT ] || { echo "[ERROR] kpex wrote no netlist $$OUT, see $(NET_PEX_DIR)/$(CELL)__$(CELL)/kpex.log"; exit 1; }; \
	sed -i 's/$(CELL)/$(CELL)_pex/g' $$OUT; \
	if [ "$(KPEX_ENGINE)" = "fastercap" ]; then \
		find $(NET_PEX_DIR)/$(CELL)__$(CELL) -type d \( -name FasterCap_Input_Files -o -name Geometries \) -prune -exec rm -rf {} + 2>/dev/null; \
	else \
		rm -rf $(NET_PEX_DIR)/$(CELL)__$(CELL); \
	fi
	rm -f $(CELL).nodes $(CELL).sim
.PHONY: klayout-pex

magic-pex: check-pdk ## Run Parasitic Extraction with Magic of the CELL cell (usage: make magic-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>])
	mkdir -p $(NET_PEX_DIR)
	sak-pex.sh -d -m $(EXT_MODE) -n $(CELL)_pex -t $(THRESHOLD) -r $(MINRES) -y $(MINDELAY) -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	rm -f $(NET_PEX_DIR)/pex_$(CELL).tcl
.PHONY: magic-pex
# ================================================================================================

# Regression Target
regression: check-pdk ## Run DRC, LVS and PEX regression for every .gds in $(LAY_DIR)/ (usage: make regression [KNOWN_FAILS="<cell>[:<step>] ..."])
	@if [ -z "$(strip $(LAYOUT_CELLS))" ]; then \
		echo "[ERROR] No layouts found in $(LAY_DIR)/ - wrong working directory?"; \
		echo "        Run the regression as: make -C <pdk-dir> regression"; \
		exit 1; \
	fi
	@set -f; \
	for kf in $(KNOWN_FAILS); do \
		kf_cell="$${kf%%:*}"; kf_step="$${kf#*:}"; \
		[ "$$kf_step" = "$$kf" ] && kf_step="*"; \
		case " $(LAYOUT_CELLS) " in \
			*" $$kf_cell "*) ;; \
			*) echo "[REGRESSION] WARNING: stale KNOWN_FAILS entry '$$kf': no $(LAY_DIR)/$$kf_cell.gds" ;; \
		esac; \
		[ "$$kf_step" = "*" ] && continue; \
		case " $(REGRESSION_STEPS) " in \
			*" $$kf_step "*) ;; \
			*) echo "[REGRESSION] WARNING: stale KNOWN_FAILS entry '$$kf': step '$$kf_step' is not in REGRESSION_STEPS" ;; \
		esac; \
	done
	@set -f; \
	failed=""; \
	known=""; \
	xpassed=""; \
	for cell in $(LAYOUT_CELLS); do \
		echo "[REGRESSION] Running verify for: $$cell"; \
		bad_steps=""; ok_steps=""; \
		for step in $(REGRESSION_STEPS); do \
			case $$step in \
				klayout-drc)  $(MAKE) klayout-drc CELL=$$cell ;; \
				klayout-lvs)  $(MAKE) klayout-lvs CELL=$$cell ;; \
				klayout-pex1) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=1 ;; \
				klayout-pex2) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=2 ;; \
				klayout-pex3) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=3 ;; \
				magic-drc)    $(MAKE) magic-drc CELL=$$cell ;; \
				magic-lvs)    $(MAKE) magic-lvs CELL=$$cell ;; \
				magic-pex1)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=1 ;; \
				magic-pex2)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=2 ;; \
				magic-pex3)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=3 ;; \
				*) echo "[REGRESSION] ERROR: unknown step '$$step' in REGRESSION_STEPS"; exit 1 ;; \
			esac; \
			if [ $$? -eq 0 ]; then ok_steps="$$ok_steps $$step"; else bad_steps="$$bad_steps $$step"; fi; \
		done; \
		cell_known=""; cell_bad=""; cell_xpass=""; \
		for step in $$bad_steps; do \
			case " $(KNOWN_FAILS) " in \
				*" $$cell "*|*" $$cell:* "*|*" $$cell:$$step "*) cell_known="$$cell_known $$step" ;; \
				*) cell_bad="$$cell_bad $$step" ;; \
			esac; \
		done; \
		for step in $$ok_steps; do \
			case " $(KNOWN_FAILS) " in \
				*" $$cell:$$step "*) cell_xpass="$$cell_xpass $$step" ;; \
			esac; \
		done; \
		if [ -z "$$bad_steps" ]; then \
			case " $(KNOWN_FAILS) " in \
				*" $$cell "*|*" $$cell:* "*) cell_xpass="$$cell_xpass all-steps" ;; \
			esac; \
		fi; \
		if [ -n "$$cell_known" ]; then \
			echo "[REGRESSION] KNOWN FAIL (ignored): $$cell ($${cell_known# })"; \
			known="$$known $$cell($${cell_known# })"; \
		fi; \
		if [ -n "$$cell_xpass" ]; then \
			echo "[REGRESSION] UNEXPECTED PASS: $$cell ($${cell_xpass# }) - listed in KNOWN_FAILS but passed, remove the entry"; \
			xpassed="$$xpassed $$cell($${cell_xpass# })"; \
		fi; \
		if [ -n "$$cell_bad" ]; then \
			echo "[REGRESSION] FAILED: $$cell ($${cell_bad# })"; \
			failed="$$failed $$cell($${cell_bad# })"; \
		elif [ -z "$$cell_known" ] && [ -z "$$cell_xpass" ]; then \
			echo "[REGRESSION] PASSED: $$cell"; \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	if [ -n "$$known" ]; then \
		echo "[REGRESSION] SUMMARY: KNOWN FAIL cells (ignored):$$known"; \
	fi; \
	if [ -n "$$xpassed" ]; then \
		echo "[REGRESSION] SUMMARY: UNEXPECTED PASS cells:$$xpassed"; \
	fi; \
	if [ -n "$$failed" ]; then \
		echo "[REGRESSION] SUMMARY: FAILED cells:$$failed"; \
	fi; \
	if [ -n "$$failed" ] || [ -n "$$xpassed" ]; then \
		echo "========================================"; \
		exit 1; \
	elif [ -n "$$known" ]; then \
		echo "[REGRESSION] SUMMARY: No unexpected failures"; \
		echo "========================================"; \
	else \
		echo "[REGRESSION] SUMMARY: All cells PASSED"; \
		echo "========================================"; \
	fi
.PHONY: regression
