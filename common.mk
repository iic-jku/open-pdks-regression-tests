# Shared DRC / LVS / PEX regression logic for the Open-PDK regression designs.
#
# Included by the per-PDK Makefile, which selects the PDK and lists that PDK's
# known failures. Always run it from the design directory:
#     cd <pdk-dir> && make <target>      or      make -C <pdk-dir> <target>
# "make -f <pdk-dir>/Makefile" does NOT work: the relative paths below would
# then resolve against the current directory instead of the design directory.
#
# SPDX-FileCopyrightText: 2026 Julian Schwarz, Simon Dorrer, and Harald Pretl
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0
# ========================================================================

.DEFAULT_GOAL := help

# ================================================================================================
# Settings the per-PDK Makefile defines before including this file:
#   REQUIRED_PDK      PDK this design is written for. common.mk switches the environment
#                     to it (see "PDK Guard" below), so a design can never be
#                     silently verified against the wrong PDK.
#   CELL              Default cell for the single-cell targets.
#   KNOWN_FAILS       Steps that fail because of a tool bug, see below.
#   EXPECTED_FAILS    Steps that have to fail, the cell is broken on purpose (see below).
#   KNOWN_FALSE_PASSES  Steps that pass a cell broken on purpose, because of a tool bug.
#   GDSCHECK_STEP     Empty for a PDK gdscheck has no rule decks for (optional, see below).
#   REGRESSION_STEPS  Steps the regression runs per cell (optional, default below).
#   KLAYOUT_EXT_CIR   Name of the extracted netlist (optional, see below).
#   MAGIC_EXT_SPC     Same for the Magic+Netgen flow (optional, see below).
# ================================================================================================

# ================================================================================================
# PDK Guard
#
# The design has to be verified against REQUIRED_PDK, so common.mk selects that PDK itself
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

ifeq ($(REQUIRED_PDK),)
PDK_ERROR := REQUIRED_PDK is not set.
PDK_ERROR_HINT := The PDK Makefile has to define it before it includes common.mk.
else ifneq ($(INCOMING_PDK),$(REQUIRED_PDK))
# PDKs installed in $PDK_ROOT, from the "Available PDKs:" block of the blank sak-pdk call.
# That call lists every entry of $PDK_ROOT, files (versions.txt) included, so keep the
# entries that are directories.
AVAILABLE_PDKS := $(filter $(notdir $(patsubst %/,%,$(wildcard $(PDK_ROOT)/*/))),\
			$(shell $(SAK_PDK_SCRIPT) 2>/dev/null | sed -n '/^Available PDKs:/,$$p' | tail -n +2))
ifeq ($(filter $(REQUIRED_PDK),$(AVAILABLE_PDKS)),)
PDK_ERROR := This design needs PDK=$(REQUIRED_PDK), which sak-pdk does not offer.
PDK_ERROR_HINT := Available PDKs: $(if $(AVAILABLE_PDKS),$(AVAILABLE_PDKS),none at all - is $(SAK_PDK_SCRIPT) there, is PDK_ROOT set?)
else
SAK_PDK_ENV := $(shell $(SAK_PDK_SCRIPT) $(REQUIRED_PDK) 2>/dev/null)
$(foreach kv,$(SAK_PDK_ENV),\
			$(if $(filter $(SAK_PDK_VARS),$(firstword $(subst =, ,$(kv)))),$(eval export $(kv))))
ifneq ($(PDK),$(REQUIRED_PDK))
PDK_ERROR := sak-pdk did not switch to PDK=$(REQUIRED_PDK).
PDK_ERROR_HINT := $(SAK_PDK_SCRIPT) $(REQUIRED_PDK) printed: $(SAK_PDK_ENV)
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

# capacitance threshold of magic-pex in fF, smaller capacitors are left out of the netlist (sak-pex.sh -c, used in every EXT_MODE, default: 0.01 = 10 aF)
# Override with: make <target> CTHRESH=<fF>
CTHRESH ?= 0.01

# full-RC extresist threshold in mOhm (sak-pex.sh -t, only used in EXT_MODE=3; default: 10000 = 10 Ohm)
# Override with: make <target> THRESHOLD=<mOhm>
THRESHOLD ?= 10000

# full-RC extresist minres in mOhm (sak-pex.sh -r, only used in EXT_MODE=3; default: 1000 = 1 Ohm)
# Override with: make <target> MINRES=<mOhm>
MINRES ?= 1000

# full-RC extresist mindelay in ps (sak-pex.sh -y, only used in EXT_MODE=3; default: 1; 0 = gate by resistance)
# Override with: make <target> MINDELAY=<ps>
MINDELAY ?= 1

# KLayout/gdscheck DRC level: precheck, macro, or regular (sak-drc.sh -l, only used by klayout-drc and gdscheck-drc; default: macro)
# Override with: make <target> DRC_LEVEL=<precheck|macro|regular>
DRC_LEVEL ?= macro

# gdscheck suite, replaces the one DRC_LEVEL selects (sak-drc.sh -s, only used by gdscheck-drc; default: empty = precheck runs precheck, macro core, regular main)
# Override with: make <target> GDSCHECK_SUITE=<precheck|core|main|density|antenna|recommended>
GDSCHECK_SUITE ?=

# gdscheck rule decks instead of a suite, comma-separated (sak-drc.sh -D, only used by gdscheck-drc, not together with GDSCHECK_SUITE; default: empty = run the suite)
# Override with: make <target> GDSCHECK_DECKS=<deck>[,<deck>...]
GDSCHECK_DECKS ?=

# Parallel DRC jobs, the KLayout processes and gdscheck threads (sak-drc.sh -j, only used by klayout-drc and gdscheck-drc; default: empty = 4 KLayout processes or fewer, on sky130A one per rule deck, gdscheck on every CPU)
# Override with: make <target> DRC_JOBS=<n>
DRC_JOBS ?=

# sak-drc.sh options for the three variables above, left out when empty so that the script defaults apply
_GDSCHECK_SUITE_OPT = $(if $(GDSCHECK_SUITE),-s "$(GDSCHECK_SUITE)")
_GDSCHECK_DECKS_OPT = $(if $(GDSCHECK_DECKS),-D "$(GDSCHECK_DECKS)")
_DRC_JOBS_OPT = $(if $(DRC_JOBS),-j $(DRC_JOBS))

# Port net that klayout-pex ties the substrate port of the kpex 2.5D netlist to (sak-pex.sh -g): sub! on the IHP PDKs, SUB on gf180mcuD, sky130_gnd on sky130A. Empty keeps the substrate port: the cells here name their bulk pin B, not VSS, and the port check accepts the extra port as long as elements connect to it.
# Override with: make klayout-pex PEX_SUB_NET=<net>
PEX_SUB_NET ?=

# Reduction of the full-RC netlist of klayout-pex (sak-pex.sh -R, only used in EXT_MODE=3; default: ticer): none, floating (merges the floating islands and removes the capacitor-only nodes) or ticer (floating plus TICER node elimination).
# Override with: make klayout-pex KPEX_REDUCE=<none|floating|ticer>
KPEX_REDUCE ?= ticer

# sak-drc.sh to run, e.g. a newer one than the image ships (default: the one on PATH)
# Override with: make <target> SAK_DRC=<path to sak-drc.sh>
SAK_DRC ?= sak-drc.sh

# sak-lvs.sh to run, e.g. a newer one than the image ships (default: the one on PATH)
# Override with: make <target> SAK_LVS=<path to sak-lvs.sh>
SAK_LVS ?= sak-lvs.sh

# sak-pex.sh to run, e.g. a newer one than the image ships (default: the one on PATH)
# Override with: make <target> SAK_PEX=<path to sak-pex.sh>
SAK_PEX ?= sak-pex.sh

# Floating-point precision (significant digits) for Xschem's ev function
# Override with: make <target> EV_PRECISION=<digits>
EV_PRECISION ?= 5

# Extra options for the sak-open.py file browser (e.g. --all to include build outputs)
# Override with: make open OPEN_ARGS=<options>
OPEN_ARGS ?=

# Folder structure
XSCHEM_SCH_DIR  := schematic/xschem
LAY_DIR         := layout
NET_SCH_DIR     := netlist/schematic
NET_LAY_DIR     := netlist/layout
NET_PEX_DIR     := netlist/pex
LVS_RPT_DIR     := verification/lvs
DRC_RPT_DIR     := verification/drc

# Scripts shared by every PDK, in scripts/ next to this file.
SCRIPTS_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))/scripts

# File name the KLayout LVS wrapper writes the extracted netlist to, inside its run dir.
# The PDK wrappers disagree: ihp-sg13g2 and ihp-sg13cmos5l write <cell>_extracted.cir
# (run_lvs.py:605), gf180mcuD writes <cell>.cir (run_lvs.py:347).
KLAYOUT_EXT_CIR ?= $(CELL)_extracted.cir

# Same for the Magic+Netgen LVS run dir.
MAGIC_EXT_SPC ?= $(CELL).ext.spc


# Auto-discovered cells from all .gds files in $(LAY_DIR)/
ALL_CELLS := $(patsubst $(LAY_DIR)/%.gds,%,$(wildcard $(LAY_DIR)/*.gds))
LAYOUT_CELLS := $(ALL_CELLS)

# gdscheck has rule decks for ihp-sg13g2, ihp-sg13cmos5l and gf180mcuD, not for sky130A.
# The sky130A Makefile sets this empty, so its regression leaves the step out.
GDSCHECK_STEP ?= gdscheck-drc

# Steps executed by regression for every cell, in this order.
# Each name must have a matching branch in the case statement of the regression target.
# Override with: make regression REGRESSION_STEPS="<step> <step> ..."
DEFAULT_STEPS := $(strip klayout-drc klayout-lvs \
			magic-drc magic-lvs \
			$(GDSCHECK_STEP) \
			magic-pex1 magic-pex2 magic-pex3 \
			klayout-pex1 klayout-pex2 klayout-pex3)
REGRESSION_STEPS ?= $(DEFAULT_STEPS)

# Every step the regression target knows. The lists below may name any of them, also a step
# that REGRESSION_STEPS leaves out.
ALL_STEPS := klayout-drc klayout-lvs klayout-pex1 klayout-pex2 klayout-pex3 \
			magic-drc magic-lvs magic-pex1 magic-pex2 magic-pex3 gdscheck-drc

# Run only some of REGRESSION_STEPS. Each word is a step or a make pattern, % matches any text:
#   make regression STEPS=%-lvs          klayout-lvs and magic-lvs
#   make regression STEPS="magic-%"      every Magic step
STEPS ?=
ifneq ($(strip $(STEPS)),)
STEPS_UNKNOWN := $(foreach s,$(STEPS),$(if $(filter $(s),$(ALL_STEPS)),,$(s)))
override REGRESSION_STEPS := $(filter $(STEPS),$(REGRESSION_STEPS))
endif

# A run with fewer cells (LAYOUT_CELLS) or steps (STEPS, REGRESSION_STEPS) than the full
# regression says so at the start and in the summary. Empty for a full run.
comma := ,
CELLS_LEFT_OUT = $(filter-out $(LAYOUT_CELLS),$(ALL_CELLS))
STEPS_LEFT_OUT = $(filter-out $(REGRESSION_STEPS),$(DEFAULT_STEPS))
RUN_CELLS = $(if $(CELLS_LEFT_OUT),$(words $(LAYOUT_CELLS)) of $(words $(ALL_CELLS)) cells$(if $(word 11,$(LAYOUT_CELLS)),, ($(strip $(LAYOUT_CELLS)))),all $(words $(LAYOUT_CELLS)) cells)
RUN_STEPS = $(if $(STEPS_LEFT_OUT),$(words $(REGRESSION_STEPS)) of $(words $(DEFAULT_STEPS)) steps ($(strip $(REGRESSION_STEPS))),all $(words $(REGRESSION_STEPS)) steps)
PARTIAL_RUN = $(if $(CELLS_LEFT_OUT)$(STEPS_LEFT_OUT),$(RUN_CELLS)$(comma) $(RUN_STEPS))

# Steps that are not supposed to simply pass. A tool bug is "known" and expected to be fixed one
# day; a cell that is broken on purpose is "expected" to fail for good.
#
#     the right verdict is PASS     					the right verdict is FAIL
#     tool gets it right  (no entry)                    EXPECTED_FAILS
#     tool gets it wrong  KNOWN_FAILS                   KNOWN_FALSE_PASSES
#
# Entry syntax, the same in all three lists:
#   <cell>:<step>   that step only; list one entry per step
#   <cell>          the whole cell, same as <cell>:*. In KNOWN_FAILS every step of the cell. In
#                   EXPECTED_FAILS and KNOWN_FALSE_PASSES every DRC and LVS step: a PEX step
#                   checks the extraction, not the cell. It fails when it writes no netlist,
#                   or one with a port that no element connects to (scripts/check_pex_ports.py),
#                   or a full-RC netlist that connects devices or ports otherwise than the
#                   C-coupled netlist of the cell (scripts/check_pex_modes.py).
# Step names: see REGRESSION_STEPS above. A step may be covered by one list only, and the two
# lists for cells broken on purpose take DRC and LVS steps only.
#
# KNOWN_FAILS: the step should pass but fails because of a tool or PDK bug (KNOWN_ISSUES.md).
#   fails   KNOWN FAIL, tolerated
#   passes  UNEXPECTED PASS, fails the regression: the bug is gone, remove the entry. For a
#           whole-cell entry this is the case once every step of the cell passes.
# EXPECTED_FAILS: the cell is broken on purpose and the step has to catch it (EXPECTED_FAILS.md).
#   fails with a finding     EXPECTED FAIL, fine
#   passes                   FALSE PASS, fails the regression: the tool missed the error
#   fails without a finding  BROKEN, fails the regression: the check did not run to the end
# KNOWN_FALSE_PASSES: the cell is broken on purpose, but the step passes because of a tool bug
# (KNOWN_ISSUES.md).
#   passes                   KNOWN FALSE PASS, tolerated
#   fails with a finding     UNEXPECTED FAIL, fails the regression: the tool catches it now, move
#                            the entry to EXPECTED_FAILS. For a whole-cell entry a step that
#                            catches it counts as EXPECTED FAIL until every step does.
#   fails without a finding  BROKEN, fails the regression
#
# A finding or a breakdown: sak-drc.sh and sak-lvs.sh exit with 1 when the check ran and found
# DRC violations or a mismatch, and with another code when it could not run (missing file, no
# report, ...). make turns both into its own exit code 2, so every DRC and LVS target writes the
# exit code of its sak script to <report dir>/<cell>.<step>.rc. A step that fails without that
# file never reached the check, e.g. because the schematic could not be netlisted.
# gdscheck-drc is a DRC step like the other two: sak-drc.sh -g exits with 1 on violations as well.
#
# Override with: make regression KNOWN_FAILS="<entry> ..." EXPECTED_FAILS="..." KNOWN_FALSE_PASSES="..."
KNOWN_FAILS ?=
EXPECTED_FAILS ?=
KNOWN_FALSE_PASSES ?=

# Exit code file of a DRC or LVS step of CELL, see "A finding or a breakdown" above.
# Usage: $(call step_rc,<report dir>,<step>)
step_rc = $(1)/$(CELL).$(2).rc

# Shell helpers of the regression target.
#   is_check <step>                        DRC or LVS step?
#   in_list "<entries>" <cell> <step> all|checks
#                                          is <cell>:<step> covered by the list? A whole-cell
#                                          entry covers every step (all) or the DRC and LVS
#                                          steps only (checks).
#   whole_cell "<entries>" <cell>          does the list name the whole cell?
REGRESSION_SH = \
	is_check() { case $$1 in *-drc|*-lvs) return 0 ;; esac; return 1; }; \
	in_list() { \
		case " $$1 " in *" $$2:$$3 "*) return 0 ;; esac; \
		case " $$1 " in *" $$2 "*|*" $$2:* "*) [ "$$4" = all ] || is_check "$$3" ;; *) return 1 ;; esac; \
	}; \
	whole_cell() { case " $$1 " in *" $$2 "*|*" $$2:* "*) return 0 ;; esac; return 1; };
# ================================================================================================

# Help Target
help: ## Show this help message
	@echo 'Usage: make <target> [CELL=<cellname>] [EXT_MODE=<1|2|3>] [CTHRESH=<fF>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>] [DRC_LEVEL=<precheck|macro|regular>] [GDSCHECK_SUITE=<suite>|GDSCHECK_DECKS=<decks>] [DRC_JOBS=<n>] [KPEX_REDUCE=<none|floating|ticer>] [PEX_SUB_NET=<net>] [EV_PRECISION=<digits>] [SAK_DRC=<path>] [SAK_LVS=<path>] [SAK_PEX=<path>] [OPEN_ARGS=<options>]'
	@echo ''
	@echo 'Available targets:'
	@grep -h -E '^[a-zA-Z0-9_.-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@if [ -z '$(GDSCHECK_STEP)' ]; then echo '  gdscheck has no rule decks for $(REQUIRED_PDK): gdscheck-drc stops with an error, and the regression leaves it out.'; fi
	@echo ''
	@echo 'REQUIRED_PDK is $(REQUIRED_PDK). Unlike the chip templates, which abort, common.mk switches every target to it with sak-pdk-script.sh if $$PDK differs, active now: PDK=$(or $(PDK),<unset>).'
	@if [ -n '$(PDK_ERROR)' ]; then echo '  [WARNING] $(PDK_ERROR)'; fi
	@if [ -n '$(PDK_ERROR_HINT)' ]; then echo '            $(PDK_ERROR_HINT)'; fi
	@echo 'CELL defaults to $(CELL). Override to verify subcells.'
	@echo 'EXT_MODE defaults to 1 (C-decoupled). 2=C-coupled, 3=full-RC.'
	@echo 'CTHRESH is the capacitance threshold of magic-pex in fF in every EXT_MODE, smaller capacitors are left out of the netlist (default 0.01 = 10 aF).'
	@echo 'THRESHOLD/MINRES/MINDELAY are full-RC (EXT_MODE=3) extresist settings for magic-pex (defaults 10000 mOhm / 1000 mOhm / 1 ps).'
	@echo 'DRC_LEVEL defaults to macro. Sets the DRC level for klayout-drc and gdscheck-drc (precheck|macro|regular).'
	@echo 'GDSCHECK_SUITE replaces the gdscheck suite of DRC_LEVEL for gdscheck-drc (precheck|core|main|density|antenna|recommended).'
	@echo 'GDSCHECK_DECKS runs gdscheck rule decks instead of a suite, comma-separated (e.g. activ,gatpoly).'
	@echo 'DRC_JOBS caps the KLayout DRC processes and sets the gdscheck threads (default: 4 KLayout processes or fewer, on sky130A one per rule deck, gdscheck on every CPU).'
	@echo 'PEX_SUB_NET defaults to empty, which keeps the substrate port of the kpex 2.5D netlist of klayout-pex. A port net ties the substrate port to that net.'
	@echo 'KPEX_REDUCE defaults to ticer. Sets the RC network reduction of klayout-pex in EXT_MODE=3 (none|floating|ticer).'
	@echo 'EV_PRECISION defaults to 5 significant digits for Xschem ev function.'
	@echo 'SAK_DRC, SAK_LVS and SAK_PEX default to sak-drc.sh, sak-lvs.sh and sak-pex.sh on PATH. Point one at another copy to test that one, regression passes it on to every step.'
	@echo 'OPEN_ARGS passes extra options to sak-open.py for the open target (e.g. --all).'
	@echo 'REGRESSION_STEPS lists the steps regression runs per cell (currently: $(REGRESSION_STEPS)).'
	@echo 'STEPS runs only the matching REGRESSION_STEPS, % matches any text (e.g. STEPS=%-lvs for both LVS steps).'
	@echo 'KNOWN_FAILS tolerates failures in regression as "<cell>" (all steps) or "<cell>:<step>" (currently: $(KNOWN_FAILS)).'
	@echo 'A KNOWN_FAILS step that passes is reported as UNEXPECTED PASS and fails the regression.'
	@echo 'EXPECTED_FAILS lists DRC/LVS steps of cells broken on purpose, which have to fail with a finding (currently: $(EXPECTED_FAILS)).'
	@echo 'KNOWN_FALSE_PASSES lists DRC/LVS steps that pass a cell broken on purpose because of a tool bug (currently: $(KNOWN_FALSE_PASSES)).'
.PHONY: help
# ================================================================================================

# Guard, prerequisite of every target that starts a tool. The PDK guard above has already
# switched the environment to REQUIRED_PDK, so all that is left here is to report a switch that
# could not happen, so a design is never verified against whatever PDK the shell happens to
# have, which fails in confusing ways (or, worse, passes).
# Both lines expand to nothing when there is nothing to report.
check-pdk:
	@$(if $(PDK_ERROR),echo '[ERROR] $(PDK_ERROR)'; echo '        $(PDK_ERROR_HINT)'; exit 1,:)
	@$(if $(CELL),,echo '[ERROR] CELL is not set. The PDK Makefile has to define a default cell.'; exit 1)
.PHONY: check-pdk
# ================================================================================================

# Open Target
# The tools the file browser starts inherit the PDK selected above, not the one of the shell.
open: check-pdk ## Open the design files of this folder in the sak-open.py file browser (needs the VNC/X11 desktop)
	sak-open.py $(OPEN_ARGS) .
.PHONY: open
# ================================================================================================

# DRC Targets
klayout-drc: check-pdk ## Run KLayout DRC of the CELL cell (usage: make klayout-drc [CELL=<cellname>] [DRC_LEVEL=<precheck|macro|regular>] [DRC_JOBS=<n>])
	@rm -f $(call step_rc,$(DRC_RPT_DIR),klayout-drc)
	mkdir -p $(DRC_RPT_DIR)
	$(SAK_DRC) -d -k -l $(DRC_LEVEL) $(_DRC_JOBS_OPT) -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds; \
	rc=$$?; echo $$rc > $(call step_rc,$(DRC_RPT_DIR),klayout-drc); exit $$rc
.PHONY: klayout-drc

magic-drc: check-pdk ## Run Magic DRC of the CELL cell (usage: make magic-drc [CELL=<cellname>])
	@rm -f $(call step_rc,$(DRC_RPT_DIR),magic-drc)
	mkdir -p $(DRC_RPT_DIR)
	@# No -f (gds flatglob) here: Magic keeps the contents of a matching cell only to paint them
	@# into its parents, so a pattern that matches the top cell ("*") loads it empty and every
	@# check passes. On the regression cells, hierarchical Magic DRC finds the same errors as on a
	@# copy flattened with Magic's "flatten" command.
	$(SAK_DRC) -d -m -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds; \
	rc=$$?; echo $$rc > $(call step_rc,$(DRC_RPT_DIR),magic-drc); exit $$rc
.PHONY: magic-drc

gdscheck-drc: check-pdk ## Run gdscheck DRC of the CELL cell (usage: make gdscheck-drc [CELL=<cellname>] [DRC_LEVEL=<precheck|macro|regular>] [GDSCHECK_SUITE=<suite>|GDSCHECK_DECKS=<decks>] [DRC_JOBS=<n>])
	@rm -f $(call step_rc,$(DRC_RPT_DIR),gdscheck-drc)
	mkdir -p $(DRC_RPT_DIR)
	$(SAK_DRC) -d -g -l $(DRC_LEVEL) $(_GDSCHECK_SUITE_OPT) $(_GDSCHECK_DECKS_OPT) $(_DRC_JOBS_OPT) -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds; \
	rc=$$?; echo $$rc > $(call step_rc,$(DRC_RPT_DIR),gdscheck-drc); exit $$rc
.PHONY: gdscheck-drc
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
	@rm -f $(call step_rc,$(LVS_RPT_DIR),klayout-lvs)
	$(MAKE) klayout-lvs-netlist CELL=$(CELL)
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(SAK_LVS) -d -k -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_klayout.cdl -l $(LAY_DIR)/$(CELL).gds -c $(CELL); \
	rc=$$?; echo $$rc > $(call step_rc,$(LVS_RPT_DIR),klayout-lvs); exit $$rc
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
	@rm -f $(call step_rc,$(LVS_RPT_DIR),magic-lvs)
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(MAKE) magic-lvs-netlist CELL=$(CELL)
	@# stdin from /dev/null, see magic-pex
	$(SAK_LVS) -d -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_magic.spice -l $(LAY_DIR)/$(CELL).gds -c $(CELL) < /dev/null; \
	rc=$$?; echo $$rc > $(call step_rc,$(LVS_RPT_DIR),magic-lvs); exit $$rc
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
klayout-pex: check-pdk ## Run Parasitic Extraction with the KPEX 2.5D engine of the CELL cell (usage: make klayout-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [KPEX_REDUCE=<none|floating|ticer>] [PEX_SUB_NET=<net>])
	mkdir -p $(NET_PEX_DIR)
	@# No schematic for kpex (sak-pex.sh -S): its device check fails the full-RC extraction of every cell whose layout and schematic differ, which is what the LVS steps report.
	@# A PEX step checks the extraction, not the cell.
	$(SAK_PEX) -d -k -m $(EXT_MODE) -n $(CELL)_pex -R $(KPEX_REDUCE) -g "$(PEX_SUB_NET)" -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
	python3 $(SCRIPTS_DIR)/check_pex_ports.py $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
	@# full-RC only: compare the connections with the C-coupled netlist of the same cell, which regression extracts first (klayout-pex2 runs before klayout-pex3)
	@if [ "$(EXT_MODE)" = "3" ]; then \
		python3 $(SCRIPTS_DIR)/check_pex_modes.py --layout $(LAY_DIR)/$(CELL).gds \
			$(NET_PEX_DIR)/$(CELL)_klayout_pex_3.spice $(NET_PEX_DIR)/$(CELL)_klayout_pex_2.spice; \
	fi
.PHONY: klayout-pex

magic-pex: check-pdk ## Run Parasitic Extraction with Magic of the CELL cell (usage: make magic-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [CTHRESH=<fF>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>])
	mkdir -p $(NET_PEX_DIR)
	@# stdin from /dev/null: sak-pex.sh and sak-lvs.sh run Magic in the foreground, and a Magic that
	@# crashes (sky130_pnp_05v5_W3p40L3p40, full-RC) leaves the terminal without echo. sak-drc.sh runs
	@# Magic in the background, where stdin is /dev/null already.
	$(SAK_PEX) -d -m $(EXT_MODE) -n $(CELL)_pex -c $(CTHRESH) -t $(THRESHOLD) -r $(MINRES) -y $(MINDELAY) -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds < /dev/null
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	rm -f $(NET_PEX_DIR)/pex_$(CELL).tcl
	python3 $(SCRIPTS_DIR)/check_pex_ports.py $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	@# full-RC only: compare the connections with the C-coupled netlist of the same cell, which
	@# regression extracts first (magic-pex2 runs before magic-pex3)
	@if [ "$(EXT_MODE)" = "3" ]; then \
		python3 $(SCRIPTS_DIR)/check_pex_modes.py --layout $(LAY_DIR)/$(CELL).gds \
			$(NET_PEX_DIR)/$(CELL)_magic_pex_3.spice $(NET_PEX_DIR)/$(CELL)_magic_pex_2.spice; \
	fi
.PHONY: magic-pex
# ================================================================================================

# Verify Targets
# As in the chip templates, each step runs only if the one before it passed. regression runs
# every step and judges the outcome against the lists of the PDK Makefile.
klayout-verify: check-pdk ## Verify CELL cell with KLayout (usage: make klayout-verify [CELL=<cellname>])
	$(MAKE) klayout-drc CELL=$(CELL)
	$(MAKE) klayout-lvs CELL=$(CELL)
	$(MAKE) klayout-pex CELL=$(CELL)
.PHONY: klayout-verify

magic-verify: check-pdk ## Verify CELL cell with Magic (usage: make magic-verify [CELL=<cellname>])
	$(MAKE) magic-drc CELL=$(CELL)
	$(MAKE) magic-lvs CELL=$(CELL)
	$(MAKE) magic-pex CELL=$(CELL)
.PHONY: magic-verify
# ================================================================================================

# Regression Target
regression: check-pdk ## Run DRC, LVS and PEX regression for every .gds in $(LAY_DIR)/ (usage: make regression [STEPS="<step or pattern> ..."] [KNOWN_FAILS="<cell>[:<step>] ..."] [EXPECTED_FAILS="..."] [KNOWN_FALSE_PASSES="..."])
	@if [ -z "$(strip $(LAYOUT_CELLS))" ]; then \
		echo "[ERROR] No layouts found in $(LAY_DIR)/ - wrong working directory?"; \
		echo "        Run the regression as: make -C <pdk-dir> regression"; \
		exit 1; \
	fi
	@if [ -n "$(strip $(STEPS_UNKNOWN))" ]; then \
		echo "[ERROR] STEPS=\"$(STEPS)\": '$(strip $(STEPS_UNKNOWN))' matches no step. Steps: $(ALL_STEPS)"; \
		exit 1; \
	fi
	@if [ -z "$(strip $(REGRESSION_STEPS))" ]; then \
		echo "[ERROR] No step to run: STEPS=\"$(STEPS)\" matches none of the regression steps."; \
		exit 1; \
	fi
	@$(if $(PARTIAL_RUN),echo "[REGRESSION] Partial run: $(PARTIAL_RUN)",true)
	@set -f; \
	$(REGRESSION_SH) \
	check_list() { \
		list=$$1; shift; \
		for kf in "$$@"; do \
			kf_step="$${kf#*:}"; \
			[ "$$kf_step" = "$$kf" ] && continue; \
			if [ "$$list" != KNOWN_FAILS ] && ! is_check "$$kf_step"; then \
				echo "[REGRESSION] ERROR: $$list entry '$$kf': only DRC and LVS steps can catch a cell broken on purpose"; \
				exit 1; \
			fi; \
		done; \
	}; \
	check_list KNOWN_FAILS $(KNOWN_FAILS); \
	check_list EXPECTED_FAILS $(EXPECTED_FAILS); \
	check_list KNOWN_FALSE_PASSES $(KNOWN_FALSE_PASSES); \
	clash=""; \
	for cell in $(LAYOUT_CELLS); do \
		for step in $(REGRESSION_STEPS); do \
			lists=""; \
			in_list "$(KNOWN_FAILS)" $$cell $$step all && lists="$$lists KNOWN_FAILS"; \
			in_list "$(EXPECTED_FAILS)" $$cell $$step checks && lists="$$lists EXPECTED_FAILS"; \
			in_list "$(KNOWN_FALSE_PASSES)" $$cell $$step checks && lists="$$lists KNOWN_FALSE_PASSES"; \
			case "$$lists" in \
				" "*" "*) echo "[REGRESSION] ERROR: $$cell:$$step is covered by more than one list:$$lists"; clash=1 ;; \
			esac; \
		done; \
	done; \
	[ -z "$$clash" ]
	@set -f; \
	$(REGRESSION_SH) \
	failed=""; \
	known=""; \
	expected=""; \
	kfp=""; \
	xpassed=""; \
	xfailed=""; \
	for cell in $(LAYOUT_CELLS); do \
		echo "[REGRESSION] Running verify for: $$cell"; \
		any_fail=""; checks_run=""; checks_passed=""; \
		c_bad=""; c_known=""; c_xpass=""; c_expected=""; c_falsepass=""; c_kfp=""; c_xfail=""; \
		c_broken=""; c_broken_steps=""; \
		for step in $(REGRESSION_STEPS); do \
			case $$step in \
				klayout-drc)  $(MAKE) klayout-drc CELL=$$cell ;; \
				klayout-lvs)  $(MAKE) klayout-lvs CELL=$$cell ;; \
				klayout-pex1) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=1 ;; \
				klayout-pex2) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=2 ;; \
				klayout-pex3) $(MAKE) klayout-pex CELL=$$cell EXT_MODE=3 ;; \
				magic-drc)    $(MAKE) magic-drc CELL=$$cell ;; \
				magic-lvs)    $(MAKE) magic-lvs CELL=$$cell ;; \
				gdscheck-drc) $(MAKE) gdscheck-drc CELL=$$cell ;; \
				magic-pex1)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=1 ;; \
				magic-pex2)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=2 ;; \
				magic-pex3)   $(MAKE) magic-pex CELL=$$cell EXT_MODE=3 ;; \
				*) echo "[REGRESSION] ERROR: unknown step '$$step' in REGRESSION_STEPS"; exit 1 ;; \
			esac; \
			if [ $$? -eq 0 ]; then ok=1; else ok=""; any_fail=1; fi; \
			rc=""; \
			case $$step in \
				*-drc) [ -f $(DRC_RPT_DIR)/$$cell.$$step.rc ] && rc=$$(cat $(DRC_RPT_DIR)/$$cell.$$step.rc) ;; \
				*-lvs) [ -f $(LVS_RPT_DIR)/$$cell.$$step.rc ] && rc=$$(cat $(LVS_RPT_DIR)/$$cell.$$step.rc) ;; \
			esac; \
			if [ -n "$$rc" ]; then why="exit $$rc"; else why="never reached the check"; fi; \
			if is_check $$step; then checks_run=1; [ -n "$$ok" ] && checks_passed=1; fi; \
			if in_list "$(EXPECTED_FAILS)" $$cell $$step checks; then \
				if [ -n "$$ok" ]; then c_falsepass="$$c_falsepass $$step"; \
				elif [ "$$rc" = 1 ]; then c_expected="$$c_expected $$step"; \
				else c_broken="$$c_broken, $$step $$why"; c_broken_steps="$$c_broken_steps $$step"; fi; \
			elif in_list "$(KNOWN_FALSE_PASSES)" $$cell $$step checks; then \
				if [ -n "$$ok" ]; then c_kfp="$$c_kfp $$step"; \
				elif [ "$$rc" != 1 ]; then c_broken="$$c_broken, $$step $$why"; c_broken_steps="$$c_broken_steps $$step"; \
				elif whole_cell "$(KNOWN_FALSE_PASSES)" $$cell; then c_expected="$$c_expected $$step"; \
				else c_xfail="$$c_xfail $$step"; fi; \
			elif in_list "$(KNOWN_FAILS)" $$cell $$step all; then \
				if [ -z "$$ok" ]; then c_known="$$c_known $$step"; \
				else case " $(KNOWN_FAILS) " in *" $$cell:$$step "*) c_xpass="$$c_xpass $$step" ;; esac; fi; \
			elif [ -z "$$ok" ]; then \
				c_bad="$$c_bad $$step"; \
			fi; \
		done; \
		if [ -z "$$any_fail" ] && whole_cell "$(KNOWN_FAILS)" $$cell; then \
			c_xpass="$$c_xpass all-steps"; \
		fi; \
		if [ -n "$$checks_run" ] && [ -z "$$checks_passed$$c_broken_steps" ] && whole_cell "$(KNOWN_FALSE_PASSES)" $$cell; then \
			c_xfail="$$c_xfail all-steps"; \
		fi; \
		if [ -n "$$c_known" ]; then \
			echo "[REGRESSION] KNOWN FAIL (tool bug, ignored): $$cell ($${c_known# })"; \
			known="$$known $$cell($${c_known# })"; \
		fi; \
		if [ -n "$$c_expected" ]; then \
			echo "[REGRESSION] EXPECTED FAIL (broken on purpose, caught): $$cell ($${c_expected# })"; \
			expected="$$expected $$cell($${c_expected# })"; \
		fi; \
		if [ -n "$$c_kfp" ]; then \
			echo "[REGRESSION] KNOWN FALSE PASS (tool bug, ignored): $$cell ($${c_kfp# })"; \
			kfp="$$kfp $$cell($${c_kfp# })"; \
		fi; \
		if [ -n "$$c_xpass" ]; then \
			echo "[REGRESSION] UNEXPECTED PASS: $$cell ($${c_xpass# }) - listed in KNOWN_FAILS but passed, remove the entry"; \
			xpassed="$$xpassed $$cell($${c_xpass# })"; \
		fi; \
		if [ -n "$$c_xfail" ]; then \
			echo "[REGRESSION] UNEXPECTED FAIL: $$cell ($${c_xfail# }) - listed in KNOWN_FALSE_PASSES but failed, move it to EXPECTED_FAILS"; \
			xfailed="$$xfailed $$cell($${c_xfail# })"; \
		fi; \
		if [ -n "$$c_falsepass" ]; then \
			echo "[REGRESSION] FALSE PASS: $$cell ($${c_falsepass# }) - broken on purpose, but the tool passed it"; \
		fi; \
		if [ -n "$$c_broken" ]; then \
			echo "[REGRESSION] BROKEN: $$cell ($${c_broken#, }) - the check did not run to the end, its verdict is unknown"; \
		fi; \
		if [ -n "$$c_bad" ]; then \
			echo "[REGRESSION] FAILED: $$cell ($${c_bad# })"; \
		fi; \
		red="$$c_bad"; \
		for s in $$c_falsepass; do red="$$red $$s:false-pass"; done; \
		for s in $$c_broken_steps; do red="$$red $$s:broken"; done; \
		if [ -n "$$red" ]; then \
			failed="$$failed $$cell($${red# })"; \
		elif [ -z "$$c_known$$c_expected$$c_kfp$$c_xpass$$c_xfail" ]; then \
			echo "[REGRESSION] PASSED: $$cell"; \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	$(if $(PARTIAL_RUN),echo "[REGRESSION] SUMMARY: Partial run: $(PARTIAL_RUN)";) \
	if [ -n "$$known" ]; then \
		echo "[REGRESSION] SUMMARY: KNOWN FAIL cells (tool bug, ignored):$$known"; \
	fi; \
	if [ -n "$$expected" ]; then \
		echo "[REGRESSION] SUMMARY: EXPECTED FAIL cells (broken on purpose, caught):$$expected"; \
	fi; \
	if [ -n "$$kfp" ]; then \
		echo "[REGRESSION] SUMMARY: KNOWN FALSE PASS cells (tool bug, ignored):$$kfp"; \
	fi; \
	if [ -n "$$xpassed" ]; then \
		echo "[REGRESSION] SUMMARY: UNEXPECTED PASS cells:$$xpassed"; \
	fi; \
	if [ -n "$$xfailed" ]; then \
		echo "[REGRESSION] SUMMARY: UNEXPECTED FAIL cells:$$xfailed"; \
	fi; \
	if [ -n "$$failed" ]; then \
		echo "[REGRESSION] SUMMARY: FAILED cells:$$failed"; \
	fi; \
	if [ -n "$$failed" ] || [ -n "$$xpassed" ] || [ -n "$$xfailed" ]; then \
		echo "========================================"; \
		exit 1; \
	elif [ -n "$$known$$expected$$kfp" ]; then \
		echo "[REGRESSION] SUMMARY: No unexpected failures"; \
		echo "========================================"; \
	else \
		echo "[REGRESSION] SUMMARY: All cells PASSED"; \
		echo "========================================"; \
	fi
.PHONY: regression
# ================================================================================================

# Clean Target
clean: ## Delete all generated files and folders (netlists, DRC/LVS reports, Xschem simulations folder)
	rm -rf $(NET_SCH_DIR) $(NET_LAY_DIR) $(NET_PEX_DIR)
	rm -rf $(DRC_RPT_DIR) $(LVS_RPT_DIR)
	@# Netlists of the Xschem GUI (make open) land in schematic/xschem/simulations. The leading ./
	@# keeps the path inside the design directory if XSCHEM_SCH_DIR is overridden empty.
	rm -rf ./$(XSCHEM_SCH_DIR)/simulations
.PHONY: clean
