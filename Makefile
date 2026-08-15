# Top-level Makefile just includes the sub-makefiles and exposes user-facing targets

include flows/common.mk	# Shared vars and paths
include flows/lint.mk	# Lint only
include flows/sim.mk	# Build + run sim
include flows/synth.mk

.PHONY: all
all: lint

.PHONY: help
help:
	@echo "make lint        - run Verilator lint"							# Working
	@echo "make lint_wall   - run Verilator lint -Wall"						# Working
	@echo "make sim         - build + run simulation"						# Not setup
	@echo "make cellcount   - run Yosys synthesis + report cell count"		# Working
	@echo "make netlist    	- run Yosys synthesis + show netlist diagram"	# Working
	@echo "make yosys_shell - load design into an interactive yosys shell"	# Working
	@echo "make clean       - remove all build artifacts"					# Working

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)