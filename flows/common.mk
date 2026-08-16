TOP				:= tt_top_ubc_montreal
OUTPUT_DIR  	:= output
RTL_FILELIST 	:= rtl/filelist.f
DV_FILELIST  	:= dv/filelist.f

VERILATOR  := verilator
YOSYS      := yosys

# SKY130 PDK, fetched via `volare enable --pdk sky130 $(PDK_VERSION)`.
# Override any of these on the command line to point at a different PDK install.
PDK          ?= sky130
PDK_VERSION  ?= c6d73a35f524070e85faff4a6a9eef49553ebc2b
# Requires `pip install volare && volare enable --pdk sky130 $(PDK_VERSION)`
# in whatever shell you run `make` from (volare must be on that shell's PATH).
# If `volare` isn't found, override this directly, e.g.:
#   make area PDK_ROOT=/path/to/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b
PDK_ROOT     ?= $(shell volare path --pdk $(PDK) $(PDK_VERSION))
SKY130_LIB   ?= $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib