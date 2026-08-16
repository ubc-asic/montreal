# Top-level Makefile just includes the sub-makefiles and exposes user-facing targets

.PHONY: all
all: lint netlist

include flows/common.mk	# Shared vars and paths
include flows/lint.mk	# Lint only
include flows/sim.mk	# Build + run sim
include flows/synth.mk

.PHONY: help
help:
	@echo "make lint        		- run Verilator lint"
	@echo "make lint_wall   		- run Verilator lint -Wall"
	@echo "make sim         		- build + run simulation (Work In Progress)"
	@echo "make cellcount   		- run Yosys synthesis + report cell count"
	@echo "make netlist          	- run Yosys synthesis + show netlist diagram for \$$(TOP)"
	@echo "make netlist_<module>	- same, but for a specific module (e.g. netlist_qspi_controller)"
	@echo "make yosys_shell 		- load design into an interactive yosys shell"
	@echo "make clean       		- remove all build artifacts"

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
