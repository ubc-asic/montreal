# reads all RTL files and sets the design hierarchy; shared by the targets below
$(OUTPUT_DIR)/load.ys: $(RTL_FILELIST)
	mkdir -p $(OUTPUT_DIR)
	{ sed 's/^/read_verilog -sv -I rtl /' $(RTL_FILELIST); \
	  echo "hierarchy -top $(TOP)"; } > $@

$(OUTPUT_DIR)/synth.ys: $(OUTPUT_DIR)/load.ys
	# convert processes (always blocks) to netlist elements and perform some simple optimizations
	# prints the cell count report
	{ cat $<; \
	  echo "proc; opt"; \
	  echo "stat"; } > $@

.PHONY: cellcount
cellcount: $(OUTPUT_DIR)/synth.ys
	$(YOSYS) $<

$(OUTPUT_DIR)/netlist.ys: $(OUTPUT_DIR)/load.ys
	# convert processes (always blocks) to netlist elements and perform some simple optimizations
	# draws the netlist
	{ cat $<; \
	  echo "proc; opt"; \
	  echo "show"; } > $@

.PHONY: netlist
netlist: $(OUTPUT_DIR)/netlist.ys
	$(YOSYS) $<

$(OUTPUT_DIR)/shell.ys: $(OUTPUT_DIR)/load.ys
	{ cat $<; \
	  echo "shell"; } > $@

.PHONY: yosys_shell
yosys_shell: $(OUTPUT_DIR)/shell.ys
	$(YOSYS) $<
