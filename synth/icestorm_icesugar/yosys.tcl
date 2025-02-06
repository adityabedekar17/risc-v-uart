
yosys -import

read_verilog synth/build/rtl.sv2v.v synth/icestorm_icesugar/icesugar.v

synth_ice40 -top icesugar

write_verilog -noexpr -noattr -simple-lhs synth/icestorm_icesugar/build/synth.v
write_json synth/icestorm_icesugar/build/synth.json
