
build_dir = $(abspath ./test_and_run)
MFC_BASE_LOWERING_OPTIONS = emittedLineLength=2048,noAlwaysComb,disallowLocalVariables,verifLabels,locationInfoStyle=wrapInAtSquareBracket
$(eval MFC_LOWERING_OPTIONS = $(MFC_BASE_LOWERING_OPTIONS),disallowPackedArrays)

MODEL ?= Queue

ANNO_FILE   ?= $(build_dir)/$(MODEL).anno.json
MFC_EXTRA_ANNO_FILE ?= $(build_dir)/$(MODEL).extrafirtool.anno.json
SFC_ANNO_FILE ?= $(build_dir)/$(MODEL).sfc.anno.json
SFC_EXTRA_ANNO_FILE ?= $(build_dir)/$(MODEL).extrasfc.anno.json
EXTRA_ANNO_FILE ?= $(build_dir)/$(MODEL).extra.anno.json
FINAL_ANNO_FILE ?= $(build_dir)/$(MODEL).appended.anno.json

FIRRTL_FILE ?= $(build_dir)/$(MODEL).fir
SFC_FIRRTL_BASENAME ?= $(build_dir)/$(MODEL).sfc
SFC_FIRRTL_FILE ?= $(SFC_FIRRTL_BASENAME).fir

SFC_SMEMS_CONF ?= $(MODEL).sfc.mems.conf
# firtool compiler outputs
MFC_TOP_HRCHY_JSON ?= $(build_dir)/top_module_hierarchy.json
MFC_MODEL_HRCHY_JSON ?= $(build_dir)/model_module_hierarchy.json
MFC_SMEMS_CONF ?= $(build_dir)/$(MODEL).mems.conf

EXTRA_FIRRTL_OPTIONS = --infer-rw --repl-seq-mem -c:$(MODEL):-o:$(SFC_SMEMS_CONF)



define mfc_extra_anno_contents
[
	{
		"class":"sifive.enterprise.firrtl.MarkDUTAnnotation",
		"target":"~$(MODEL)|$(MODEL)"
	},
	{
		"class": "sifive.enterprise.firrtl.TestHarnessHierarchyAnnotation",
		"filename": "$(MFC_MODEL_HRCHY_JSON)"
	},
	{
		"class": "sifive.enterprise.firrtl.ModuleHierarchyAnnotation",
		"filename": "$(MFC_TOP_HRCHY_JSON)"
	}
]
endef
define sfc_extra_low_transforms_anno_contents
[
	{
		"class": "firrtl.stage.RunFirrtlTransformAnnotation",
		"transform": "barstools.tapeout.transforms.ExtraLowTransforms"
	}
]
endef
export mfc_extra_anno_contents
export sfc_extra_low_transforms_anno_contents

.PHONY: transformation
transformation:
	echo "$$mfc_extra_anno_contents" > $(MFC_EXTRA_ANNO_FILE)
	echo "$$sfc_extra_low_transforms_anno_contents" >$(SFC_EXTRA_ANNO_FILE)
	jq -s '[.[][]]' $(MFC_EXTRA_ANNO_FILE) > $(EXTRA_ANNO_FILE)
	cat $(EXTRA_ANNO_FILE) > $(FINAL_ANNO_FILE)
	sbt "project tapeout; runMain barstools.tapeout.transforms.GenerateModelStageMain \
		--no-dedup \
		--output-file $(SFC_FIRRTL_BASENAME) \
		--output-annotation-file $(SFC_ANNO_FILE) \
		--target-dir $(build_dir) \
		--input-file $(build_dir)/$(MODEL).fir \
		--annotation-file $(FINAL_ANNO_FILE) \
		--log-level error \
		--allow-unrecognized-annotations \
		-X none \
		$(EXTRA_FIRRTL_OPTIONS)"
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
		--repl-seq-mem-file=$(build_dir)/$(SFC_SMEMS_CONF) \
		--repl-seq-mem-circuit=Queue \
		--annotation-file=$(SFC_ANNO_FILE) \
		--split-verilog \
		-o $(build_dir)/ \
		$(FIRRTL_FILE)
uint:
	make clean
	sbt "runMain example.QueueUIntChirtlApp"
	make transformation

sint:
	make clean
	sbt "runMain example.QueueSIntChirtlApp"
	make transformation

.PHONY: clean
clean:
	rm -rf $(build_dir)

