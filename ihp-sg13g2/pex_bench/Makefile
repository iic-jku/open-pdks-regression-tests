# ihp-sg13g2 PEX bench: metal-only dummy layouts whose parasitics follow from the extraction
# deck by hand, extracted with Magic and with the kpex engines, then compared.
# Run from this directory: make pex-bench
# The single-cell targets (magic-pex, klayout-pex) come from ../../common.mk.
#
# SPDX-FileCopyrightText: 2026 Simon Dorrer
# Johannes Kepler University, Department for Integrated Circuits
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

EXPECTED_PDK := ihp-sg13g2

# Default cell for the single-cell targets
CELL ?= sidewall_m1_s0p2

# The bench compares capacitance in C-coupled mode, so that is the default here
EXT_MODE ?= 2

# Full-RC settings the bench uses for the resistance tables: the only combination that makes
# Magic emit a resistor for an unbranched net at all (see report/pex_bench_report.html, defect 2)
THRESHOLD ?= 0
MINRES ?= 0
MINDELAY ?= 0

# kpex FasterCap triangulation (--delaunay_amax, um^2) and auto tolerance (-a).
# 50 is kpex's default and far too coarse for sub-micron gaps. 2 is the bench default, 0.1 is
# where the sidewall sweep converged. FasterCap's -m is overridden by -a, so --mesh does nothing.
KPEX_AMAX ?= 2
KPEX_TOL ?= 0.05

# Threads for the FasterCap field solve. Empty means kpex's own default, which is
# os.cpu_count() * 4 - 128 threads on a 32-core machine, four times oversubscribed on an
# OpenMP solver. Set it explicitly on a big machine, and remember that FasterCap is only
# part of the run: the KLayout triangulation and the LVS in front of it are single-threaded,
# so cell-level parallelism buys more than threads per cell past a handful.
# Left empty by default so the committed expected values stay reproducible bit for bit.
KPEX_THREADS ?=

# Set FASTERCAP=1 to include the field solve in pex-bench (minutes, not seconds)
FASTERCAP ?= 0

# Cells the engine comparison runs on: the device-less structures with a hand answer.
# The Magic tables run on every layout.
KPEX_CELLS := capsub_m1 capsub_m2 capsub_m3 capsub_m4 capsub_m5 capsub_tm1 capsub_tm2 \
	overlap_m1_m2 overlap_m2_m3 overlap_m3_m4 overlap_m4_m5 overlap_m5_tm1 \
	overlap_tm1_tm2 overlap_m1_m3 overlap_m1_tm1 \
	sidewall_m1_s0p2 sidewall_m1_s0p4 sidewall_m1_s0p8 sidewall_m1_s1p6 sidewall_m1_s3p2

# kpex 2.5D cells that are expected to fail, tolerated like common.mk's KNOWN_FAILS: a listed
# cell that fails is reported and ignored, a listed cell that passes fails the target so the
# entry gets removed. Use it only for a defect that is understood and written down.
KPEX_KNOWN_FAILS ?=

# common.mk's regression on this directory means: every layout through the three Magic modes
REGRESSION_STEPS ?= magic-pex1 magic-pex2 magic-pex3
KNOWN_FAILS ?=

include $(MAKEFILE_DIR)/../../common.mk

SCRIPTS   := scripts
EXPECTED  := expected
RUN_DIR   := runs
KPEX_DIR  := $(NET_PEX_DIR)/kpex
FRESH     := $(RUN_DIR)/results.json

# ================================================================================================

layouts: ## Regenerate every layout/*.gds from the generators in scripts/ (usage: make layouts)
	@mkdir -p $(LAY_DIR)
	@for g in $(SCRIPTS)/gen_*.py; do \
		klayout -b -r $$g > $(RUN_DIR).genlog 2>&1 || { echo "[LAYOUTS] FAILED $$g"; cat $(RUN_DIR).genlog; rm -f $(RUN_DIR).genlog; exit 1; }; \
		grep -v '^wrote' $(RUN_DIR).genlog || true; \
	done; rm -f $(RUN_DIR).genlog
	@ls $(LAY_DIR)/*.gds | wc -l | sed 's/^/[LAYOUTS] /; s/$$/ layouts in $(LAY_DIR)\//'
.PHONY: layouts

layouts-check: ## Assert the generators reproduce layout/ byte for byte (usage: make layouts-check)
	@tmp=$$(mktemp -d); \
	cp -r $(LAY_DIR) $$tmp/ref; \
	$(MAKE) --no-print-directory layouts > /dev/null || { rm -rf $$tmp; exit 1; }; \
	if diff -rq $$tmp/ref $(LAY_DIR); then \
		echo "[LAYOUTS] reproducible: the generators rewrite every committed GDS byte for byte"; \
		rm -rf $$tmp; \
	else \
		echo "[LAYOUTS] the generators no longer reproduce $(LAY_DIR)/ - commit the new layouts, or fix the generator"; \
		rm -rf $$tmp; exit 1; \
	fi
.PHONY: layouts-check

pex-bench-magic: check-pdk ## Extract every layout with Magic in modes 1, 2 and 3 (usage: make pex-bench-magic)
	@fails=; \
	for cell in $(LAYOUT_CELLS); do \
		for mode in 1 2 3; do \
			$(MAKE) --no-print-directory magic-pex CELL=$$cell EXT_MODE=$$mode > /dev/null || { echo "[MAGIC] FAILED $$cell mode $$mode"; fails="$$fails $$cell:$$mode"; }; \
		done; \
		echo "[MAGIC] $$cell: modes 1 2 3"; \
	done; \
	[ -z "$$fails" ] || { echo "[MAGIC] failed:$$fails"; exit 1; }
.PHONY: pex-bench-magic

pex-bench-2.5d: check-pdk ## Extract the comparison cells with the kpex 2.5D engine (usage: make pex-bench-2.5d)
	@fails=; known=; xpass=; \
	for kf in $(KPEX_KNOWN_FAILS); do \
		case " $(KPEX_CELLS) " in *" $$kf "*) ;; \
			*) echo "[KPEX 2.5D] WARNING: stale KPEX_KNOWN_FAILS entry '$$kf': not in KPEX_CELLS" ;; \
		esac; \
	done; \
	for cell in $(KPEX_CELLS); do \
		d=$(KPEX_DIR)/2.5D/$$cell; mkdir -p $$d; \
		if kpex --pdk $(PDK) --cell $$cell --gds $(LAY_DIR)/$$cell.gds --2.5D --out_dir $$d --out_spice $$d/out.spice > $$d/log 2>&1; then \
			rm -rf $$d/.kpex_cache; \
			echo "[KPEX 2.5D] $$cell: $$(grep -h '^Cext_1 ' $$d/out.spice | awk '{print $$2, $$3, $$4}')"; \
			case " $(KPEX_KNOWN_FAILS) " in *" $$cell "*) xpass="$$xpass $$cell" ;; esac; \
		else \
			case " $(KPEX_KNOWN_FAILS) " in \
				*" $$cell "*) echo "[KPEX 2.5D] KNOWN FAIL (ignored): $$cell, see $$d/log"; known="$$known $$cell" ;; \
				*) echo "[KPEX 2.5D] FAILED $$cell, see $$d/log"; fails="$$fails $$cell" ;; \
			esac; \
		fi; \
	done; \
	[ -z "$$known" ] || echo "[KPEX 2.5D] known fails:$$known"; \
	[ -z "$$xpass" ] || { echo "[KPEX 2.5D] UNEXPECTED PASS:$$xpass - listed in KPEX_KNOWN_FAILS but passed, remove the entry"; exit 1; }; \
	[ -z "$$fails" ] || { echo "[KPEX 2.5D] failed:$$fails"; exit 1; }
	@# kpex's KLayout LVS step drops an empty <cell>_extracted.cir next to its input; the
	@# directory it picks differs per PDK runset, so clean both places it has been seen in.
	@rm -f $(LAY_DIR)/*_extracted.cir $(MAKEFILE_DIR)/../*_extracted.cir 2>/dev/null || true
.PHONY: pex-bench-2.5d

pex-bench-fastercap: check-pdk ## Field-solve the comparison cells with kpex FasterCap (usage: make pex-bench-fastercap [KPEX_AMAX=<um2>] [KPEX_TOL=<frac>])
	@for cell in $(KPEX_CELLS); do \
		d=$(KPEX_DIR)/fastercap/$${cell}_a$(KPEX_AMAX); mkdir -p $$d; \
		kpex --pdk $(PDK) --cell $$cell --gds $(LAY_DIR)/$$cell.gds --fastercap \
			--delaunay_amax $(KPEX_AMAX) --delaunay_b 0.5 --tolerance $(KPEX_TOL) \
			$(if $(KPEX_THREADS),--threads $(KPEX_THREADS),) \
			--out_dir $$d --out_spice $$d/out.spice > $$d/log 2>&1 || { echo "[FASTERCAP] FAILED $$cell, see $$d/log"; exit 1; }; \
		find $$d -type d \( -name FasterCap_Input_Files -o -name Geometries -o -name .kpex_cache \) -prune -exec rm -rf {} + 2>/dev/null; \
		python3 $(SCRIPTS)/read_kpex.py $$d | sed 's/^/[FASTERCAP] /'; \
	done
	@# kpex's KLayout LVS step drops an empty <cell>_extracted.cir next to its input; the
	@# directory it picks differs per PDK runset, so clean both places it has been seen in.
	@rm -f $(LAY_DIR)/*_extracted.cir $(MAKEFILE_DIR)/../*_extracted.cir 2>/dev/null || true
.PHONY: pex-bench-fastercap

pex-bench-compare: ## Print tables A to I from whatever has been extracted and write $(FRESH) (usage: make pex-bench-compare)
	@mkdir -p $(RUN_DIR)
	@python3 $(SCRIPTS)/analyse.py --json $(RUN_DIR)/results_magic.json
	@echo
	@python3 $(SCRIPTS)/compare_engines.py --json $(RUN_DIR)/results_engines.json
	@python3 -c "import json,sys; a=json.load(open('$(RUN_DIR)/results_magic.json')); b=json.load(open('$(RUN_DIR)/results_engines.json')); json.dump(a+b, open('$(FRESH)','w'), indent=1)"
.PHONY: pex-bench-compare

pex-bench-check: ## Fail if the fresh results drift from $(EXPECTED)/results.json (usage: make pex-bench-check)
	@python3 $(SCRIPTS)/check_results.py $(FRESH) $(EXPECTED)/results.json
.PHONY: pex-bench-check

pex-bench-expected: ## Overwrite $(EXPECTED)/results.json with the fresh results, after a deliberate change only (usage: make pex-bench-expected)
	@python3 $(SCRIPTS)/check_results.py $(FRESH) $(EXPECTED)/results.json --write
.PHONY: pex-bench-expected

pex-bench: check-pdk ## Magic + kpex 2.5D on every cell, compare, check against expected (usage: make pex-bench [FASTERCAP=1] [KPEX_AMAX=<um2>])
	$(MAKE) --no-print-directory pex-bench-magic
	$(MAKE) --no-print-directory pex-bench-2.5d
	@if [ "$(FASTERCAP)" = "1" ]; then $(MAKE) --no-print-directory pex-bench-fastercap; fi
	$(MAKE) --no-print-directory pex-bench-compare
	$(MAKE) --no-print-directory pex-bench-check
.PHONY: pex-bench

pex-bench-defects: check-pdk ## Reproduce the six defects of the report on their smallest cases (usage: make pex-bench-defects)
	@echo "=== 1  full-RC counts every coupling capacitance twice (MINDELAY=0) ==="
	@sh $(SCRIPTS)/try_dbl.sh | sed -n '1p;$$p'
	@echo "=== 2  the shipped MINDELAY=1 collapses the resistor network, THRESHOLD gates unbranched nets ==="
	@sh $(SCRIPTS)/try_tee.sh | grep -E '=====|t=0      r=0     y=0|t=10000  r=1000  y=1'
	@echo "=== 3  C-decoupled drops coupling instead of grounding it ==="
	@sak-pex.sh -m 1 -w $(RUN_DIR)/d3 $(LAY_DIR)/sidewall_m1_s0p2.gds > /dev/null 2>&1; grep -h '^C' $(RUN_DIR)/d3/sidewall_m1_s0p2.pex.spice | sed 's/^/  mode 1: /'
	@sak-pex.sh -m 2 -w $(RUN_DIR)/d3 $(LAY_DIR)/sidewall_m1_s0p2.gds > /dev/null 2>&1; grep -h '^C' $(RUN_DIR)/d3/sidewall_m1_s0p2.pex.spice | sed 's/^/  mode 2: /'
	@echo "=== 4  ext2spice hierarchy on moves a gate net's wire capacitance onto its neighbours ==="
	@sh $(SCRIPTS)/try_hier.sh | grep -E '^---|VSS'
	@echo "=== 5  lateral coupling: Magic emits half of what kpex 2.5D emits from the same deck ==="
	@sh $(SCRIPTS)/try_sw.sh | grep -E 'default_28|explicit_swapped|formula'
	@echo "=== 6  the halo split: shielded-plate coupling sent to the substrate ==="
	@sak-pex.sh -m 2 -w $(RUN_DIR)/d6 $(LAY_DIR)/overlap_m1_tm1.gds > /dev/null 2>&1; grep -h '^C' $(RUN_DIR)/d6/overlap_m1_tm1.pex.spice | sed 's/^/  Magic:     /'
	@python3 $(SCRIPTS)/read_kpex.py $(EXPECTED)/fastercap/overlap_m1_tm1_a2 | sed 's/^/  FasterCap: /'
.PHONY: pex-bench-defects

pex-bench-clean: ## Remove every bench output (usage: make pex-bench-clean)
	rm -rf $(NET_PEX_DIR) $(RUN_DIR)
.PHONY: pex-bench-clean
