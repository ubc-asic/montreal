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

$(OUTPUT_DIR)/netlist_%.ys: $(OUTPUT_DIR)/load.ys
	# convert processes (always blocks) to netlist elements and perform some simple optimizations
	# draws the netlist for the module named by the % stem
	{ cat $<; \
	  echo "proc; opt"; \
	  echo "show $*"; } > $@

.PHONY: netlist_%
netlist_%: $(OUTPUT_DIR)/netlist_%.ys
	$(YOSYS) $<

.PHONY: netlist
netlist: netlist_$(TOP)

$(OUTPUT_DIR)/area.ys: $(RTL_FILELIST)
	# synthesis-only area estimate: maps generic cells onto real SKY130 std cells
	mkdir -p $(OUTPUT_DIR)
	{ sed 's/^/read_verilog -sv -I rtl /' $(RTL_FILELIST); \
	  echo "synth -top $(TOP)"; \
	  echo "dfflibmap -liberty $(SKY130_LIB)"; \
	  echo "abc -liberty $(SKY130_LIB)"; \
	  echo "stat -liberty $(SKY130_LIB)"; } > $@

.PHONY: area
area: $(OUTPUT_DIR)/area.ys
	$(YOSYS) $<

$(OUTPUT_DIR)/shell.ys: $(OUTPUT_DIR)/load.ys
	{ cat $<; \
	  echo "shell"; } > $@

.PHONY: yosys_shell
yosys_shell: $(OUTPUT_DIR)/shell.ys
	$(YOSYS) $<
