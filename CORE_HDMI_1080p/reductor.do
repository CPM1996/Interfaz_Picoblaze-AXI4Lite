
vlib work
vcom -reportprogress 300 -work work reductor_transiciones.vhd

vsim -gui work.reductor_transiciones(behavioral) 

add wave -ports *

force clk 0, 1 20ns -r 40nsç
force reset 1, 0 120ns
force dato 16#00
run 400ns

force dato 16#FF
run 400ns