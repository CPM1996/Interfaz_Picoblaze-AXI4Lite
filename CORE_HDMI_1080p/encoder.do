#cd D:/Carlos/Zybo/Pruebas_CORE_HDMI/MODELSIM_TEST

vlib work
vcom -reportprogress 300 -work work HDMI_COD.vhd

vsim -gui work.codificador_tmds(arq_codificador_tmds)

add wave -ports *

add wave -divider "internals"

add wave -internals *

force clk 0, 1 20ns -r 40ns
force reset 1, 0 120ns
force den 0
force dato 16#00
force TMDS_Channel 0
force C0 0
force C1 0

run 400ns

force C0 1
run 200ns
force C0 0
run 200ns

force den 1

run 400ns

force dato 16#FF

run 400ns

force dato 16#00

run 400ns