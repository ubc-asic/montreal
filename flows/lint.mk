.PHONY: lint
lint:
	$(VERILATOR) --lint-only -f $(RTL_FILELIST) --top-module $(TOP) \
		-Irtl -Mdir $(OUTPUT_DIR)/lint

.PHONY: lint_wall
lint_wall:
	$(VERILATOR) --lint-only -f $(RTL_FILELIST) --top-module $(TOP) \
		-Irtl -Wall -Mdir $(OUTPUT_DIR)/lint_wall