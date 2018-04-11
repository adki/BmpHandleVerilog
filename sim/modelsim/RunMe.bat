@echo off

vlib work
vlog -work work +incdir+../../design/verilog ../../design/verilog/tea_encryptor_pipeline.v
vlog -work work +incdir+../../design/verilog ../../design/verilog/tea_decryptor_pipeline.v
vlog -work work +incdir+../../bench.bmp/verilog ../../bench.bmp/verilog/check_pipeline.v
vlog -work work +incdir+../../bench.bmp/verilog ../../bench.bmp/verilog/bmp_stimulus_check.v
vlog -work work +incdir+../../bench.bmp/verilog ../../bench.bmp/verilog/top.v
vsim -novopt -c -do "run -all" work.top

pause
