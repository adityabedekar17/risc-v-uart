
TOP := picorv_uart_tb

export BASEJUMP_STL_DIR := $(abspath third_party/basejump_stl)
export YOSYS_DATDIR := $(shell yosys-config --datdir)
export HPDCACHE_DIR := $(abspath third_party/hpdcache)

RTL := $(shell \
 BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR) \
 python3 misc/convert_filelist.py Makefile rtl/rtl.f \
)

SV2V_ARGS := $(shell \
 BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR) \
 python3 misc/convert_filelist.py sv2v rtl/rtl.f \
)

.PHONY: lint sim gls icestorm_icesugar_gls icestorm_icesugar_program icestorm_icesugar_flash clean

bitstream: synth/icestorm_icesugar/build/icesugar.bin

lint:
	verilator lint/verilator.vlt \
		-f $(HPDCACHE_DIR)/rtl/hpdcache.Flist \
		$(HPDCACHE_DIR)/rtl/src/common/macros/behav/*.sv \
		-f rtl/rtl.f -f dv/dv.f \
		--lint-only --top picorv_uart

sim:
	verilator lint/verilator.vlt --Mdir ${TOP}_$@_dir \
		-f $(HPDCACHE_DIR)/rtl/hpdcache.Flist \
		$(HPDCACHE_DIR)/rtl/src/common/macros/behav/*.sv \
		-f rtl/rtl.f -f dv/pre_synth.f -f dv/dv.f \
		--binary -Wno-fatal --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

synth/build/rtl.sv2v.v: ${RTL} rtl/rtl.f
	mkdir -p $(dir $@)
	sv2v ${SV2V_ARGS} -w $@ -DSYNTHESIS

gls: synth/yosys_generic/build/synth.v
	verilator lint/verilator.vlt --Mdir ${TOP}_$@_dir -f synth/yosys_generic/gls.f -f dv/dv.f --binary -Wno-fatal --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

synth/yosys_generic/build/synth.v: synth/build/rtl.sv2v.v synth/yosys_generic/yosys.tcl
	mkdir -p $(dir $@)
	yosys -p 'tcl synth/yosys_generic/yosys.tcl synth/build/rtl.sv2v.v' -ql synth/yosys_generic/build/yosys.log

icestorm_icesugar_gls: synth/icestorm_icesugar/build/synth.v
	verilator lint/verilator.vlt --Mdir ${TOP}_$@_dir -f synth/icestorm_icesugar/gls.f -f dv/dv.f --binary -Wno-fatal --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

synth/icestorm_icesugar/build/synth.v synth/icestorm_icesugar/build/synth.json: synth/build/rtl.sv2v.v synth/icestorm_icesugar/icesugar.v synth/icestorm_icesugar/yosys.tcl
	mkdir -p $(dir $@)
	yosys -p 'tcl synth/icestorm_icesugar/yosys.tcl' -ql synth/icestorm_icesugar/build/yosys.log

synth/icestorm_icesugar/build/icesugar.asc: synth/icestorm_icesugar/build/synth.json synth/icestorm_icesugar/nextpnr.py synth/icestorm_icesugar/icesugar.pcf
	nextpnr-ice40 \
	 --json synth/icestorm_icesugar/build/synth.json \
	 --up5k \
	 --package sg48 \
	 --pre-pack synth/icestorm_icesugar/nextpnr.py \
	 --pcf synth/icestorm_icesugar/icesugar.pcf \
	 --asc $@ \
	 -q -l synth/icestorm_icesugar/build/nextpnr.log

%.bin: %.asc
	icepack $< $@

icestorm_icesugar_program: synth/icestorm_icesugar/build/icesugar.bin
	icesprog $<

clean:
	rm -rf \
	 *.memh *.memb \
	 *sim_dir *gls_dir \
	 dump.vcd dump.fst \
	 synth/build \
	 synth/yosys_generic/build \
	 synth/icestorm_icesugar/build \
	 synth/vivado_basys3/build
