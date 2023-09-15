SHELL=/bin/bash
SED ?= sed

TOP = Queue

#########################################################################################
# build output directory for compilation
#########################################################################################
# output for all project builds
build_dir = $(abspath ./test_and_run)
# final generated collateral per-project
GEN_COLLATERAL_DIR ?= $(build_dir)/gen-collateral

# chisel generated outputs
FIRRTL_FILE ?= $(build_dir)/$(TOP).fir

# scala firrtl compiler (sfc) outputs
SFC_FIRRTL_BASENAME ?= $(build_dir)/$(TOP).sfc
SFC_FIRRTL_FILE ?= $(SFC_FIRRTL_BASENAME).fir
SFC_ANNO_FILE ?= $(build_dir)/$(TOP).sfc.anno.json

# firtool compiler outputs
MFC_TOP_HRCHY_JSON ?= $(build_dir)/top_module_hierarchy.json
MFC_SMEMS_CONF ?= $(build_dir)/$(TOP).mems.conf
# hardcoded firtool outputs
MFC_FILELIST = $(GEN_COLLATERAL_DIR)/filelist.f

# macrocompiler smems in/output
SFC_SMEMS_CONF ?= $(build_dir)/$(long_name).sfc.mems.conf
TOP_SMEMS_CONF ?= $(build_dir)/$(long_name).top.mems.conf
TOP_SMEMS_FILE ?= $(GEN_COLLATERAL_DIR)/$(long_name).top.mems.v
TOP_SMEMS_FIR  ?= $(build_dir)/$(long_name).top.mems.fir

# top module files to include
TOP_MODS_FILELIST ?= $(build_dir)/$(long_name).top.f
# all module files to include (top, model, bb included)
ALL_MODS_FILELIST ?= $(build_dir)/$(long_name).all.f

#########################################################################################
# create verilog files rules and variables
#########################################################################################
SFC_MFC_TARGETS = \
	$(MFC_SMEMS_CONF) \
	$(MFC_TOP_SMEMS_JSON) \
	$(MFC_TOP_HRCHY_JSON) \
	$(MFC_FILELIST) \
	$(GEN_COLLATERAL_DIR)

SFC_REPL_SEQ_MEM = --infer-rw --repl-seq-mem -c:$(TOP):-o:$(SFC_SMEMS_CONF)
MFC_LOWERING_OPTIONS = emittedLineLength=2048,noAlwaysComb,disallowLocalVariables,verifLabels,locationInfoStyle=wrapInAtSquareBracket,disallowPackedArrays
SFC_LEVEL := none
EXTRA_FIRRTL_OPTIONS += $(SFC_REPL_SEQ_MEM)

#########################################################################################
# create firrtl file rule and variables
#########################################################################################

$(SFC_MFC_TARGETS):
	rm -rf $(GEN_COLLATERAL_DIR)
	sbt "project tapeout; runMain barstools.tapeout.transforms.GenerateModelStageMain \
		--no-dedup \
		--output-file $(SFC_FIRRTL_BASENAME) \
		--output-annotation-file $(SFC_ANNO_FILE) \
		--target-dir $(GEN_COLLATERAL_DIR) \
		--input-file $(FIRRTL_FILE) \
		--log-level error \
		--allow-unrecognized-annotations \
		-X $(SFC_LEVEL) \
		$(EXTRA_FIRRTL_OPTIONS)"
	-mv $(SFC_FIRRTL_BASENAME).lo.fir $(SFC_FIRRTL_FILE) 2> /dev/null # Optionally change file type when SFC generates LowFIRRTL
	firtool \
		--format=fir \
		--dedup \
		--export-module-hierarchy \
		--verify-each=true \
		--warn-on-unprocessed-annotations \
		--disable-annotation-classless \
		--disable-annotation-unknown \
		--mlir-timing \
		--lowering-options=$(MFC_LOWERING_OPTIONS) \
		--repl-seq-mem \
		--repl-seq-mem-file=$(MFC_SMEMS_CONF) \
		--repl-seq-mem-circuit=$(TOP) \
		--annotation-file=$(SFC_ANNO_FILE) \
		--split-verilog \
		-o $(GEN_COLLATERAL_DIR) \
		$(SFC_FIRRTL_FILE)
	-mv $(SFC_SMEMS_CONF) $(MFC_SMEMS_CONF) 2> /dev/null
	$(SED) -i 's/.*/& /' $(MFC_SMEMS_CONF) # need trailing space for SFC macrocompiler
# DOC include end: FirrtlCompiler

$(TOP_MODS_FILELIST) $(ALL_MODS_FILELIST) &: $(MFC_FILELIST) 
	$(base_dir)/scripts/split-module-files.py \
		--dut $(TOP) \
		--out-dut-filelist $(TOP_MODS_FILELIST) \
		--in-all-filelist $(MFC_FILELIST) \
		--target-dir $(GEN_COLLATERAL_DIR)
	$(SED) -e 's;^;$(GEN_COLLATERAL_DIR)/;' $(MFC_BB_MODS_FILELIST) > $(BB_MODS_FILELIST)
	$(SED) -i 's/\.\///' $(TOP_MODS_FILELIST)
	sort -u $(TOP_MODS_FILELIST) > $(ALL_MODS_FILELIST)

$(TOP_SMEMS_CONF): $(MFC_SMEMS_CONF)
	$(base_dir)/scripts/split-mems-conf.py \
		--in-smems-conf $(MFC_SMEMS_CONF) \
		--dut-module-name $(TOP) \
		--out-dut-smems-conf $(TOP_SMEMS_CONF) 

# This file is for simulation only. VLSI flows should replace this file with one containing hard SRAMs
TOP_MACROCOMPILER_MODE ?= --mode synflops
$(TOP_SMEMS_FILE) $(TOP_SMEMS_FIR) &: $(TOP_SMEMS_CONF)
	sbt "project tapeout; runMain barstools.macros.MacroCompiler -n $(TOP_SMEMS_CONF) -v $(TOP_SMEMS_FILE) -f $(TOP_SMEMS_FIR) $(TOP_MACROCOMPILER_MODE)"


#########################################################################################
# helper rule to just make verilog files
#########################################################################################
.PHONY: verilog
verilog: $(SFC_MFC_TARGETS)

uint:
	make clean
	sbt "runMain example.QueueUIntChirtlApp"
	make verilog

sint:
	make clean
	sbt "runMain example.QueueSIntChirtlApp"
	make verilog

.PHONY: clean
clean:
	rm -rf $(build_dir)

