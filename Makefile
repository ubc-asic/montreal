# Top-level Makefile just includes the sub-makefiles and exposes user-facing targets

include flows/common.mk	# Shared vars and paths
include flows/lint.mk	# Lint only
include flows/sim.mk		# Build + run sim
include flows/synth.mk

.PHONY: all
all: lint

.PHONY: help
help:
	@echo "make lint       - run Verilator lint"
	@echo "make lint_wall  - run Verilator lint -Wall"
	@echo "make sim        - build + run simulation"
	@echo "make cellcount  - run Yosys synthesis + report cell count"
	@echo "make clean      - remove all build artifacts"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)